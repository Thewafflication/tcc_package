[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Compiler,

    [ValidateSet('Native', 'CompileOnly')]
    [string]$ExecutionMode = 'Native',

    [string]$EvidenceRoot = 'out/test-evidence/cx01/tc-0003'
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
    test_id = 'TCC-CX-TC-0003'
    requirement_ids = @('TCC-CX-REQ-0004')
    started_utc = (Get-Date).ToUniversalTime().ToString('o')
    compiler = $compilerPath
    execution_mode = $ExecutionMode
    verdict = 'Fail'
}

try {
    $source = Join-Path $PSScriptRoot 'tc-0003-conversions.c'
    if ($ExecutionMode -eq 'Native') {
        $positive = Invoke-Compiler -Name 'conversions' -Arguments @(
            '-run'
            $source
        )
    } else {
        $positive = Invoke-Compiler -Name 'conversions' -Arguments @(
            '-c'
            $source
            '-o'
            (Join-Path $evidenceDirectory 'tc-0003-conversions.o')
        )
    }
    if ($positive.ExitCode -ne 0) {
        throw "Complex conversion test failed: $($positive.LogPath)"
    }

    $invalid = Invoke-Compiler -Name 'invalid-pointer' -Arguments @(
        '-fsyntax-only'
        (Join-Path $PSScriptRoot 'tc-0003-invalid-pointer.c')
    )
    if ($invalid.ExitCode -eq 0) {
        throw 'Pointer-to-complex conversion was accepted.'
    }
    if ($invalid.Output -notmatch 'cannot convert') {
        throw 'Pointer-to-complex conversion had an unexpected diagnostic.'
    }

    $metadata.verdict = 'Pass'
    Write-Output "TCC-CX-TC-0003: Pass ($evidenceDirectory)"
}
finally {
    $metadata.completed_utc = (Get-Date).ToUniversalTime().ToString('o')
    $metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (
        Join-Path $evidenceDirectory 'metadata.json')
}
