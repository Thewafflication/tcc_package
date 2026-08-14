param(
    [Parameter(Mandatory)][string]$Compiler,
    [ValidateSet('Native', 'CompileOnly')][string]$ExecutionMode = 'Native'
)
& "$PSScriptRoot\Invoke-Cx02Case.ps1" -Compiler $Compiler `
    -Source 'tc-1006-tgmath.c' -TestId 'TC-1006' `
    -RequirementIds @('TCC-CX-REQ-1006') -ExecutionMode $ExecutionMode
if (-not $?) { exit 1 }
