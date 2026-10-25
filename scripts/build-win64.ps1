<#
.SYNOPSIS
  Builds the prebuilt Win64 plugin zips by hand, named like the release CI's.

.DESCRIPTION
  Runs RunUAT BuildPlugin against each stock Launcher engine, so a
  Blueprint-only project can load the result without compiling it, then zips
  it with CLX\ at the top. For every engine it writes two identical files to
  dist\: clx-ue-<Tag>-UE<engine>-Win64.zip and clx-ue-latest-UE<engine>-Win64.zip.
  Upload both to plugins/ in the clockworks-downloads bucket, the versioned one
  first. With -Upload it does that itself through the b2 command-line tool.

  Needs the engines from the Epic Games Launcher and Visual Studio 2022 with
  the "Game development with C++" workload. Runs in Windows PowerShell 5.1:
    powershell -ExecutionPolicy Bypass -File scripts\build-win64.ps1 -Tag v1.1

.PARAMETER Tag
  The release tag the zips belong to, such as v1.1.

.PARAMETER Engine
  Engine versions to build for (default 5.6).

.PARAMETER Upload
  Upload the zips with b2. Needs b2 on PATH and the B2_APPLICATION_KEY_ID,
  B2_APPLICATION_KEY and B2_BUCKET_NAME environment variables.
#>
param(
  [Parameter(Mandatory = $true)][string]$Tag,
  [string[]]$Engine = @('5.6'),
  [switch]$Upload
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $repo 'dist'
# Short scratch path: Unreal's intermediate paths get long.
$work = Join-Path $env:SystemDrive 'clx-ue-build'
New-Item -ItemType Directory -Force $dist | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem

if ($Upload) {
  if (-not (Get-Command b2 -ErrorAction SilentlyContinue)) { throw 'b2 is not on PATH.' }
  foreach ($v in 'B2_APPLICATION_KEY_ID', 'B2_APPLICATION_KEY', 'B2_BUCKET_NAME') {
    if (-not [Environment]::GetEnvironmentVariable($v)) { throw "Set $v first." }
  }
}

# The Launcher records every engine it installed, on any drive.
$installs = @()
$dat = Join-Path $env:ProgramData 'Epic\UnrealEngineLauncher\LauncherInstalled.dat'
if (Test-Path $dat) { $installs = (Get-Content $dat -Raw | ConvertFrom-Json).InstallationList }

$zips = @()
foreach ($v in $Engine) {
  $root = $installs | Where-Object { $_.AppName -eq "UE_$v" } |
    Select-Object -First 1 -ExpandProperty InstallLocation
  if (-not $root) { $root = Join-Path $env:ProgramFiles "Epic Games\UE_$v" }
  $uat = Join-Path $root 'Engine\Build\BatchFiles\RunUAT.bat'
  if (-not (Test-Path $uat)) { throw "Unreal Engine $v is not installed (no $uat)." }

  # Build from a copy: the Binaries and Intermediate committed to the repo
  # were built for 5.3 and must stay out of the build.
  $src = Join-Path $work "UE$v\src\CLX"
  $pkg = Join-Path $work "UE$v\pkg\CLX"
  if (Test-Path (Join-Path $work "UE$v")) { Remove-Item -Recurse -Force (Join-Path $work "UE$v") }
  New-Item -ItemType Directory -Force $src | Out-Null
  foreach ($item in 'CLX.uplugin', 'Source', 'Resources', 'Content') {
    Copy-Item -Recurse (Join-Path $repo $item) $src
  }

  # Builds the editor module plus Development/Shipping game targets, and
  # stamps this engine version into the packaged .uplugin.
  & $uat BuildPlugin "-Plugin=$src\CLX.uplugin" "-Package=$pkg" -TargetPlatforms=Win64
  if ($LASTEXITCODE -ne 0) { throw "BuildPlugin failed for UE $v (exit $LASTEXITCODE)." }
  $hostProject = Join-Path $pkg 'HostProject'
  if (Test-Path $hostProject) { Remove-Item -Recurse -Force $hostProject }

  $zip = Join-Path $dist "clx-ue-$Tag-UE$v-Win64.zip"
  $latest = Join-Path $dist "clx-ue-latest-UE$v-Win64.zip"
  Remove-Item -Force $zip, $latest -ErrorAction SilentlyContinue
  # includeBaseDirectory puts CLX\ at the top of the zip.
  [IO.Compression.ZipFile]::CreateFromDirectory($pkg, $zip, 'Optimal', $true)
  Copy-Item $zip $latest
  $zips += , @($zip, $latest)
}

Write-Output 'Built:'
$zips | ForEach-Object { Write-Output "  $($_[0])"; Write-Output "  $($_[1])" }

if ($Upload) {
  # Versioned objects first, then the -latest copies, so a -latest link never
  # points at a release that's only half uploaded.
  foreach ($i in 0, 1) {
    foreach ($pair in $zips) {
      $f = $pair[$i]
      & b2 file upload --no-progress $env:B2_BUCKET_NAME $f "plugins/$(Split-Path -Leaf $f)"
      if ($LASTEXITCODE -ne 0) { throw "Upload failed: $f" }
    }
  }
}
