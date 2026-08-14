[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Compiler,

    [ValidateSet('Native', 'CompileOnly')]
    [string]$ExecutionMode = 'CompileOnly',

    [string]$EvidenceRoot = 'out/test-evidence/cx01/tc-0006'
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
$fixture = Join-Path $repositoryRoot (
    'tests\fixtures\musl-complex-f21a9653')
$source = Join-Path $PSScriptRoot 'tc-0006-musl-header.c'

$metadata = [ordered]@{
    test_id = 'TCC-CX-TC-0006'
    requirement_ids = @('TCC-CX-REQ-0010')
    fixture_revision = 'f21a96538f78fa8e2040831b4209b35f2fb581da'
    started_utc = (Get-Date).ToUniversalTime().ToString('o')
    compiler = $compilerPath
    execution_mode = $ExecutionMode
    verdict = 'Fail'
}

try {
    $logPath = Join-Path $evidenceDirectory 'musl-header.log'
    if ($ExecutionMode -eq 'Native') {
        $arguments = @('-std=c11', '-I', $fixture, '-run', $source, '-lm')
    } else {
        $arguments = @('-std=c11', '-I', $fixture, '-c', $source, '-o',
                       (Join-Path $evidenceDirectory 'musl-header.o'))
    }
    $output = & $compilerPath @arguments 2>&1
    $exitCode = $LASTEXITCODE
    @(
        "command=$compilerPath $($arguments -join ' ')"
        "exit_code=$exitCode"
        $output
    ) | Set-Content -LiteralPath $logPath
    if ($exitCode -ne 0) {
        throw "musl complex header compatibility failed: $logPath"
    }

    $metadata.verdict = 'Pass'
    Write-Output "TCC-CX-TC-0006: Pass ($evidenceDirectory)"
}
finally {
    $metadata.completed_utc = (Get-Date).ToUniversalTime().ToString('o')
    $metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (
        Join-Path $evidenceDirectory 'metadata.json')
}
