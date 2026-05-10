<#
.SYNOPSIS
    Bundle the built DLL, compiled .pex, source .psc, README and LICENSE into
    a single .7z that drops into MO2 / a Skyrim Data folder cleanly.

.PARAMETER Version
    Stamp the archive filename (defaults to today's date in yyyy.MM.dd form).

.PARAMETER ModRoot
    Path to the live Barefoot Realism mod folder (where the compiled .pex live).
    Default matches the dev box layout.

.PARAMETER RepoRoot
    Path to the BarefootRealismNG source repo (where build\Release\*.dll lives).

.PARAMETER OutDir
    Where to drop the packaged archive. Defaults to $RepoRoot\dist.

.PARAMETER ZipFallback
    Force the legacy Compress-Archive .zip fallback even if 7z.exe is available.

.EXAMPLE
    pwsh scripts\pack-release.ps1 -Version 0.2.0
    -> dist\BarefootRealismNG-0.2.0.7z
#>

[CmdletBinding()]
param(
    [string] $Version     = (Get-Date -Format 'yyyy.MM.dd'),
    [string] $ModRoot     = 'D:\BarefootRealism - Patched',
    [string] $RepoRoot    = (Split-Path -Parent $PSScriptRoot),
    [string] $OutDir      = $null,
    [switch] $ZipFallback
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

if (-not $OutDir) { $OutDir = Join-Path $RepoRoot 'dist' }

# ---- pre-flight ----------------------------------------------------------

$dll = Join-Path $RepoRoot 'build\Release\BarefootRealismNG.dll'
if (-not (Test-Path $dll)) {
    throw "Plugin DLL not found at $dll. Run `cmake --build build --config Release` first."
}

$pexNames = @(
    'PBFNative',
    'PBFTerrainDetectionQuestScript',
    'PlayerBarefootQuestScript',
    'PBFFeetWashEffectScript',
    'PBFBISPlayerScript'
)

$missing = @()
foreach ($name in $pexNames) {
    $p = Join-Path $ModRoot "Scripts\$name.pex"
    if (-not (Test-Path $p)) { $missing += $p }
}
if ($missing.Count) {
    throw "Missing compiled .pex:`n  $($missing -join "`n  ")`nRun PapyrusCompiler.exe first."
}

# ---- staging -------------------------------------------------------------

$staging = Join-Path $env:TEMP "BarefootRealismNG-pack-$Version-$([guid]::NewGuid().ToString().Substring(0,8))"
Write-Information "Staging in $staging"

New-Item -ItemType Directory -Path "$staging\SKSE\Plugins" | Out-Null
New-Item -ItemType Directory -Path "$staging\Scripts\Source" | Out-Null

Copy-Item -LiteralPath $dll -Destination "$staging\SKSE\Plugins\"

foreach ($name in $pexNames) {
    Copy-Item -LiteralPath (Join-Path $ModRoot "Scripts\$name.pex") -Destination "$staging\Scripts\"
}

# Ship source .psc for transparency / Nexus reviewers
Get-ChildItem -Path (Join-Path $RepoRoot 'papyrus') -Filter '*.psc' |
    Copy-Item -Destination "$staging\Scripts\Source\"

Copy-Item -LiteralPath (Join-Path $RepoRoot 'README.md') -Destination $staging
Copy-Item -LiteralPath (Join-Path $RepoRoot 'LICENSE')   -Destination $staging

# ---- archive --------------------------------------------------------------

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$sevenZipExe = $null
$cmd = Get-Command 7z -ErrorAction SilentlyContinue
if ($cmd) { $sevenZipExe = $cmd.Source }
if (-not $sevenZipExe) {
    foreach ($c in @(
        "$env:ProgramFiles\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
    )) {
        if (Test-Path $c) { $sevenZipExe = $c; break }
    }
}

if ($sevenZipExe -and -not $ZipFallback) {
    $archive = Join-Path $OutDir "BarefootRealismNG-$Version.7z"
    Remove-Item -LiteralPath $archive -ErrorAction SilentlyContinue
    & $sevenZipExe a -t7z -mx=9 $archive (Join-Path $staging '*') | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "7-Zip failed with exit code $LASTEXITCODE" }
} else {
    $archive = Join-Path $OutDir "BarefootRealismNG-$Version.zip"
    Remove-Item -LiteralPath $archive -ErrorAction SilentlyContinue
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $archive -CompressionLevel Optimal
}

Remove-Item -Recurse -Force $staging

$sizeKB = [int]((Get-Item $archive).Length / 1KB)
Write-Information "Packaged $archive ($sizeKB KB)"
Write-Output $archive
