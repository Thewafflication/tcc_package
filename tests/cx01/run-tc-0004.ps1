[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Compiler,

    [ValidateSet('Native', 'CompileOnly')]
    [string]$ExecutionMode = 'Native',

    [string]$EvidenceRoot = 'out/test-evidence/cx01/tc-0004'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$compilerPath = (Resolve-Path $Compiler).Path
if (-not [IO.Path]::IsPathRooted($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $repositoryRoot $EvidenceRoot
}
$runId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ') + "-$PID"
$evidenceDirectory = New-Item -ItemType Directory -Force -Path (
    Join-Path $EvidenceRoot $runId)

function Invoke-Compiler {
    param([string]$Name, [string[]]$Arguments)

    $logPath = Join-Path $evidenceDirectory "$Name.log"
    $output = & $compilerPath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    @(
        "command=$compilerPath $($Arguments -join ' ')"
        "exit_code=$exitCode"
        $output
    ) | Set-Content -LiteralPath $logPath
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = ($output | Out-String)
        LogPath = $logPath
    }
}

$metadata = [ordered]@{
    test_id = 'TCC-CX-TC-0004'
    requirement_ids = @('TCC-CX-REQ-0005')
    started_utc = (Get-Date).ToUniversalTime().ToString('o')
    compiler = $compilerPath
    execution_mode = $ExecutionMode
    verdict = 'Fail'
}

try {
    $source = Join-Path $PSScriptRoot 'tc-0004-operators.c'
    if ($ExecutionMode -eq 'Native') {
        $positive = Invoke-Compiler -Name 'operators' -Arguments @(
            '-run'
            $source
        )
    } else {
        $positive = Invoke-Compiler -Name 'operators' -Arguments @(
            '-c'
            $source
            '-o'
            (Join-Path $evidenceDirectory 'tc-0004-operators.o')
        )
    }
    if ($positive.ExitCode -ne 0) {
        throw "Complex operator test failed: $($positive.LogPath)"
    }

    foreach ($fileName in @(
        'tc-0004-invalid-relational.c'
        'tc-0004-invalid-modulo.c'
        'tc-0004-invalid-bitwise.c'
        'tc-0004-invalid-shift.c'
        'tc-0004-invalid-complement.c'
        'tc-0004-invalid-increment.c'
    )) {
        $name = [IO.Path]::GetFileNameWithoutExtension($fileName)
        $invalid = Invoke-Compiler -Name $name -Arguments @(
            '-fsyntax-only'
            (Join-Path $PSScriptRoot $fileName)
        )
        if ($invalid.ExitCode -eq 0) {
            throw "Invalid complex operator was accepted: $fileName"
        }
        if ($invalid.Output -notmatch 'invalid operand types') {
            throw "Invalid complex operator had an unexpected diagnostic."
        }
    }

    $metadata.verdict = 'Pass'
    Write-Output "TCC-CX-TC-0004: Pass ($evidenceDirectory)"
}
finally {
    $metadata.completed_utc = (Get-Date).ToUniversalTime().ToString('o')
    $metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (
        Join-Path $evidenceDirectory 'metadata.json')
}
