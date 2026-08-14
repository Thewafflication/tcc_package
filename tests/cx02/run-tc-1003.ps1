param(
    [Parameter(Mandatory)][string]$Compiler,
    [ValidateSet('Native', 'CompileOnly')][string]$ExecutionMode = 'Native'
)
& "$PSScriptRoot\Invoke-Cx02Case.ps1" -Compiler $Compiler `
    -Source 'tc-1003-elementary-functions.c' -TestId 'TC-1003' `
    -RequirementIds @('TCC-CX-REQ-1003') -ExecutionMode $ExecutionMode
if (-not $?) { exit 1 }
