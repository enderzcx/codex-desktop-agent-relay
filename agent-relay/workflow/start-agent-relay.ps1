[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)]
    [string]$Goal,
    [ValidateSet("general", "ceo-review", "eng-review", "staff-debug", "qa-bug-hunt")]
    [string]$Mode = "general",
    [string]$ContextNote = "Add the real files, flows, and constraints before launching workers.",
    [string[]]$Roles = @(),
    [switch]$UseWorktrees,
    [switch]$PrepareOnly,
    [switch]$NoOpenWindows,
    [switch]$NoWatch,
    [int]$PollSeconds = 15,
    [int]$TimeoutMinutes = 90,
    [string]$CodexCommand = "codex"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$spawnScript = Join-Path $root "spawn-agents.ps1"
$watchScript = Join-Path $root "watch-agent-results.ps1"

if (-not (Test-Path -LiteralPath $spawnScript)) {
    throw "Could not find spawn-agents.ps1 at $spawnScript"
}

if (-not (Test-Path -LiteralPath $watchScript)) {
    throw "Could not find watch-agent-results.ps1 at $watchScript"
}

function Get-ModePreset {
    param([string]$SelectedMode)

    switch ($SelectedMode) {
        "ceo-review" {
            return [pscustomobject]@{
                Roles = @("ceo", "product-manager", "risk-reviewer")
                ContextNote = "Run this as an executive/product challenge. Pressure-test whether the problem is worth solving, what the user actually needs, what should be cut, and which hidden assumptions or market risks could invalidate the idea."
            }
        }
        "eng-review" {
            return [pscustomobject]@{
                Roles = @("architect", "staff-engineer", "reviewer")
                ContextNote = "Run this as an engineering architecture review. Focus on system boundaries, dependencies, failure modes, implementation order, and the smallest technically credible path."
            }
        }
        "staff-debug" {
            return [pscustomobject]@{
                Roles = @("incident-commander", "staff-debugger", "reviewer")
                ContextNote = "Run this as a staff-level production debugging session. Focus on impact, containment, root cause, strongest evidence, and what must be true before calling the issue resolved."
            }
        }
        "qa-bug-hunt" {
            return [pscustomobject]@{
                Roles = @("qa-hunter", "repro-engineer", "triage-reviewer")
                ContextNote = "Run this as a QA bug hunt. Focus on user-visible failures, crisp repro steps, severity, release risk, and which issues should block release."
            }
        }
        default {
            return [pscustomobject]@{
                Roles = @("implementer", "tester", "reviewer")
                ContextNote = "Add the real files, flows, and constraints before launching workers."
            }
        }
    }
}

$preset = Get-ModePreset -SelectedMode $Mode
if ($Roles.Count -eq 0) {
    $Roles = @($preset.Roles)
}

if ($ContextNote -eq "Add the real files, flows, and constraints before launching workers.") {
    $ContextNote = $preset.ContextNote
}

& $spawnScript `
    -ProjectRoot $root `
    -Goal $Goal `
    -ContextNote $ContextNote `
    -Roles $Roles `
    -UseWorktrees:$UseWorktrees `
    -NoOpenWindows:($PrepareOnly -or $NoOpenWindows) `
    -CodexCommand $CodexCommand

if ($PrepareOnly) {
    Write-Host ""
    Write-Host "Prepared worker tasks only. Edit the task files, then rerun start-agent-relay.ps1 without -PrepareOnly." -ForegroundColor Yellow
    exit 0
}

if ($NoWatch) {
    Write-Host ""
    Write-Host "Worker launch completed. Watcher was skipped because -NoWatch was set." -ForegroundColor Yellow
    exit 0
}

& $watchScript `
    -ProjectRoot $root `
    -PollSeconds $PollSeconds `
    -TimeoutMinutes $TimeoutMinutes
