[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetPath = $ProjectRoot
if (-not (Test-Path -LiteralPath $targetPath)) {
    $null = New-Item -ItemType Directory -Path $targetPath -Force
}
$targetRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

function Copy-Template {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [switch]$Overwrite
    )

    $parent = Split-Path -Parent $DestinationPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    if ((Test-Path -LiteralPath $DestinationPath) -and -not $Overwrite) {
        Write-Host "Skipped existing file: $DestinationPath" -ForegroundColor Yellow
        return
    }

    Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
    Write-Host "Installed: $DestinationPath" -ForegroundColor Green
}

function Update-Gitignore {
    param([string]$GitignorePath)

    $entries = @("AGENT.md", "STATUS.md", ".ai-context/")
    $existing = @()
    if (Test-Path -LiteralPath $GitignorePath) {
        $existing = Get-Content -LiteralPath $GitignorePath
    }

    $missing = @($entries | Where-Object { $_ -and ($existing -notcontains $_) })
    if ($missing.Count -eq 0) {
        Write-Host "Skipped existing file: $GitignorePath" -ForegroundColor Yellow
        return
    }

    $lines = @($existing)
    if ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[-1]) -eq $false) {
        $lines += ""
    }
    $lines += "# Local AI working files"
    $lines += $missing
    Set-Content -LiteralPath $GitignorePath -Value $lines -Encoding utf8
    Write-Host "Updated: $GitignorePath" -ForegroundColor Green
}

$files = @(
    @{ source = "AGENTS.md.template"; destination = "AGENTS.md" },
    @{ source = "AGENT.md.template"; destination = "AGENT.md" },
    @{ source = "STATUS.md.template"; destination = "STATUS.md" },
    @{ source = "TASK.template.md"; destination = ".ai-context/TASK.template.md" },
    @{ source = "PR-REVIEW.template.md"; destination = ".ai-context/PR-REVIEW.template.md" }
)

foreach ($file in $files) {
    Copy-Template `
        -SourcePath (Join-Path $scriptRoot $file.source) `
        -DestinationPath (Join-Path $targetRoot $file.destination) `
        -Overwrite:$Force
}

Update-Gitignore -GitignorePath (Join-Path $targetRoot ".gitignore")

Write-Host ""
Write-Host "Agent relay context stack installed into $targetRoot" -ForegroundColor Cyan
