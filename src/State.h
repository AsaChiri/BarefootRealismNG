#pragma once

#include "PCH.h"

namespace BarefootRealismNG {

// Plugin-wide cached state. Populated by Papyrus via `PBFNative.InitGlobals`
// at quest startup and after each save reload. All members are raw pointers
// into the game's form table — those persist for the runtime of the process,
// so we don't need to retain them ourselves.
struct State {
    static State& GetSingleton();

    RE::TESGlobal* feetDirtiness               = nullptr;
    RE::TESGlobal* feetPain                    = nullptr;
    RE::TESGlobal* feetRoughness               = nullptr;
    RE::TESGlobal* playerLastSurfaceDirtiness  = nullptr;

    bool initialized() const noexcept {
        return feetDirtiness && feetPain && feetRoughness && playerLastSurfaceDirtiness;
    }
};

}  // namespace BarefootRealismNG
