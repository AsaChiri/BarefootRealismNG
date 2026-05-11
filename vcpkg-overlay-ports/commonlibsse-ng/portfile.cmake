# Overlay port for commonlibsse-ng.
#
# Color-Glass's vcpkg-colorglass registry pins commonlibsse-ng at 3.7.0
# (CharmedBaryon/CommonLibSSE @ c4ab853d…), which still spells the
# bhkCharacterController surface-material field as `unk300` and is missing
# many other reverse-engineering refinements landed in the past two years.
#
# This overlay replaces that port with alandtse/CommonLibVR's `ng` branch
# at 4.18.0 (drop-in API: same `commonlibsse-ng` port name, same
# `CommonLibSSE` CMake target, same `add_commonlibsse_plugin()` helper).
#
# To roll back: delete this overlay-port directory and remove the
# `overlay-ports` entry in `vcpkg-configuration.json`.

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO alandtse/CommonLibVR
    REF 8c4025b01fac2bea1bbe73a3a9da7b4fde338343
    SHA512 92aa5930a5500601ae0a8418161bdb0629ed5ee9076e7a93e3969a5dc4f4d59b24fa586c2be0b3ad6c0d87e3af82b7f233ceee8b87e3501285168507fbdc5192
    HEAD_REF ng
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTS=OFF
        -DSKSE_SUPPORT_XBYAK=ON
        -DENABLE_SKYRIM_SE=ON
        -DENABLE_SKYRIM_AE=ON
        # VR is disabled because alandtse's repo pulls OpenVR as a git
        # submodule under extern/openvr/headers/, which the GitHub tarball
        # archive doesn't include. Re-enable only after wiring up a proper
        # submodule fetch (or vendoring OpenVR headers) — Barefoot Realism
        # has no VR-only behavior, so skipping it costs us nothing today.
        -DENABLE_SKYRIM_VR=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME CommonLibSSE CONFIG_PATH lib/cmake)
vcpkg_copy_pdbs()

# The upstream install lays out CMake configs under both `share/CommonLibSSE/`
# and `share/CommonLibSSE/CommonLibSSE/`. Color-Glass's older port flattened
# this; mirror that for compatibility with consumers that include
# `${CommonLibSSE_DIR}/CommonLibSSE.cmake` directly.
file(GLOB CMAKE_CONFIGS "${CURRENT_PACKAGES_DIR}/share/CommonLibSSE/CommonLibSSE/*.cmake")
if(CMAKE_CONFIGS)
    file(INSTALL ${CMAKE_CONFIGS} DESTINATION "${CURRENT_PACKAGES_DIR}/share/CommonLibSSE")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/CommonLibSSE/CommonLibSSE")
endif()

# Ship the `add_commonlibsse_plugin()` helper script alongside the CMake
# config so `find_package(CommonLibSSE CONFIG)` brings it in automatically.
if(EXISTS "${SOURCE_PATH}/cmake/CommonLibSSE.cmake")
    file(INSTALL "${SOURCE_PATH}/cmake/CommonLibSSE.cmake"
         DESTINATION "${CURRENT_PACKAGES_DIR}/share/CommonLibSSE")
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${SOURCE_PATH}/LICENSE"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
     RENAME copyright)
