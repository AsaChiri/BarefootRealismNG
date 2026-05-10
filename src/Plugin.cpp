#include "PCH.h"

#include "Logging.h"
#include "Papyrus/PBFNative.h"

#include <windows.h>

using namespace std::literals;

namespace {

void OnSKSEMessage(SKSE::MessagingInterface::Message* a_msg) {
    if (!a_msg) return;
    if (a_msg->type == SKSE::MessagingInterface::kDataLoaded) {
        // po3's Papyrus Extender is a hard *Papyrus-side* dependency
        // (PBFTerrainDetectionQuestScript and PBFFeetWashEffectScript call
        // PO3_SKSEFunctions.IsRefInWater). SKSE itself doesn't enforce this
        // since it's not a CommonLibSSE inter-plugin dep — so detect it
        // ourselves by walking the loaded module list and surface a clear
        // warning if it's missing. The mod will still load, but the wash
        // spell and water short-circuit will error at Papyrus call time.
        if (!::GetModuleHandleW(L"po3_PapyrusExtender.dll") &&
            !::GetModuleHandleW(L"po3_PapyrusExtenderVR.dll")) {
            logger::warn(
                "po3 PapyrusExtenderSSE not detected. The terrain & wash-feet scripts "
                "depend on PO3_SKSEFunctions.IsRefInWater. Install "
                "https://www.nexusmods.com/skyrimspecialedition/mods/22854 "
                "or the VR equivalent.");
        } else {
            logger::info("po3 PapyrusExtenderSSE detected.");
        }
        logger::info("BarefootRealismNG: Data loaded — natives ready.");
    }
}

}  // namespace

SKSEPluginLoad(const SKSE::LoadInterface* a_skse) {
    SKSE::Init(a_skse);

    BarefootRealismNG::Logging::Init();
    if (auto* decl = SKSE::PluginDeclaration::GetSingleton()) {
        const auto v = decl->GetVersion();
        logger::info("BarefootRealismNG {}.{}.{} loading...", v.major(), v.minor(), v.patch());
    }

    // Confirm Address Library is wired up. The plugin descriptor declares
    // VersionIndependence::AddressLibrary, so SKSE refuses to load us if the
    // matching version-x-y-z.bin is missing for this runtime; if we reach
    // here, the database is present. Logging the runtime version gives users
    // (and bug reports) a clear paper trail.
    const auto runtimeVersion = REL::Module::get().version();
    logger::info("Runtime version {}.{}.{}.{} — Address Library bound.",
                 runtimeVersion[0], runtimeVersion[1], runtimeVersion[2], runtimeVersion[3]);

    auto papyrus = SKSE::GetPapyrusInterface();
    if (!papyrus || !papyrus->Register(BarefootRealismNG::Papyrus::Register)) {
        logger::error("Failed to register Papyrus natives — plugin will be inert.");
        return false;
    }

    auto messaging = SKSE::GetMessagingInterface();
    if (messaging) {
        messaging->RegisterListener(OnSKSEMessage);
    }

    logger::info("BarefootRealismNG ready.");
    return true;
}
