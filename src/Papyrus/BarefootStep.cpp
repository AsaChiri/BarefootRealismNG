#include "PCH.h"

#include "Papyrus/BarefootStep.h"

#include "State.h"

#include <algorithm>
#include <cmath>

namespace BarefootRealismNG::Papyrus {

namespace {

// Mirror of PlayerBarefootQuestScript.GetDirtinessTier:
//   <= 0.03  → -1 (None)
//   <= 0.10  →  0 (Light)
//   <= 0.30  →  1 (Medium)
//   <= 0.90  →  2 (Heavy)
//   else     →  3 (Extreme)
std::int32_t DirtinessTier(float v) {
    if (v <= 0.03f) return -1;
    if (v <= 0.10f) return  0;
    if (v <= 0.30f) return  1;
    if (v <= 0.90f) return  2;
    return 3;
}

}  // namespace

void InitGlobals(
    RE::StaticFunctionTag*,
    RE::TESGlobal* a_feetDirtiness,
    RE::TESGlobal* a_feetPain,
    RE::TESGlobal* a_feetRoughness,
    RE::TESGlobal* a_playerLastSurfaceDirtiness)
{
    auto& s = State::GetSingleton();
    s.feetDirtiness              = a_feetDirtiness;
    s.feetPain                   = a_feetPain;
    s.feetRoughness              = a_feetRoughness;
    s.playerLastSurfaceDirtiness = a_playerLastSurfaceDirtiness;

    if (!s.initialized()) {
        logger::warn("InitGlobals received one or more null GlobalVariables; "
                     "per-step natives will no-op until reinitialized.");
    } else {
        logger::info("InitGlobals: cached 4 GlobalVariables for per-step math.");
    }
}

float GetStaggerChanceNative(
    RE::StaticFunctionTag*,
    RE::Actor*    a_actor,
    float         a_staggerMultiplier,
    float         a_staggerExponent,
    float         a_sprintingMod,
    float         a_walkingMod,
    float         a_sneakingMod,
    float         a_locationRoughness,
    float         a_surfaceRoughness)
{
    auto& s = State::GetSingleton();
    if (!a_actor || !s.feetRoughness) {
        return 0.0f;
    }

    const float feetRoughness = s.feetRoughness->value;
    float base = a_staggerMultiplier * std::exp(a_staggerExponent * feetRoughness);

    if (auto* st = a_actor->AsActorState()) {
        // Movement-mode order matches 1.2: sneak first (the engine can have
        // both sneaking + running bits set), then sprint, then walking, else
        // running falls through unscaled (1.0×).
        if (st->IsSneaking()) {
            base *= a_sneakingMod;
        } else if (st->IsSprinting()) {
            base *= a_sprintingMod;
        } else if (!st->actorState1.running) {
            base *= a_walkingMod;
        }
    }

    base *= a_locationRoughness * a_surfaceRoughness;
    return base;
}

std::int32_t ApplyDirtinessPainStep(
    RE::StaticFunctionTag*,
    float a_adjustedSurfaceDirtiness,
    float a_locationDirtiness,
    float a_locationRoughness,
    float a_surfaceRoughness,
    float a_positiveDeltaMul,
    float a_negativeDeltaMul,
    float a_painIncreaseMul,
    float a_painIncreaseExp,
    float a_roughnessIncreaseMul)
{
    auto& s = State::GetSingleton();
    if (!s.initialized()) {
        logger::warn("ApplyDirtinessPainStep called before InitGlobals — no-op");
        return kNoTierChange;
    }

    // ---- Dirtiness -------------------------------------------------------
    const float oldDirtiness = s.feetDirtiness->value;
    const float target = a_adjustedSurfaceDirtiness * a_locationDirtiness;
    s.playerLastSurfaceDirtiness->value = target;

    const float delta = target - oldDirtiness;
    const float dirtinessRate = (delta > 0.0f) ? (a_positiveDeltaMul * delta)
                                               : (a_negativeDeltaMul * delta);
    const float newDirtiness = std::clamp(oldDirtiness + dirtinessRate, 0.0f, 1.0f);
    s.feetDirtiness->value = newDirtiness;

    // ---- Pain ------------------------------------------------------------
    const float feetRoughness = s.feetRoughness->value;
    const float score = (a_locationRoughness * a_surfaceRoughness) / (feetRoughness + 1.0f);
    const float painIncrease = a_painIncreaseMul * std::pow(score, a_painIncreaseExp);

    const float oldPain = s.feetPain->value;
    const float newPain = std::clamp(oldPain + painIncrease, 0.0f, 1.0f);
    s.feetPain->value = newPain;

    // ---- Roughness -------------------------------------------------------
    const float newRoughness = std::clamp(
        feetRoughness + painIncrease * a_roughnessIncreaseMul, 0.0f, 1.0f);
    s.feetRoughness->value = newRoughness;

    // ---- Dirtiness tier transition --------------------------------------
    const auto oldTier = DirtinessTier(oldDirtiness);
    const auto newTier = DirtinessTier(newDirtiness);
    if (oldTier != newTier) {
        return newTier;
    }
    return kNoTierChange;
}

}  // namespace BarefootRealismNG::Papyrus
