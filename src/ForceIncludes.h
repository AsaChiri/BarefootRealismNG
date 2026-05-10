#pragma once

// This header is force-included into every translation unit (via /FI in
// CMakeLists.txt) so that the std string-view / string / chrono literals are
// usable at global scope. The auto-generated __<Plugin>Plugin.cpp emitted by
// add_commonlibsse_plugin() uses "name"sv at global scope, which the plain
// CommonLibSSE-NG headers don't put into scope (they only inject
// `using namespace std::literals;` inside the SKSE / RE / REL namespaces).
#include <string>
#include <string_view>
using namespace std::literals;
