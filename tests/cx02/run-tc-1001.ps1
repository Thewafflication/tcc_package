param(
    [Parameter(Mandatory)][string]$Compiler,
    [ValidateSet('Native', 'CompileOnly')][string]$ExecutionMode = 'Native'
)
& "$PSScriptRoot\Invoke-Cx02Case.ps1" -Compiler $Compiler `
    -Source 'tc-1001-hosted-header.c' -TestId 'TC-1001' `
    -RequirementIds @('TCC-CX-REQ-1001') -ExecutionMode $ExecutionMode
if (-not $?) { exit 1 }
