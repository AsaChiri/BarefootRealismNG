# Helper scripts

Both scripts target PowerShell 7+ (pwsh) but also work in Windows PowerShell 5.

## `pack-release.ps1`

Bundles `build\Release\BarefootRealismNG.dll`, the compiled `.pex` from the live mod folder, the source `.psc` from `papyrus\`, and `README.md` / `LICENSE` into a single `.7z` ready to upload to Nexus or share. Falls back to `.zip` via `Compress-Archive` if 7-Zip isn't on `PATH` and isn't in the standard `Program Files` install.

```powershell
pwsh scripts\pack-release.ps1 -Version 0.2.0
# -> dist\BarefootRealismNG-0.2.0.7z
```

The archive lays out files so it drops into MO2 / a Skyrim `Data` folder as-is:

```
SKSE\Plugins\BarefootRealismNG.dll
Scripts\PBFNative.pex
Scripts\PBFTerrainDetectionQuestScript.pex
Scripts\PlayerBarefootQuestScript.pex
Scripts\PBFFeetWashEffectScript.pex
Scripts\PBFBISPlayerScript.pex
Scripts\Source\<.psc sources>
README.md
LICENSE
```

Pre-flight: the script aborts with a clear message if `BarefootRealismNG.dll` or any of the five `.pex` files are missing, so a stale build never gets shipped.

## `sync-to-repo.ps1`

The Papyrus `.psc` files are edited in MO2's live mod folder (because that's where the Creation Kit / Papyrus compiler / SKSE all expect them). This script mirrors those files back into `papyrus\` in this repo and commits the diff, so the GitHub source of truth never drifts from what's running in-game.

```powershell
# preview what would change
pwsh scripts\sync-to-repo.ps1 -DryRun

# copy + commit
pwsh scripts\sync-to-repo.ps1 -Message "1.1: fix Clamp bug"

# copy + commit + push
pwsh scripts\sync-to-repo.ps1 -Message "v1.1 release" -Push
```

If the live files are identical to the repo copies the script exits cleanly with no commit (no empty commits ever).
