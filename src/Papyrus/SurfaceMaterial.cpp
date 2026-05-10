#include "PCH.h"

#include "Papyrus/SurfaceMaterial.h"

#include "RE/B/bhkPickData.h"
#include "RE/B/bhkShape.h"
#include "RE/B/bhkWorld.h"
#include "RE/H/hkpCollidable.h"

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
            return kWood;

        case M::kGrass:
            return kGrass;

        case M::kSnow:
        case M::kSnowStairs:
            return kSnow;

        case M::kCarpet:
            return kCarpet;

        case M::kGravel:
        case M::kSand:
            return kGravel;

        case M::kWater:
        case M::kWaterPuddle:
            return kWater;

        default:
            return kUnknown;
    }
}

constexpr float kForwardOffsetXY = 50.0f;  // matches original Papyrus offset
constexpr float kVerticalLift    = 10.0f;  // matches original 10-unit lift
constexpr float kRayLengthDown   = 220.0f; // covers walking forward off a small ledge

// Cast a downward havok ray from a point ~50 units in front of the actor,
// 10 units above the actor's feet. Returns the MATERIAL_ID at the hit, or
// std::nullopt if the cell has no havok world or nothing was hit.
std::optional<RE::MATERIAL_ID> PickSurfaceMaterial(RE::Actor* a_actor) {
    auto* cell = a_actor->GetParentCell();
    if (!cell) {
        return std::nullopt;
    }
    auto* bhkWorld = cell->GetbhkWorld();
    if (!bhkWorld) {
        return std::nullopt;
    }

    const auto pos   = a_actor->GetPosition();
    const auto theta = a_actor->data.angle.z;
    const RE::NiPoint3 origin{
        pos.x + std::sin(theta) * kForwardOffsetXY,
        pos.y + std::cos(theta) * kForwardOffsetXY,
        pos.z + kVerticalLift,
    };
    const RE::NiPoint3 endPt{ origin.x, origin.y, origin.z - kRayLengthDown };

    // Skyrim units -> Havok meters (1/70).
    const float scale = RE::bhkWorld::GetWorldScale();

    RE::bhkPickData pick;
    pick.rayInput.from = RE::hkVector4(origin * scale);
    pick.rayInput.to   = RE::hkVector4(endPt  * scale);
    pick.rayInput.enableShapeCollectionFilter = false;
    // kLOS is the line-of-sight layer; it doesn't filter out the floor and
    // ignores most actor capsules, which is exactly what we want here.
    pick.rayInput.filterInfo = static_cast<std::uint32_t>(RE::COL_LAYER::kLOS);

    if (!bhkWorld->PickObject(pick) || !pick.rayOutput.HasHit()) {
        return std::nullopt;
    }

    const auto* hkShape = pick.rayOutput.rootCollidable->GetShape();
    if (!hkShape) {
        return std::nullopt;
    }
    const auto* bhShape = hkShape->userData;
    if (!bhShape) {
        return std::nullopt;
    }

    // For compound shapes (terrain triangle meshes, list shapes, etc.), the
    // top shapeKey identifies the specific sub-shape that was hit. For simple
    // shapes the key is HK_INVALID_SHAPE_KEY and we fall back to the
    // top-level material on bhkShape.
    const auto key = pick.rayOutput.shapeKeys[0];
    if (key != RE::HK_INVALID_SHAPE_KEY) {
        return bhShape->GetMaterialID(key);
    }
    return bhShape->materialID;
}

}  // namespace

std::int32_t GetSurfaceMaterialUnderActor(RE::StaticFunctionTag*, RE::Actor* a_actor) {
    if (!a_actor) {
        return kUnknown;
    }

    const auto material = PickSurfaceMaterial(a_actor);
    if (!material) {
        return kUnknown;
    }

    const auto surface = MapMaterialId(*material);
    if (surface == kUnknown) {
        // Debug log so the mapping table can grow from real-world data.
        logger::debug("Unmapped MATERIAL_ID {} under actor {:08X}",
                      *material, a_actor->GetFormID());
    }
    return surface;
}

}  // namespace BarefootRealismNG::Papyrus
