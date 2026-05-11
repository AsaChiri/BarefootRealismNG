cmake_minimum_required(VERSION 3.21)

project(
    BarefootRealismNG
    VERSION 0.1.0
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ---- CommonLibSSE-NG (alandtse's ng fork) ----
#
# Pulled in as a git submodule at extern/CommonLibSSE-NG. This is the
# integration pattern alandtse's README recommends — the vcpkg path is
# explicitly unmaintained for this fork (older Color-Glass port pins
# upstream 3.7.0, not this 4.18.x ng tree).
#
# Configure CLib's CMake options BEFORE add_subdirectory so they apply at
# its project() call.
set(BUILD_TESTS         OFF CACHE BOOL "Skip CommonLibSSE unit tests."          FORCE)
set(SKSE_SUPPORT_XBYAK  ON  CACHE BOOL "Enable xbyak trampoline support."       FORCE)
set(ENABLE_SKYRIM_SE    ON  CACHE BOOL "Build CommonLibSSE for Skyrim SE."      FORCE)
set(ENABLE_SKYRIM_AE    ON  CACHE BOOL "Build CommonLibSSE for Skyrim AE."      FORCE)
set(ENABLE_SKYRIM_VR    ON  CACHE BOOL "Build CommonLibSSE for Skyrim VR."      FORCE)
add_subdirectory(extern/CommonLibSSE-NG)

# CLib's CMakeLists doesn't auto-include its `add_commonlibsse_plugin()`
# helper — that ships via `cmake/CommonLibSSE.cmake` which is normally
# pulled in transitively when CLib is consumed through `find_package(...
# CONFIG)`. With `add_subdirectory`, we have to include it manually.
include(${CMAKE_CURRENT_SOURCE_DIR}/extern/CommonLibSSE-NG/cmake/CommonLibSSE.cmake)

find_package(spdlog CONFIG REQUIRED)

set(SOURCES
    src/Plugin.cpp
    src/State.cpp
    src/Papyrus/PBFNative.cpp
    src/Papyrus/SurfaceMaterial.cpp
    src/Papyrus/LocationType.cpp
    src/Papyrus/BarefootStep.cpp
)

set(HEADERS
    src/PCH.h
    src/ForceIncludes.h
    src/Logging.h
    src/State.h
    src/Papyrus/PBFNative.h
    src/Papyrus/SurfaceMaterial.h
    src/Papyrus/LocationType.h
    src/Papyrus/BarefootStep.h
)

# add_commonlibsse_plugin is provided by CLib's cmake/CommonLibSSE.cmake,
# included automatically when add_subdirectory() above processes its CMakeLists.
add_commonlibsse_plugin(
    ${PROJECT_NAME}
    AUTHOR "BarefootRealism-NG"
    SOURCES ${SOURCES} ${HEADERS}
)

target_include_directories(${PROJECT_NAME} PRIVATE src)
target_precompile_headers(${PROJECT_NAME} PRIVATE src/PCH.h)
target_link_libraries(${PROJECT_NAME} PRIVATE spdlog::spdlog)

if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE
        /MP
        /W4
        /permissive-
        /Zc:__cplusplus
        /Zc:preprocessor
        /utf-8
        /EHsc
        # Force-include ForceIncludes.h so std::literals are visible at
        # global scope in the auto-generated plugin glue.
        /FI${CMAKE_CURRENT_SOURCE_DIR}/src/ForceIncludes.h
    )
endif()
