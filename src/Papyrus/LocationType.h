#pragma once

#include "PCH.h"

namespace BarefootRealismNG::Papyrus {

// Returns the mod's cell category for the actor:
//   0 = owned interior (clean, like a player home)
//   1 = owned interior whose name contains " Mine" / " Dungeon" / " Jail"
//   2 = exterior city skydome (Sky::mode == 2)
//   3 = unowned interior (random dungeon, inn back room, ...)
//   4 = exterior wilderness skydome (Sky::mode == 3)
//
// Mirrors PlayerBarefootQuestScript.GetCurrentLocationType() exactly. The
// Papyrus side still writes the PlayerCellType global; this native only returns.
std::int32_t GetActorLocationType(RE::StaticFunctionTag*, RE::Actor* a_actor);

}  // namespace BarefootRealismNG::Papyrus
