# BarefootRealismNG

Native SKSE accelerator for the [Barefoot Realism](https://www.loverslab.com/files/file/5070-barefoot-realism/) Skyrim SE/AE/VR mod.

Replaces two of Barefoot Realism's most expensive Papyrus paths with a single CommonLibSSE-NG plugin that exposes two native Papyrus functions on the `PBFNative` script.

## What it replaces

| Original Papyrus | Replacement |
| --- | --- |
| `PBFTerrainDetectionQuestScript.OnUpdate` — every second, did `2× PlaceAtMe + 2× MoveTo + Spell.Cast + 2× Delete + 9× FindClosestReferenceOfTypeFromRef` to figure out which surface decal had spawned under the player | A single downward havok pick from C++; reads `bhkShape::materialID` and maps to the mod's 0..8 surface ids |
| `PlayerBarefootQuestScript.GetCurrentLocationType` — called twice **per footstep** (~6×/sec while sprinting) doing weather + cell-owner + faction-owner + cell-name substring search | Same logic in C++, one VM call per invocation |

Water detection is delegated to **powerof3's PapyrusExtenderSSE** (`PO3_SKSEFunctions.IsRefInWater`); the surface-material native returns -1 on miss and water resolves on the Papyrus side.

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

## Deploy

Copy the DLL into the mod folder so SKSE picks it up:

```
D:\BarefootRealism - Patched\SKSE\Plugins\BarefootRealismNG.dll
```

## Recompile the changed Papyrus

The repo ships three Papyrus sources under `papyrus/`:

| File | Status | Replaces |
| --- | --- | --- |
| `PBFNative.psc` | new — native stub | n/a |
| `PBFTerrainDetectionQuestScript.psc` | modified | gutted `OnUpdate` / `DetectTerrain` |
| `PlayerBarefootQuestScript.psc` | modified | replaced `GetCurrentLocationType` |

Drop these into the BarefootRealism mod's `Scripts\Source\` (overwrite the existing two), then recompile.

This repo's authoring used **Bethesda's bundled `PapyrusCompiler.exe`** (ships with Skyrim SE/AE). [russo-2025/papyrus-compiler](https://github.com/russo-2025/papyrus-compiler) is a fine alternative if installed; the Bethesda compiler is what's already on disk for any Skyrim modder.

PowerShell, with paths matching this dev box (substitute for your own):

```powershell
$compiler = "D:\SteamLibrary\steamapps\common\Skyrim Special Edition\Papyrus Compiler\PapyrusCompiler.exe"
$flags    = "D:\Program Files\Skyrim\Data\scripts\Source\TESV_Papyrus_Flags.flg"
$mods     = "D:\ModOrganizer\Skyrim Special Edition\mods"
$srcDir   = "D:\BarefootRealism - Patched\Scripts\Source"
$outDir   = "D:\BarefootRealism - Patched\Scripts"

# IMPORTANT: SKSE-extended sources MUST come BEFORE vanilla so SKSE's Armor.psc
# (which adds GetMaskForSlot etc.) shadows the vanilla Armor.psc.
$imports = @(
    "$mods\Skyrim Script Extender (SKSE64)\Scripts\Source",
    "<Skyrim AE backup>\Data\Source\Scripts",
    "$mods\powerofthree's Papyrus Extender\Source\scripts",
    "$mods\SkyUI_5.1_SDK\Scripts\Source",
    "$mods\SlaveTatsNG\Source\Scripts",
    "$mods\SlaveTatsNG\Scripts\Source",
    "$mods\JContainers SE\scripts\source",
    "$mods\RaceMenu_backup\Scripts\source",
    $srcDir
) -join ';'

Push-Location $srcDir
foreach ($name in 'PBFNative','PBFTerrainDetectionQuestScript','PlayerBarefootQuestScript') {
    & $compiler $name "-f=$flags" "-i=$imports" "-o=$outDir"
}
Pop-Location
```

Notes on import paths:
- Vanilla `.psc` for `GlobalVariable`, `Light`, `Hazard`, `ImpactDataSet`, etc. only ship with **AE installs that have extracted `Data\Source\Scripts`** — current Skyrim SE/AE ships them as a `Scripts.zip` inside `Data\`. The dev box used a backup install (`Skyrim Special Edition - 640 backup`) that had them already extracted; if your install only has `Scripts.zip`, extract it first.
- `SlaveTatsNG` ships its scripts in **two** folders (`Source\Scripts\` for the public `SlaveTats` wrapper and `Scripts\Source\` for the internal `SlaveTatsNG.psc` implementation). Both need to be on the path.
- `NiOverride.psc` lives in `RaceMenu`'s mod data; on the dev box only `RaceMenu_backup` had it extracted.

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

## Notes for future work

- Material map (`MapMaterialId` in `SurfaceMaterial.cpp`) is built from Skyrim's documented `MATERIAL_ID` values. Niche cells (volcanic tundra, blackreach) may surface unmapped ids; the native debug-logs each so the table can be expanded from real-world data.
- The mod's `.esp` is intentionally not modified. The `PBFDetectSurfaceSpell`, `DummyObject`, and 9 `PBF*Hazard` forms remain bound to the quest script's properties so existing save games stay valid.
- `PBFFeetWashEffectScript` still uses vanilla `IsSwimming` / `GetWaterLevel`. That's a one-shot cold path on spell cast and not worth touching in v1; could be migrated to `PO3_SKSEFunctions.IsRefInWater` for consistency in v1.1.
