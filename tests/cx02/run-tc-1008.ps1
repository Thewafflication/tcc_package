[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Compiler,
    [ValidateSet('x86', 'x64', 'arm64')]
    [Parameter(Mandatory)][string]$TargetArchitecture,
    [ValidateSet('Native', 'CompileOnly')]
    [string]$ExecutionMode = 'Native'
)

$ErrorActionPreference = 'Stop'
$compilerPath = (Resolve-Path $Compiler).Path
$packageDirectory = Split-Path -Parent $compilerPath
foreach ($relativePath in @(
    'include\complex.h'
    'include\tgmath.h'
    'lib\libtcc1.a'
)) {
    $path = Join-Path $packageDirectory $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required CX2 package file is missing: $path"
    }
}

& "$PSScriptRoot\Invoke-Cx02Case.ps1" -Compiler $compilerPath `
    -Source 'tc-1008-package.c' -TestId 'TC-1008' `
    -RequirementIds @('TCC-CX-REQ-1008') -ExecutionMode $ExecutionMode
if (-not $?) { exit 1 }
