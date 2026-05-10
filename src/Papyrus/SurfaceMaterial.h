#pragma once

#include "PCH.h"

namespace BarefootRealismNG::Papyrus {

// Returns the mod's surface id under the actor's feet, matching the 0..8 mapping
// that PBFTerrainDetectionQuestScript previously inferred via spawned hazards.
//   0 = Stone   1 = Dirt   2 = Mud    3 = Wood    4 = Grass
//   5 = Snow    6 = Carpet 7 = Gravel 8 = Water  -1 = Unknown / no hit
//
// Water is *not* the primary path here — callers short-circuit to 8 via po3's
// IsRefInWater before invoking this native. We still map kWater for completeness
// when a downward pick happens to land on a water shape.
std::int32_t GetSurfaceMaterialUnderActor(RE::StaticFunctionTag*, RE::Actor* a_actor);

}  // namespace BarefootRealismNG::Papyrus
