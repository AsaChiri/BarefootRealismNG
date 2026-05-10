#include "PCH.h"

#include "Papyrus/SurfaceMaterial.h"

#include "RE/B/bhkPickData.h"
#include "RE/B/bhkShape.h"
#include "RE/B/bhkWorld.h"
#include "RE/H/hkpCollidable.h"
#include "RE/H/hkpShapeBuffer.h"
#include "RE/H/hkpShapeContainer.h"

#include <atomic>
#include <mutex>
#include <unordered_set>

namespace BarefootRealismNG::Papyrus {

namespace {

// Mod surface ids — match the constants used in PBFTerrainDetectionQuestScript.psc
// (Stone=0 ... Water=8, Unknown=-1) and the SurfaceDirtiness/SurfaceRoughness
// arrays indexed by these in PBFConfig.
enum SurfaceId : std::int32_t {
    kStone   = 0,
    kDirt    = 1,
    kMud     = 2,
    kWood    = 3,
    kGrass   = 4,
    kSnow    = 5,
    kCarpet  = 6,
    kGravel  = 7,
    kWater   = 8,
    kUnknown = -1,
};

// Translate Skyrim's MATERIAL_ID enum to a mod surface id. Missing ids fall
// through to kUnknown and are debug-logged so the table can be expanded from
// real game data without rebuilding.
std::int32_t MapMaterialId(RE::MATERIAL_ID a_id) {
    using M = RE::MATERIAL_ID;

    switch (a_id) {
        case M::kStone:
        case M::kStoneStairs:
        case M::kStoneAsStairs:
        case M::kStoneStairsBroken:
        case M::kStoneBroken:
        case M::kStoneHeavy:
        case M::kBoulderLarge:
        case M::kBoulderMedium:
        case M::kBoulderSmall:
            return kStone;

        case M::kDirt:
            return kDirt;

        case M::kMud:
            return kMud;

        case M::kWood:
        case M::kWoodLight:
        case M::kWoodHeavy:
        case M::kWoodAsStairs:
        case M::kWoodStairs:
        case M::kDLC1SwingingBridge:
            return kWood;

        case M::kGrass:
            return kGrass;

        case M::kSnow:
        case M::kSnowStairs:
        case M::kIce:
        case M::kIceForm:
            return kSnow;

        case M::kCarpet:
        case M::kCloth:
        case M::kDLC1DeerSkin:
        case M::kDLC1SabreCatPelt:
            return kCarpet;

        case M::kGravel:
        case M::kSand:
            return kGravel;

        case M::kWater:
        case M::kWaterPuddle:
            return kWater;

        // Solstheim ash piles and small treasure piles behave more like dirt/stone
        // than their default fallback; map them explicitly.
        case M::kAsh:
            return kDirt;
        case M::kCoin:
            return kStone;

        default:
            return kUnknown;
    }
}

constexpr float kForwardOffsetXY = 50.0f;  // matches original Papyrus offset
constexpr float kVerticalLift    = 10.0f;  // matches original 10-unit lift
constexpr float kRayLengthDown   = 220.0f; // covers walking forward off a small ledge

}  // namespace

std::int32_t GetSurfaceMaterialUnderActor(RE::StaticFunctionTag*, RE::Actor* a_actor) {
    // First 30 calls log full detail at INFO so we can diagnose why a pick
    // returns -1 without making the user flip log levels. After that, only
    // the rate-limited "unmapped material" lines fire.
    static std::atomic<int> s_callCount{ 0 };
    const int n = ++s_callCount;
    const bool diag = (n <= 30);

    if (!a_actor) {
        if (diag) logger::info("[surface #{}] actor=null -> -1", n);
        return kUnknown;
    }

    auto* cell = a_actor->GetParentCell();
    if (!cell) {
        if (diag) logger::info("[surface #{}] no parent cell -> -1", n);
        return kUnknown;
    }
    auto* bhkWorld = cell->GetbhkWorld();
    if (!bhkWorld) {
        if (diag) logger::info("[surface #{}] cell '{}' has no bhkWorld -> -1",
                               n, cell->GetFormEditorID() ? cell->GetFormEditorID() : "?");
        return kUnknown;
    }

    const auto pos   = a_actor->GetPosition();
    const auto theta = a_actor->data.angle.z;
    const RE::NiPoint3 origin{
        pos.x + std::sin(theta) * kForwardOffsetXY,
        pos.y + std::cos(theta) * kForwardOffsetXY,
        pos.z + kVerticalLift,
    };
    const RE::NiPoint3 endPt{ origin.x, origin.y, origin.z - kRayLengthDown };

    const float scale = RE::bhkWorld::GetWorldScale();

    RE::bhkPickData pick;
    pick.rayInput.from = RE::hkVector4(origin * scale);
    pick.rayInput.to   = RE::hkVector4(endPt  * scale);
    pick.rayInput.enableShapeCollectionFilter = false;
    pick.rayInput.filterInfo = static_cast<std::uint32_t>(RE::COL_LAYER::kLOS);

    const bool picked = bhkWorld->PickObject(pick);
    const bool hasHit = picked && pick.rayOutput.HasHit();
    if (!hasHit) {
        if (diag) logger::info("[surface #{}] pos=({:.0f},{:.0f},{:.0f}) origin=({:.0f},{:.0f},{:.0f}) PickObject={} HasHit=false -> -1",
                               n, pos.x, pos.y, pos.z, origin.x, origin.y, origin.z, picked);
        return kUnknown;
    }

    const auto* collidable = pick.rayOutput.rootCollidable;
    const auto* hkShape    = collidable ? collidable->GetShape() : nullptr;
    const auto* bhShape    = hkShape ? hkShape->userData : nullptr;
    const auto  shapeType  = hkShape ? static_cast<std::uint32_t>(hkShape->type) : 0u;

    // The raycast may have hit a wrapper shape (kBVTree=8, kMOPP=10, kCollection=7,
    // kList=9, kCompound=17, …) whose top-level materialID is kNone — the real
    // per-triangle material lives in a child shape. Walk one level via the
    // standard hkpShapeContainer API (no relocated funcs, no SEH; just two
    // virtuals that are universally implemented).
    RE::MATERIAL_ID  rawMat    = bhShape ? bhShape->materialID : RE::MATERIAL_ID::kNone;
    bool             walked    = false;
    std::uint32_t    childType = 0;
    const void*      childHk   = nullptr;
    if (hkShape && rawMat == RE::MATERIAL_ID::kNone) {
        const auto* container = hkShape->GetContainer();
        if (container) {
            const auto keyIdx = pick.rayOutput.shapeKeyIndex;
            const auto key    = (keyIdx >= 0 && keyIdx < RE::hkpShapeRayCastOutput::kMaxHierarchyDepth)
                                  ? pick.rayOutput.shapeKeys[keyIdx]
                                  : pick.rayOutput.shapeKeys[0];
            if (key != RE::HK_INVALID_SHAPE_KEY) {
                RE::hkpShapeBuffer buf{};
                const auto* childShape = container->GetChildShape(key, buf);
                if (childShape) {
                    childHk   = childShape;
                    childType = static_cast<std::uint32_t>(childShape->type);
                    walked    = true;
                    if (const auto* childBh = childShape->userData) {
                        rawMat = childBh->materialID;
                    }
                }
            }
        }
    }

    const auto surface = MapMaterialId(rawMat);

    if (diag) {
        // NO unchecked pointer casts here: collidable->GetOwner<T>() crashes
        // when the owner isn't actually a T (terrain owner is hkpRigidBody,
        // not TESObjectREFR).
        logger::info("[surface #{}] pos=({:.0f},{:.0f},{:.0f}) shapeType={} bhShape={} matRaw={:#010x} walked={} childType={} childHk={} mapped={}",
                     n, pos.x, pos.y, pos.z, shapeType,
                     static_cast<const void*>(bhShape),
                     static_cast<std::uint32_t>(rawMat),
                     walked, childType, childHk,
                     surface);
    }

    if (surface == kUnknown && rawMat != RE::MATERIAL_ID::kNone) {
        static std::mutex                       s_unmappedMu;
        static std::unordered_set<std::uint32_t> s_unmapped;
        const auto rawId = static_cast<std::uint32_t>(rawMat);
        bool firstTime = false;
        {
            std::lock_guard lock{ s_unmappedMu };
            firstTime = s_unmapped.insert(rawId).second;
        }
        if (firstTime) {
            logger::info("Unmapped MATERIAL_ID {} ({:#010x}) under actor {:08X}",
                         rawMat, rawId, a_actor->GetFormID());
        }
    }
    return surface;
}

}  // namespace BarefootRealismNG::Papyrus
