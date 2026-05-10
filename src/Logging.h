#pragma once

#include "PCH.h"

namespace BarefootRealismNG::Logging {

inline void Init() {
    using namespace std::literals;

    auto path = SKSE::log::log_directory();
    if (!path) {
        SKSE::stl::report_and_fail("Could not resolve SKSE log directory."sv);
    }
    *path /= std::format("{}.log", SKSE::PluginDeclaration::GetSingleton()->GetName());

    auto sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(path->string(), true);
    auto log  = std::make_shared<spdlog::logger>("global log"s, std::move(sink));

    log->set_level(spdlog::level::info);
    log->flush_on(spdlog::level::info);

    spdlog::set_default_logger(std::move(log));
    spdlog::set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%l] [%s:%#] %v");
}

}  // namespace BarefootRealismNG::Logging
