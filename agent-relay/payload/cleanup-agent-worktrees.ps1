[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$RemoveBranches
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Invoke-GitCommand {
    param(
        [string]$RepoRoot,
        [string[]]$Arguments
    )

    $quotedArgs = @("-C", $RepoRoot) + $Arguments | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + ($_ -replace '"', '\"') + '"'
        } else {
            $_
        }
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = ($quotedArgs -join " ")
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $null = $process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdout.Trim()
        StdErr = $stderr.Trim()
    }
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$boardPath = Join-Path $root ".codex-agents\board.json"

if (-not (Test-Path -LiteralPath $boardPath)) {
    throw "Could not find board file at $boardPath"
}

try {
    $null = git -C $root rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "not_git"
    }
} catch {
    throw "cleanup-agent-worktrees.ps1 requires a git repository."
}

$board = Get-Content -LiteralPath $boardPath -Raw | ConvertFrom-Json

foreach ($task in $board.tasks) {
    if ($task.workspace -eq $root) {
        continue
    }
    if (-not (Test-Path -LiteralPath $task.workspace)) {
        continue
    }

    $removeResult = Invoke-GitCommand -RepoRoot $root -Arguments @("worktree", "remove", "--force", $task.workspace)
    if ($removeResult.ExitCode -ne 0) {
        $message = $removeResult.StdErr
        if (-not $message) {
            $message = $removeResult.StdOut
        }
        if (-not $message) {
            $message = "git worktree remove failed"
        }
        throw "Failed to remove worktree $($task.workspace): $message"
    }
    Write-Host "Removed worktree: $($task.workspace)" -ForegroundColor Green

    if ($RemoveBranches -and ($task.PSObject.Properties.Name -contains "branch") -and $task.branch) {
        $branchResult = Invoke-GitCommand -RepoRoot $root -Arguments @("branch", "-D", $task.branch)
        if ($branchResult.ExitCode -ne 0) {
            $message = $branchResult.StdErr
            if (-not $message) {
                $message = $branchResult.StdOut
            }
            if (-not $message) {
                $message = "git branch -D failed"
            }
            throw "Failed to remove branch $($task.branch): $message"
        }
        Write-Host "Removed branch: $($task.branch)" -ForegroundColor Green
    }
}
