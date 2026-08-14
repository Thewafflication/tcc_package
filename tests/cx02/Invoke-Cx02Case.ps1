[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Compiler,
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$TestId,
    [Parameter(Mandatory)][string[]]$RequirementIds,
    [ValidateSet('Native', 'CompileOnly')]
    [string]$ExecutionMode = 'Native',
    [string]$EvidenceRoot = 'out/test-evidence/cx02'
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
    Join-Path (Join-Path $EvidenceRoot $TestId.ToLowerInvariant()) $runId)
$sourcePath = Join-Path $PSScriptRoot $Source
$logPath = Join-Path $evidenceDirectory 'execution.log'
$metadata = [ordered]@{
    test_id = "TCC-CX-$TestId"
    requirement_ids = $RequirementIds
    started_utc = (Get-Date).ToUniversalTime().ToString('o')
    compiler = $compilerPath
    compiler_sha256 = (Get-FileHash -LiteralPath $compilerPath).Hash
    source = $sourcePath
    execution_mode = $ExecutionMode
    host_architecture = (
        [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    )
    verdict = 'Fail'
}

try {
    if ($ExecutionMode -eq 'Native') {
        $arguments = @('-std=c11', '-run', $sourcePath)
    } else {
        $arguments = @(
            '-std=c11'
            $sourcePath
            '-o'
            (Join-Path $evidenceDirectory 'case.exe')
        )
    }
    $output = & $compilerPath @arguments 2>&1
    $exitCode = $LASTEXITCODE
    @(
        "command=$compilerPath $($arguments -join ' ')"
        "exit_code=$exitCode"
        $output
    ) | Set-Content -LiteralPath $logPath
    if ($exitCode -ne 0) {
        throw "$TestId failed: $logPath"
    }
    $metadata.verdict = 'Pass'
    Write-Output "TCC-CX-$TestId`: Pass ($evidenceDirectory)"
}
finally {
    $metadata.completed_utc = (Get-Date).ToUniversalTime().ToString('o')
    $metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (
        Join-Path $evidenceDirectory 'metadata.json')
}
