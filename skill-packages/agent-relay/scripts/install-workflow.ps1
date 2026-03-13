[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$packageRoot = Split-Path -Parent $scriptRoot
$payloadRoot = Join-Path $packageRoot "payload"
if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
}
$targetRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

if (-not (Test-Path -LiteralPath $payloadRoot)) {
    throw "Could not find payload directory at $payloadRoot"
}

function Copy-PayloadFile {
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

$payloadFiles = Get-ChildItem -LiteralPath $payloadRoot -Recurse -File
foreach ($file in $payloadFiles) {
    $relativePath = $file.FullName.Substring($payloadRoot.Length).TrimStart('\')
    $destination = Join-Path $targetRoot $relativePath
    Copy-PayloadFile -SourcePath $file.FullName -DestinationPath $destination -Overwrite:$Force
}

Write-Host ""
Write-Host "Agent relay workflow installed into $targetRoot" -ForegroundColor Cyan
Write-Host "Optional next step: merge this snippet into AGENTS.md if the repo has one:" -ForegroundColor Cyan
Write-Host (Join-Path $packageRoot "AGENTS_SNIPPET.md") -ForegroundColor Yellow
