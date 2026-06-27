# Release builds with optional Supabase dart-defines.
# From repo root:
#   .\scripts\build_production.ps1 -Target requestor
# Or copy defines.production.json.example to defines.production.json (gitignored).

param(
    [ValidateSet("requestor", "technician", "both")]
    [string] $Target = "both",

    [ValidateSet("apk", "appbundle", "ipa")]
    [string] $AndroidFormat = "apk"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$DefinesFile = Join-Path $ScriptDir "defines.production.json"

function Get-DefineArgList {
    if (Test-Path $DefinesFile) {
        Write-Host "Using --dart-define-from-file: $DefinesFile" -ForegroundColor Cyan
        return @("--dart-define-from-file=$DefinesFile")
    }
    $out = @()
    if (-not [string]::IsNullOrWhiteSpace($env:SUPABASE_URL)) {
        $out += "--dart-define=SUPABASE_URL=$($env:SUPABASE_URL)"
    }
    if (-not [string]::IsNullOrWhiteSpace($env:SUPABASE_ANON_KEY)) {
        $out += "--dart-define=SUPABASE_ANON_KEY=$($env:SUPABASE_ANON_KEY)"
    }
    return $out
}

$defineArgList = Get-DefineArgList

function Invoke-FlutterRelease {
    param(
        [string] $AppFolderName,
        [string] $Format
    )
    $appPath = Join-Path $RepoRoot "apps\$AppFolderName"
    Push-Location $appPath
    try {
        if ($Format -eq "ipa") {
            $exportPlist = Join-Path $appPath "ios/ExportOptions.plist"
            $exportOpts = @()
            if (Test-Path $exportPlist) {
                $exportOpts = @("--export-options-plist=ios/ExportOptions.plist")
            }
            $cmd = @("build", "ipa", "--release") + $defineArgList + $exportOpts
        } else {
            $cmd = @("build", $Format, "--release") + $defineArgList
        }
        Write-Host ">>> $($AppFolderName): flutter $($cmd -join ' ')" -ForegroundColor Cyan
        & flutter @cmd
    } finally {
        Pop-Location
    }
}

switch ($Target) {
    "requestor" { Invoke-FlutterRelease "requestor_cmms" $AndroidFormat }
    "technician" { Invoke-FlutterRelease "technician_cmms" $AndroidFormat }
    "both" {
        Invoke-FlutterRelease "requestor_cmms" $AndroidFormat
        Invoke-FlutterRelease "technician_cmms" $AndroidFormat
    }
}

Write-Host "Done." -ForegroundColor Green
