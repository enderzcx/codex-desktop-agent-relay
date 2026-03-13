[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [Parameter(Mandatory = $true)]
    [string]$Goal,
    [string]$ContextNote = "Add the real files, flows, and constraints before launching workers.",
    [string[]]$Roles = @("implementer", "tester", "reviewer"),
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
