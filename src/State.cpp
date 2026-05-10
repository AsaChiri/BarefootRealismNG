#include "PCH.h"

#include "State.h"

namespace BarefootRealismNG {

State& State::GetSingleton() {
    static State instance;
    return instance;
}

}  // namespace BarefootRealismNG
