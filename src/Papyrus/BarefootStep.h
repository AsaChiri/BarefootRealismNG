#pragma once

#include "PCH.h"

namespace BarefootRealismNG::Papyrus {

// Sentinel returned by ApplyDirtinessPainStep when no dirtiness-tier transition
// occurred this step; Papyrus checks for this value to skip the SlaveTats sync.
inline constexpr std::int32_t kNoTierChange = std::numeric_limits<std::int32_t>::min();

// Cache the four GlobalVariable pointers we'll read/write per footstep.
// Called once from PlayerBarefootQuestScript.OnInit and again from
// OnPlayerLoadGame to survive saves.
void InitGlobals(
    RE::StaticFunctionTag*,
    RE::TESGlobal* a_feetDirtiness,
    RE::TESGlobal* a_feetPain,
    RE::TESGlobal* a_feetRoughness,
    RE::TESGlobal* a_playerLastSurfaceDirtiness);

// Pure compute — reads FeetRoughness from the cached global, applies the
// movement-mode multiplier (sneaking / sprinting / walking / running with
// 1.2's corrected ordering), and scales by location * surface roughness.
// Caller supplies the config values + the player's actor state.
float GetStaggerChanceNative(
    RE::StaticFunctionTag*,
    RE::Actor*    a_actor,
    float         a_staggerMultiplier,
    float         a_staggerExponent,
    float         a_sprintingMod,
    float         a_walkingMod,
    float         a_sneakingMod,
    float         a_locationRoughness,
    float         a_surfaceRoughness);

// Updates FeetDirtiness, FeetPain, FeetRoughness, PlayerLastSurfaceDirtiness
// from cached globals using the same formulas as the original Papyrus
// (Clamp() bug fixed inline since C++ doesn't have a no-op pass-by-value
// trap). Returns the new dirtiness tier (-1..3) when it changed this step,
// or kNoTierChange when it didn't.
std::int32_t ApplyDirtinessPainStep(
    RE::StaticFunctionTag*,
    float a_adjustedSurfaceDirtiness,   // SurfaceDirtiness[surface], already * 2 if raining
    float a_locationDirtiness,          // LocationDirtiness[place]
    float a_locationRoughness,          // LocationRoughness[place]
    float a_surfaceRoughness,           // SurfaceRoughness[surface]
    float a_positiveDeltaMul,
    float a_negativeDeltaMul,
    float a_painIncreaseMul,
    float a_painIncreaseExp,
    float a_roughnessIncreaseMul);

}  // namespace BarefootRealismNG::Papyrus
