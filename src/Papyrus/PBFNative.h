#pragma once

#include "PCH.h"

namespace BarefootRealismNG::Papyrus {

inline constexpr std::string_view kClassName = "PBFNative";

bool Register(RE::BSScript::IVirtualMachine* a_vm);

}  // namespace BarefootRealismNG::Papyrus
