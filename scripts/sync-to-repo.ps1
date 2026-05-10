<#
.SYNOPSIS
    Mirror modified Papyrus sources from the live mod folder back into this
    git repo, then optionally commit and push the changes.

    Use this whenever you iterate on a .psc inside the MO2 mod folder and
    want the change persisted back to the source tree.

.PARAMETER ModRoot
    Path to the live Barefoot Realism mod folder. Default matches the dev box.

.PARAMETER RepoRoot
    Path to this repo. Defaults to the parent of the script's directory.

.PARAMETER Message
    Commit message. If omitted and there are changes, a generic message is used.

.PARAMETER Push
    Run `git push` after committing.

.PARAMETER DryRun
    Print what would be copied/committed without touching anything.

.EXAMPLE
    pwsh scripts\sync-to-repo.ps1 -DryRun
    pwsh scripts\sync-to-repo.ps1 -Message "1.1: fix Clamp bug"
    pwsh scripts\sync-to-repo.ps1 -Message "v1.1 release" -Push
#>

[CmdletBinding()]
param(
    [string] $ModRoot  = 'D:\BarefootRealism - Patched',
    [string] $RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string] $Message  = '',
    [switch] $Push,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# Source-of-truth pairs. Keep this in sync with scripts touched by the plugin.
$pairs = @(
    @{ Src = "$ModRoot\Scripts\Source\PBFNative.psc"                      ; Dst = "$RepoRoot\papyrus\PBFNative.psc" },
    @{ Src = "$ModRoot\Scripts\Source\PBFTerrainDetectionQuestScript.psc" ; Dst = "$RepoRoot\papyrus\PBFTerrainDetectionQuestScript.psc" },
    @{ Src = "$ModRoot\Scripts\Source\PlayerBarefootQuestScript.psc"      ; Dst = "$RepoRoot\papyrus\PlayerBarefootQuestScript.psc" },
    @{ Src = "$ModRoot\Scripts\Source\PBFFeetWashEffectScript.psc"        ; Dst = "$RepoRoot\papyrus\PBFFeetWashEffectScript.psc" },
    @{ Src = "$ModRoot\Scripts\Source\PBFBISPlayerScript.psc"             ; Dst = "$RepoRoot\papyrus\PBFBISPlayerScript.psc" }
)

$changed = New-Object 'System.Collections.Generic.List[hashtable]'
foreach ($p in $pairs) {
    if (-not (Test-Path $p.Src)) {
        Write-Warning "Source missing, skipping: $($p.Src)"
        continue
    }
    $srcHash = (Get-FileHash -Algorithm SHA256 $p.Src).Hash
    $dstHash = if (Test-Path $p.Dst) { (Get-FileHash -Algorithm SHA256 $p.Dst).Hash } else { '<missing>' }
    if ($srcHash -ne $dstHash) {
        $changed.Add($p)
    }
}

if ($changed.Count -eq 0) {
    Write-Information 'No Papyrus changes to sync.'
    return
}

Write-Information "Changed ($($changed.Count)):"
foreach ($p in $changed) { Write-Information "  $($p.Dst)" }

if ($DryRun) {
    Write-Information '(dry run — no files copied, no commits made)'
    return
}

foreach ($p in $changed) {
    Copy-Item -LiteralPath $p.Src -Destination $p.Dst -Force
}

Push-Location $RepoRoot
try {
    & git add -A | Out-Null
    if (-not $Message) {
        $Message = "Sync Papyrus from mod folder ({0} file{1})" -f $changed.Count, $(if ($changed.Count -eq 1) {''} else {'s'})
    }
    & git commit -m $Message
    if ($LASTEXITCODE -ne 0) {
        throw "git commit failed (exit $LASTEXITCODE)"
    }
    if ($Push) {
        & git push
        if ($LASTEXITCODE -ne 0) {
            throw "git push failed (exit $LASTEXITCODE)"
        }
    }
} finally {
    Pop-Location
}
