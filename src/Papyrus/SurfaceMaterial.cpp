#include "PCH.h"

#include "Papyrus/SurfaceMaterial.h"

#include "RE/B/BSAtomic.h"
#include "RE/B/bhkCharacterController.h"
#include "RE/B/bhkPickData.h"
#include "RE/B/bhkShape.h"
#include "RE/B/bhkWorld.h"
#include "RE/H/hkpCollidable.h"
#include "RE/T/TES.h"

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

namespace {

// Three-layer pipeline used by OpenAnimationReplacer / RaySense / Trails.
// Returns kNone on failure; the caller maps to the mod's 0..8 surface id.
//
// Layer 1 (preferred): the bhkCharacterController caches the "ground
// material under this actor" byte at `surfaceMaterial`, updated every
// physics tick by the engine for footstep sound selection. Crash-free,
// zero raycast overhead, accurate. Named field exposed by
// alandtse/CommonLibVR's `ng` branch (our vcpkg overlay-port pins 4.18.0
// — see `vcpkg-overlay-ports/commonlibsse-ng/portfile.cmake`).
//
// Layer 2 (outdoor fallback): RE::TES::GetLandMaterialType(pos) reads the
// per-quadrant TESLandTexture data on the current TESObjectLAND record.
// Returns kNone for non-LAND triangles (roads, water, statics).
//
// Layer 3 (last resort): downward havok pick + read top-level
// bhkShape::materialID. Most shapes hit are wrappers (kBVTree, kMOPP)
// whose top-level materialID is kNone, but small clutter and some statics
// do expose a real material here. We DO NOT call bhkShape::GetMaterialID
// or hkpShapeContainer::GetChildShape — both have crashed inside the engine
// on compound shapes (the shapeKey values in rayOutput aren't valid indices
// into Skyrim's compound shape data the way the engine expects).
//
// Source references: OAR src/Conditions.cpp, RaySense src/RaySenseLogic.cpp,
// Precision src/Utils.cpp on GitHub.

RE::MATERIAL_ID ReadCharControllerMaterial(RE::Actor* a_actor) {
    auto* cc = a_actor->GetCharController();
    if (!cc) return RE::MATERIAL_ID::kNone;
    return cc->surfaceMaterial;
}

RE::MATERIAL_ID ReadLandMaterial(RE::Actor* a_actor) {
    auto* cell = a_actor->GetParentCell();
    if (!cell || cell->IsInteriorCell()) return RE::MATERIAL_ID::kNone;
    auto* tes = RE::TES::GetSingleton();
    if (!tes) return RE::MATERIAL_ID::kNone;
    return tes->GetLandMaterialType(a_actor->GetPosition());
}

RE::MATERIAL_ID ReadHavokPickMaterial(RE::Actor* a_actor) {
    auto* cell = a_actor->GetParentCell();
    if (!cell) return RE::MATERIAL_ID::kNone;
    auto* bhkWorld = cell->GetbhkWorld();
    if (!bhkWorld) return RE::MATERIAL_ID::kNone;

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

    // Use the actor's own collision filter so we skip its own capsule. kLOS
    // (our previous filter) hits NPCs and projectiles we don't want.
    // CLib 4.18 changed both the field type (uint32_t -> CFilter) AND the
    // GetCollisionFilterInfo out-parameter signature (uint32_t& -> CFilter&).
    if (auto* cc = a_actor->GetCharController()) {
        cc->GetCollisionFilterInfo(pick.rayInput.filterInfo);
    }

    RE::BSReadLockGuard lock{ bhkWorld->worldLock };
    if (!bhkWorld->PickObject(pick) || !pick.rayOutput.HasHit()) {
        return RE::MATERIAL_ID::kNone;
    }
    if (auto* hkShape = pick.rayOutput.rootCollidable->GetShape()) {
        if (auto* bhShape = hkShape->userData) {
            return bhShape->materialID;
        }
    }
    return RE::MATERIAL_ID::kNone;
}

}  // namespace

std::int32_t GetSurfaceMaterialUnderActor(RE::StaticFunctionTag*, RE::Actor* a_actor) {
    // All diagnostic logging here goes through `logger::debug`, which is
    // silent unless the user sets BAREFOOTREALISMNG_DEBUG=1 (or
    // BAREFOOTREALISMNG_LOG_LEVEL=debug) before launching Skyrim.
    // See Logging.h::ResolveLogLevel.
    if (!a_actor) {
        logger::debug("[surface] actor=null -> -1");
        return kUnknown;
    }

    // Layer 1 — engine's own cached ground material (cheap & precise).
    RE::MATERIAL_ID raw   = ReadCharControllerMaterial(a_actor);
    const char*     layer = "charCtrl";

    if (raw == RE::MATERIAL_ID::kNone) {
        // Layer 2 — outdoor TESObjectLAND lookup.
        raw   = ReadLandMaterial(a_actor);
        layer = "land";
    }
    if (raw == RE::MATERIAL_ID::kNone) {
        // Layer 3 — havok pick, top-level material only.
        raw   = ReadHavokPickMaterial(a_actor);
        layer = "pick";
    }

    const auto surface = MapMaterialId(raw);

    logger::debug("[surface] layer={} matRaw={:#010x} mapped={}",
                  layer, static_cast<std::uint32_t>(raw), surface);

    // Unmapped-material reporting stays at info level: it's rate-limited
    // to one line per unique MATERIAL_ID per session, so the noise is
    // bounded, and it's actionable feedback for expanding MapMaterialId.
    if (surface == kUnknown && raw != RE::MATERIAL_ID::kNone) {
        static std::mutex                        s_unmappedMu;
        static std::unordered_set<std::uint32_t> s_unmapped;
        const auto rawId = static_cast<std::uint32_t>(raw);
        bool firstTime = false;
        {
            std::lock_guard lock{ s_unmappedMu };
            firstTime = s_unmapped.insert(rawId).second;
        }
        if (firstTime) {
            logger::info("Unmapped MATERIAL_ID {} ({:#010x}) under actor {:08X} (layer={})",
                         raw, rawId, a_actor->GetFormID(), layer);
        }
    }
    return surface;
}

}  // namespace BarefootRealismNG::Papyrus
