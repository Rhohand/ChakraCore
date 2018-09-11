#-------------------------------------------------------------------------------------------------------
# Copyright (C) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE.txt file in the project root for full license information.
#-------------------------------------------------------------------------------------------------------

function UseValueOrDefault() {
    foreach ($value in $args) {
        if ($value) {
            return $value
        }
    }
    return ""
}


function RunShCommand() {
    param(
        [Parameter(Mandatory=$true,Position=1)]
        $command
    )
    $shExe = GetShPath

    if([string]::IsNullOrWhiteSpace($shExe)) {
        throw "Sh not found"
    }
    & "$shExe" --login -i -c "$command"
}

function RunShFile() {
    param(
        [Parameter(Mandatory=$true,Position=1)]
        $file,
        [Bool]$convertFromWindowsPath = $true
    )
    $shExe = GetShPath

    $filePath = $file
    if($convertFromWindowsPath) { 
        $filePath = $file.Replace('\', '/')
        if($filePath.Contains(":")) {
            $filePath.Replace(":", "")
        }
        if(!($filePath.StartsWith("/"))) {
            $filePath = "/$filePath"
        }
    }

    if([string]::IsNullOrWhiteSpace($shExe)) {
        throw "Sh not found"
    }
    & "$shExe" --login -i -c "$command"
}

# TODO remove duplication of code
function GetShPath() { 
    $shTemplate = "{0}\{1}\bin\sh.exe"
    
    $product = "git"

    $shExe = "sh.exe"
    if (!(Get-Command $shExe -ErrorAction SilentlyContinue)) {
        $shExe = $shTemplate -f "C:\Program Files", $product
        if (!(Test-Path $shExe  -ErrorAction SilentlyContinue)) {
            $shExe = $shTemplate -f "${Env:ProgramFiles}", $product
            if (!(Test-Path $shExe  -ErrorAction SilentlyContinue)) {
                $shExe = $shTemplate -f "${Env:ProgramFiles(x86)}", $product
                if (!(Test-Path $shExe  -ErrorAction SilentlyContinue)) {

                    throw "sh.exe not found in path -- aborting."
                }
            }
        }
    }

    return $shExe
}

function GetGitPath() {
    $gitTemplate = "{0}\{1}\bin\git.exe"
    
    $product = "git"

    $gitExe = "git.exe"
    if (!(Get-Command $gitExe -ErrorAction SilentlyContinue)) {
        $gitExe = $gitTemplate -f "C:\Program Files", $product
        if (!(Test-Path $gitExe  -ErrorAction SilentlyContinue)) {
            $gitExe = $gitTemplate -f "${Env:ProgramFiles}", $product
            if (!(Test-Path $gitExe  -ErrorAction SilentlyContinue)) {
                $gitExe = $gitTemplate -f "${Env:ProgramFiles(x86)}", $product
                if (!(Test-Path $gitExe  -ErrorAction SilentlyContinue)) {

                    throw "git.exe not found in path -- aborting."
                }
            }
        }
    }

    return $gitExe
}

function GetRepoRoot() {
    $gitExe = GetGitPath
    return Invoke-Expression "$gitExe rev-parse --show-toplevel"
}

function WriteMessage($str) {
    Write-Output $str
    if ($logFile) {
        Write-Output $str | Out-File $logFile -Append
    }
}

function WriteErrorMessage($str) {
    $host.ui.WriteErrorLine($str)
    if ($logFile) {
        Write-Output $str | Out-File $logFile -Append
    }
}

function ExecuteCommand($cmd) {
    if ($cmd -eq "") {
        return
    }
    WriteMessage "-------------------------------------"
    WriteMessage "Running $cmd"
    if ($noaction) {
        return
    }
    Invoke-Expression $cmd
    if ($lastexitcode -ne 0) {
        WriteErrorMessage "ERROR: Command failed: exit code $LastExitCode"
        $global:exitcode = $LastExitCode
    }
    WriteMessage ""
}
