param(
    [Parameter(Mandatory)][string]$Compiler,
    [ValidateSet('Native', 'CompileOnly')][string]$ExecutionMode = 'Native'
)
& "$PSScriptRoot\Invoke-Cx02Case.ps1" -Compiler $Compiler `
    -Source 'tc-1002-basic-functions.c' -TestId 'TC-1002' `
    -RequirementIds @('TCC-CX-REQ-1002') -ExecutionMode $ExecutionMode
if (-not $?) { exit 1 }
