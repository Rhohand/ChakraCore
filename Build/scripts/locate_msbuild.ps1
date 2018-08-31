#-------------------------------------------------------------------------------------------------------
# Copyright (C) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE.txt file in the project root for full license information.
#-------------------------------------------------------------------------------------------------------

# Locate-MSBuild
#
# Locate and return the preferred location of MSBuild on this machine.

. $PSScriptRoot\util.ps1

# helper to try to locate a single version installed under "Microsoft Visual Studio" instead of under "MSBuild"
function Locate-MSBuild-Modern-Version([string]$product, [string]$version) {
    $msbuildTemplate = "{0}\Microsoft Visual Studio\2017\{1}\MSBuild\{2}\Bin\{3}\msbuild.exe"
    $msbuildUnscoped = "{0}\Microsoft Visual Studio\2017\{1}\MSBuild\{2}\Bin\msbuild.exe"
    # e.g. C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe

    $msbuildExe = $msbuildTemplate -f "${Env:ProgramFiles}", $product, $version, "x86"
    $_ = WriteMessage "Trying `"$msbuildExe`""
    if (Test-Path $msbuildExe) { return $msbuildExe }

    $msbuildExe = $msbuildUnscoped -f "${Env:ProgramFiles(x86)}", $product, $version
    $_ = WriteMessage "Trying `"$msbuildExe`""
    if (Test-Path $msbuildExe) { return $msbuildExe }

    $msbuildExe = $msbuildTemplate -f "${Env:ProgramFiles(x86)}", $product, $version, "amd64"
    $_ = WriteMessage "Trying `"$msbuildExe`""
    if (Test-Path $msbuildExe) { return $msbuildExe }
}

# helper to try to locate a single version
function Locate-MSBuild-Version([string]$version) {
    $msbuildTemplate = "{0}\msbuild\{1}\Bin\{2}\msbuild.exe"
    $msbuildUnscoped = "{0}\msbuild\{1}\Bin\msbuild.exe"

    $msbuildExe = $msbuildTemplate -f "${Env:ProgramFiles}", $version, "x86"
    $_ = WriteMessage "Trying `"$msbuildExe`""
    if (Test-Path $msbuildExe) { return $msbuildExe }

    $msbuildExe = $msbuildUnscoped -f "${Env:ProgramFiles(x86)}", $version
    $_ = WriteMessage "Trying `"$msbuildExe`""
    if (Test-Path $msbuildExe) { return $msbuildExe }

    $msbuildExe = $msbuildTemplate -f "${Env:ProgramFiles(x86)}", $version, "amd64"
    $_ = WriteMessage "Trying `"$msbuildExe`""
    if (Test-Path $msbuildExe) { return $msbuildExe }

    return "" # didn't find it so return empty string
}

function Locate-MSBuild(
        $product = "Enterprise",
        $versionMajor = "15",
        # Skip 13
        $versionDecrement = @(-1, -3)
    ) {
    $msbuildExe = "msbuild.exe"
    if (Get-Command $msbuildExe -ErrorAction SilentlyContinue) { return $msbuildExe }

    $_ = WriteMessage "msbuild.exe not found on PATH, trying Dev15..."

    $msbuildExe = Locate-MSBuild-Modern-Version -product "$product" -version "$versionMajor.0"
    if ($msbuildExe -and (Test-Path $msbuildExe)) {
        $_ = WriteMessage "Found `"$msbuildExe`""
        return $msbuildExe
    }

    $penuntimateVersionMajor = $versionMajor - $versionDecrement[0]

    $_ = WriteMessage "Dev$versionMajor not found, trying Dev$penuntimateVersionMajor..."

    $msbuildExe = Locate-MSBuild-Version("$penuntimateVersionMajor.0")
    if ($msbuildExe -and (Test-Path $msbuildExe)) {
        $_ = WriteMessage "Found `"$msbuildExe`""
        return $msbuildExe
    }

    $previousPenuntimateVersionMajor = $versionMajor - $versionDecrement[1]

    $_ = WriteMessage "Dev$penuntimateVersionMajor not found, trying Dev$previousPenuntimateVersionMajor..."

    $msbuildExe = Locate-MSBuild-Version("$previousPenuntimateVersionMajor.0")
    if ($msbuildExe -and (Test-Path $msbuildExe)) {
        $_ = WriteMessage "Found `"$msbuildExe`""
        return $msbuildExe
    }

    WriteErrorMessage "Can't find msbuild.exe."
    return "" # return empty string
}
