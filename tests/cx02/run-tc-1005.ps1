param(
    [Parameter(Mandatory)][string]$Compiler,
    [ValidateSet('Native', 'CompileOnly')][string]$ExecutionMode = 'Native'
)
& "$PSScriptRoot\Invoke-Cx02Case.ps1" -Compiler $Compiler `
    -Source 'tc-1005-arithmetic-hardening.c' -TestId 'TC-1005' `
    -RequirementIds @('TCC-CX-REQ-1005') -ExecutionMode $ExecutionMode
if (-not $?) { exit 1 }
