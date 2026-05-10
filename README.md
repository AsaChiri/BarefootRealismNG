# BarefootRealismNG

> Native SKSE accelerator for [**Barefoot Realism**](https://www.loverslab.com/files/file/5070-barefoot-realism/) on Skyrim SE / AE / VR. All gameplay design, formulas, and balance are the **original mod author's** work — this project only swaps the heaviest Papyrus loops for a CommonLibSSE-NG plugin. See [`docs/original-readme.md`](docs/original-readme.md) for the upstream documentation that describes the dirtiness / pain / roughness model.

A handful of native Papyrus functions on the `PBFNative` script replace the parts of the original mod that ran every second / every footstep, plus a few Papyrus-side correctness fixes.

## What it replaces

| Original Papyrus | Replacement |
| --- | --- |
| `PBFTerrainDetectionQuestScript.OnUpdate` — every second, did `2× PlaceAtMe + 2× MoveTo + Spell.Cast + 2× Delete + 9× FindClosestReferenceOfTypeFromRef` to figure out which surface decal had spawned under the player | A single downward havok pick from C++; reads `bhkShape::materialID` and maps to the mod's 0..8 surface ids |
| `PlayerBarefootQuestScript.GetCurrentLocationType` — called twice **per footstep** (~6×/sec while sprinting) doing weather + cell-owner + faction-owner + cell-name substring search | Same logic in C++, one VM call per invocation |
| `PlayerBarefootQuestScript.OnAnimationEvent` math — five global reads, five global writes, two `Math.Pow` calls, ten `Config` property reads, all in Papyrus per footstep | Two native calls (`GetStaggerChanceNative` for pure compute and `ApplyDirtinessPainStep` for the dirtiness/pain/roughness state writes). C++ enforces the `Clamp(...)` correctly that the original Papyrus accidentally dropped on the floor. |

Water detection is delegated to **powerof3's PapyrusExtenderSSE** (`PO3_SKSEFunctions.IsRefInWater`); the surface-material native returns -1 on miss and water resolves on the Papyrus side.

## Papyrus-side correctness fixes shipped alongside

- `Clamp(NewDirtiness, 0, 1)` was a no-op in the original (Papyrus pass-by-value with a discarded return). After enough sprinting, `FeetDirtiness` / `FeetPain` / `FeetRoughness` could drift above 1.0. Fixed to assign the clamped result back.
- The sneak branch in `GetStaggerChance` was unreachable: the original `if IsSprinting / elseif !IsRunning / elseif IsSneaking` chain made the third arm a dead branch because IsSneaking is never reachable past `!IsRunning == false`. Reordered to check `IsSneaking` first.
- Per-footstep `GetCurrentLocationType()` and `GetDirtinessTier()` calls deduplicated.
- `PBFFeetWashEffectScript` (Wash Feet spell) now uses `PO3_SKSEFunctions.IsRefInWater` instead of `IsSwimming` + `Cell.GetWaterLevel`.

## Build (Windows + MSVC + vcpkg)

Prerequisites:

- Visual Studio 2022 with the C++/CMake workload
- vcpkg, with `VCPKG_ROOT` exported (e.g. `setx VCPKG_ROOT D:\vcpkg`)
- The Color-Glass `commonlibsse-ng` registry is wired up via `vcpkg-configuration.json`

```powershell
cmake --preset vs2022-windows
cmake --build build --config Release
```

Output: `build\Release\BarefootRealismNG.dll`.

## Runtime requirements (end users)

- SKSE
- [Address Library for SKSE Plugins](https://www.nexusmods.com/skyrimspecialedition/mods/32444) (or the AE variant)
- [powerof3's Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854) — provides `PO3_SKSEFunctions.IsRefInWater`

## Verification

After install:

1. `My Games\Skyrim Special Edition\SKSE\skse64.log` should mention `BarefootRealismNG.dll loaded`.
2. `My Games\Skyrim Special Edition\SKSE\Plugins\BarefootRealismNG.log` should print `Registered 2 Papyrus natives on PBFNative`.
3. In-game, with feet bare, `getglobalvalue PlayerLastDetectedSurface` should cycle 0..8 across stone / dirt / wood / grass / snow / water as expected.
4. `getglobalvalue PlayerCellType` should match the original mod's behavior:
   - 0 in Breezehome / 1 in Embershard Mine / 2 in open Whiterun / 3 in Riverwood Trader / 4 in the tundra outside Whiterun.

## Layout

```
CMakeLists.txt            build config (uses add_commonlibsse_plugin)
CMakePresets.json         vs2022-windows + ninja-release presets
vcpkg.json                deps: commonlibsse-ng, spdlog
vcpkg-configuration.json  upstream + Color-Glass registry pins
src/
  PCH.h                   precompiled header (RE/, REL/, SKSE/, spdlog)
  ForceIncludes.h         /FI'd everywhere — exposes std::literals at
                          global scope so the auto-generated plugin glue
                          compiles
  Logging.h               spdlog file-sink initialization
  Plugin.cpp              SKSEPluginLoad entry + kPostLoad registration
  Papyrus/
    PBFNative.{h,cpp}     register the two natives
    SurfaceMaterial.cpp   havok pick + MATERIAL_ID -> 0..8 table
    LocationType.cpp      Sky::mode + cell owner + cell name -> 0..4
papyrus/
  PBFNative.psc                          native stub (new)
  PBFTerrainDetectionQuestScript.psc     modified: OnUpdate + DetectTerrain
  PlayerBarefootQuestScript.psc          modified: GetCurrentLocationType
```
