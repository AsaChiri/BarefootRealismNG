cmake_minimum_required(VERSION 3.21)

project(
    BarefootRealismNG
    VERSION 0.1.0
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# CommonLibSSE-NG provides this CMake function via the vcpkg port.
# Newer alandtse fork (4.18+) re-exports transitive deps on DirectXTK and
# DirectXMath, so we have to import them before the CommonLibSSE config
# script tries to resolve its target_link_libraries chain.
find_package(directxmath CONFIG REQUIRED)
find_package(directxtk   CONFIG REQUIRED)
find_package(CommonLibSSE CONFIG REQUIRED)
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

add_commonlibsse_plugin(
    ${PROJECT_NAME}
    AUTHOR "BarefootRealism-NG"
    SOURCES ${SOURCES} ${HEADERS}
)

target_include_directories(${PROJECT_NAME} PRIVATE src)
target_precompile_headers(${PROJECT_NAME} PRIVATE src/PCH.h)
target_link_libraries(${PROJECT_NAME} PRIVATE spdlog::spdlog)

# MSVC: enable parallel build, treat all but a small set of warnings as errors.
if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE
        /MP
        /W4
        /permissive-
        /Zc:__cplusplus
        /Zc:preprocessor
        /utf-8
        /EHsc
        # Force-include ForceIncludes.h into every TU (including the
        # auto-generated __<Plugin>Plugin.cpp emitted by
        # add_commonlibsse_plugin) so std::literals are visible at global scope.
        /FI${CMAKE_CURRENT_SOURCE_DIR}/src/ForceIncludes.h
    )
endif()
