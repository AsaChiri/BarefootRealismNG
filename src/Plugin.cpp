#include "PCH.h"

#include "Logging.h"
#include "Papyrus/PBFNative.h"

using namespace std::literals;

namespace {

void OnSKSEMessage(SKSE::MessagingInterface::Message* a_msg) {
    if (!a_msg) return;
    if (a_msg->type == SKSE::MessagingInterface::kDataLoaded) {
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
