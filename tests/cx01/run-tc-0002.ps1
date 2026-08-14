[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Compiler,

    [ValidateSet('Native', 'CompileOnly')]
    [string]$ExecutionMode = 'Native',

    [string]$EvidenceRoot = 'out/test-evidence/cx01/tc-0002'
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
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

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
    test_id = 'TCC-CX-TC-0002'
    requirement_ids = @('TCC-CX-REQ-0003', 'TCC-CX-REQ-0006')
    started_utc = (Get-Date).ToUniversalTime().ToString('o')
    compiler = $compilerPath
    execution_mode = $ExecutionMode
    verdict = 'Fail'
}

try {
    $positiveSource = Join-Path $PSScriptRoot 'tc-0002-objects.c'
    if ($ExecutionMode -eq 'Native') {
        $positive = Invoke-Compiler -Name 'objects' -Arguments @(
            '-run'
            $positiveSource
        )
    } else {
        $objectPath = Join-Path $evidenceDirectory 'tc-0002-objects.o'
        $positive = Invoke-Compiler -Name 'objects' -Arguments @(
            '-c'
            $positiveSource
            '-o'
            $objectPath
        )
    }
    if ($positive.ExitCode -ne 0) {
        throw "Complex construction test failed: $($positive.LogPath)"
    }

    $negativeCases = @(
        @{
            File = 'tc-0002-invalid-address.c'
            Pattern = 'lvalue'
        }
        @{
            File = 'tc-0002-invalid-builtin-types.c'
            Pattern = '__builtin_complex arguments'
        }
    )
    foreach ($case in $negativeCases) {
        $name = [IO.Path]::GetFileNameWithoutExtension($case.File)
        $result = Invoke-Compiler -Name $name -Arguments @(
            '-fsyntax-only'
            (Join-Path $PSScriptRoot $case.File)
        )
        if ($result.ExitCode -eq 0) {
            throw "Invalid construction was accepted: $($case.File)"
        }
        if ($result.Output -notmatch $case.Pattern) {
            throw "Unexpected diagnostic for $($case.File)"
        }
    }

    $metadata.verdict = 'Pass'
    Write-Output "TCC-CX-TC-0002: Pass ($evidenceDirectory)"
}
finally {
    $metadata.completed_utc = (Get-Date).ToUniversalTime().ToString('o')
    $metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (
        Join-Path $evidenceDirectory 'metadata.json')
}
