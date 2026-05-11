#pragma once

#include "PCH.h"

#include <cstdlib>
#include <string>

namespace BarefootRealismNG::Logging {

// Resolve the desired log level for this run.
//
//   - Default: info (production builds, hot path is silent).
//   - Override: set the env var BAREFOOTREALISMNG_LOG_LEVEL before launching
//     Skyrim to anything spdlog recognises ("trace", "debug", "info", "warn",
//     "error", "critical", "off"). Convenience alias:
//     BAREFOOTREALISMNG_DEBUG=1 also flips to debug.
//
// The diagnostic logs sprinkled through SurfaceMaterial.cpp etc. all use
// `logger::debug`, so flipping the level to debug is what enables them.
inline spdlog::level::level_enum ResolveLogLevel() {
    if (const char* override_ = std::getenv("BAREFOOTREALISMNG_LOG_LEVEL")) {
        const auto lvl = spdlog::level::from_str(override_);
        if (lvl != spdlog::level::off || std::string{ override_ } == "off") {
            return lvl;
        }
    }
    if (const char* debugFlag = std::getenv("BAREFOOTREALISMNG_DEBUG")) {
        if (debugFlag[0] != '\0' && debugFlag[0] != '0') {
            return spdlog::level::debug;
        }
    }
    return spdlog::level::info;
}

inline void Init() {
    using namespace std::literals;

    auto path = SKSE::log::log_directory();
    if (!path) {
        SKSE::stl::report_and_fail("Could not resolve SKSE log directory."sv);
    }
    *path /= std::format("{}.log", SKSE::PluginDeclaration::GetSingleton()->GetName());

    auto sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(path->string(), true);
    auto log  = std::make_shared<spdlog::logger>("global log"s, std::move(sink));

    const auto level = ResolveLogLevel();
    log->set_level(level);
    log->flush_on(level);

    spdlog::set_default_logger(std::move(log));
    spdlog::set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%l] [%s:%#] %v");

    spdlog::info("Log level: {} (set BAREFOOTREALISMNG_DEBUG=1 to enable diagnostics)",
                 spdlog::level::to_string_view(level));
}

}  // namespace BarefootRealismNG::Logging
