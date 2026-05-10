#include "PCH.h"

#include "Papyrus/LocationType.h"

namespace BarefootRealismNG::Papyrus {

namespace {

constexpr std::int32_t kOwnedClean    = 0;
constexpr std::int32_t kOwnedDungeon  = 1;
constexpr std::int32_t kCitySkydome   = 2;
constexpr std::int32_t kUnownedDungeon = 3;
constexpr std::int32_t kWilderness    = 4;

// Sky::mode values (matches Weather.GetSkyMode in Papyrus):
//   0 = none / undefined
//   1 = interior
//   2 = exterior city skydome (Whiterun, Solitude, Markarth, ...)
//   3 = exterior wilderness skydome
constexpr std::uint32_t kSkyModeCity       = 2;
constexpr std::uint32_t kSkyModeWilderness = 3;

// Returns true if `haystack` contains the literal `needle` as a substring.
// std::string_view::find is constant-folded for these tiny needles.
bool ContainsToken(std::string_view haystack, std::string_view needle) {
    return haystack.find(needle) != std::string_view::npos;
}

}  // namespace

std::int32_t GetActorLocationType(RE::StaticFunctionTag*, RE::Actor* a_actor) {
    if (!a_actor) {
        return kOwnedClean;
    }

    if (auto* sky = RE::Sky::GetSingleton()) {
        const auto mode = static_cast<std::uint32_t>(sky->mode.get());
        if (mode == kSkyModeCity) {
            return kCitySkydome;
        }
        if (mode == kSkyModeWilderness) {
            return kWilderness;
        }
    }

    auto* cell = a_actor->GetParentCell();
    if (!cell) {
        return kUnownedDungeon;
    }

    const bool ownedByActor   = cell->GetActorOwner() != nullptr;
    const bool ownedByFaction = cell->GetFactionOwner() != nullptr;

    if (!ownedByActor && !ownedByFaction) {
        return kUnownedDungeon;
    }

    const std::string_view name{ cell->GetFullName() ? cell->GetFullName() : "" };
    if (ContainsToken(name, " Mine") ||
        ContainsToken(name, " Dungeon") ||
        ContainsToken(name, " Jail")) {
        return kOwnedDungeon;
    }
    return kOwnedClean;
}

}  // namespace BarefootRealismNG::Papyrus
