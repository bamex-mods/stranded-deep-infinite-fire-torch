param(
    [Alias("GameDir")]
    [string]$GameRoot = $env:STRANDED_DEEP_GAME_ROOT,
    [switch]$Deploy
)

$ErrorActionPreference = "Stop"

$ModName = "BamEx.InfiniteFireTorch"
$PluginGuid = "bamex.strandeddeep.infinitefiretorch"

$SourceFiles = @(
    (Join-Path $PSScriptRoot "Plugin.cs"),
    (Join-Path $PSScriptRoot "SDK\ModSettingsClient.cs")
)

$BuildDir = Join-Path $PSScriptRoot "build"
$OutputDll = Join-Path $BuildDir "$ModName.dll"

$GameDir = $GameRoot

if ([string]::IsNullOrWhiteSpace($GameDir)) {
    throw "GameRoot was not supplied. Pass -GameRoot or set STRANDED_DEEP_GAME_ROOT."
}

$BepInExCore = Join-Path $GameDir "BepInEx\core"
$ManagedDir = Join-Path $GameDir "Stranded_Deep_Data\Managed"

$BepInExDll = Join-Path $BepInExCore "BepInEx.dll"
$HarmonyDll = Join-Path $BepInExCore "0Harmony.dll"
$UnityEngineDll = Join-Path $ManagedDir "UnityEngine.dll"
$UnityCoreDll = Join-Path $ManagedDir "UnityEngine.CoreModule.dll"

$RequiredFiles = @(
    $BepInExDll,
    $HarmonyDll,
    $UnityEngineDll,
    $UnityCoreDll
)
$RequiredFiles += $SourceFiles

foreach ($RequiredFile in $RequiredFiles) {
    if (-not (Test-Path $RequiredFile)) {
        throw "Required file not found: $RequiredFile"
    }
}

$CompilerCandidates = @(
    "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)

$Csc = $CompilerCandidates |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1

if ($null -eq $Csc) {
    throw "C# compiler csc.exe was not found."
}

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

$CompilerArgs = @(
    "/nologo",
    "/target:library",
    "/optimize+",
    "/out:$OutputDll",
    "/reference:$BepInExDll",
    "/reference:$HarmonyDll",
    "/reference:$UnityEngineDll",
    "/reference:$UnityCoreDll"
)

foreach ($SourceFile in $SourceFiles) {
    $CompilerArgs += $SourceFile
}

Write-Host ""
Write-Host "Building BamEx Infinite Fire Torch v1.1.1..."
Write-Host "Workspace: $PSScriptRoot"
Write-Host "Game:      $GameDir"
Write-Host "Compiler:  $Csc"
Write-Host ""

& $Csc @CompilerArgs

if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path $OutputDll)) {
    throw "Compilation finished without producing $OutputDll."
}

$BuildHash = (Get-FileHash -LiteralPath $OutputDll -Algorithm SHA256).Hash

Write-Host ""
Write-Host "BUILD OK"
Write-Host "Output:  $OutputDll"
Write-Host "SHA256:  $BuildHash"

if (-not $Deploy) {
    Write-Host ""
    Write-Host "Compile-only mode. Runtime DLL was NOT changed."
    Write-Host "Use -Deploy only after a rollback backup exists."
    exit 0
}

function Test-DllContainsGuid([string]$Path, [string]$Needle) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $ascii = [System.Text.Encoding]::ASCII.GetString($bytes)
        if ($ascii.Contains($Needle)) { return $true }

        $unicode = [System.Text.Encoding]::Unicode.GetString($bytes)
        return $unicode.Contains($Needle)
    }
    catch {
        return $false
    }
}

$Plugins = Join-Path $GameDir "BepInEx\plugins"
$PluginDir = Join-Path $Plugins $ModName
$InstalledDll = Join-Path $PluginDir "$ModName.dll"

$GuidMatches = @()
foreach ($dll in Get-ChildItem -LiteralPath $Plugins -Filter "*.dll" -File -Recurse) {
    if (Test-DllContainsGuid $dll.FullName $PluginGuid) {
        $GuidMatches += $dll.FullName
    }
}
$GuidMatches = @($GuidMatches | Sort-Object -Unique)

if ($GuidMatches.Count -gt 1) {
    Write-Host "Duplicate plugin GUID matches:"
    $GuidMatches | ForEach-Object { Write-Host "  $_" }
    throw "Deploy aborted: multiple runtime DLLs contain $PluginGuid"
}

if ($GuidMatches.Count -eq 1 -and
    $GuidMatches[0] -ine $InstalledDll) {

    Write-Host "Existing runtime DLL for this GUID is:"
    Write-Host "  $($GuidMatches[0])"
    Write-Host "Canonical runtime target would be:"
    Write-Host "  $InstalledDll"

    throw "Deploy aborted: runtime folder must be reconciled first; no duplicate was created."
}

New-Item -ItemType Directory -Force -Path $PluginDir | Out-Null
Copy-Item -LiteralPath $OutputDll -Destination $InstalledDll -Force

$RuntimeHash = (Get-FileHash -LiteralPath $InstalledDll -Algorithm SHA256).Hash

Write-Host ""
Write-Host "DEPLOY OK"
Write-Host "Runtime: $InstalledDll"
Write-Host "SHA256:  $RuntimeHash"
Write-Host "BUILD == RUNTIME: $($BuildHash -eq $RuntimeHash)"
