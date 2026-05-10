#include "PCH.h"

#include "Papyrus/PBFNative.h"
#include "Papyrus/BarefootStep.h"
#include "Papyrus/LocationType.h"
#include "Papyrus/SurfaceMaterial.h"

namespace BarefootRealismNG::Papyrus {

bool Register(RE::BSScript::IVirtualMachine* a_vm) {
    if (!a_vm) {
        logger::error("Papyrus VM unavailable; cannot register natives.");
        return false;
    }

    a_vm->RegisterFunction("GetSurfaceMaterialUnderActor", kClassName, GetSurfaceMaterialUnderActor);
    a_vm->RegisterFunction("GetActorLocationType",         kClassName, GetActorLocationType);
    a_vm->RegisterFunction("InitGlobals",                  kClassName, InitGlobals);
    a_vm->RegisterFunction("GetStaggerChanceNative",       kClassName, GetStaggerChanceNative);
    a_vm->RegisterFunction("ApplyDirtinessPainStep",       kClassName, ApplyDirtinessPainStep);

    logger::info("Registered 5 Papyrus natives on {}", kClassName);
    return true;
}

}  // namespace BarefootRealismNG::Papyrus
