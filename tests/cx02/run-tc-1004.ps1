param(
    [Parameter(Mandatory)][string]$Compiler,
    [ValidateSet('Native', 'CompileOnly')][string]$ExecutionMode = 'Native'
)
& "$PSScriptRoot\Invoke-Cx02Case.ps1" -Compiler $Compiler `
    -Source 'tc-1004-exceptional-values.c' -TestId 'TC-1004' `
    -RequirementIds @('TCC-CX-REQ-1004') -ExecutionMode $ExecutionMode
if (-not $?) { exit 1 }
