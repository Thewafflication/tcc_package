[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Compiler,

    [Parameter(Mandatory)]
    [ValidateSet('x86', 'x64', 'arm64')]
    [string]$TargetArchitecture,

    [ValidateSet('Native', 'CompileOnly')]
    [string]$ExecutionMode = 'Native',

    [string]$EvidenceRoot = 'out/test-evidence/cx01/tc-0007'
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
$packageDirectory = Split-Path -Parent $compilerPath

function Invoke-Compiler {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$Arguments
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
    test_id = 'TCC-CX-TC-0007'
    requirement_ids = @('TCC-CX-REQ-0009')
    started_utc = (Get-Date).ToUniversalTime().ToString('o')
    compiler = $compilerPath
    target_architecture = $TargetArchitecture
    execution_mode = $ExecutionMode
    upstream_linux_suite = 'Recorded by run-tc-0007-linux.sh'
    verdict = 'Fail'
}

try {
    foreach ($relativePath in @(
        'tcc.exe'
        'include\tccdefs.h'
        'lib\libtcc1.a'
    )) {
        $path = Join-Path $packageDirectory $relativePath
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required package file is missing: $path"
        }
    }

    $architectureDefine = @{
        x86 = '-DCX_EXPECT_X86'
        x64 = '-DCX_EXPECT_X64'
        arm64 = '-DCX_EXPECT_ARM64'
    }[$TargetArchitecture]
    $source = Join-Path $PSScriptRoot 'tc-0007-regression-smoke.c'
    if ($ExecutionMode -eq 'Native') {
        $smoke = Invoke-Compiler -Name 'package-smoke' -Arguments @(
            $architectureDefine, '-run', $source)
    } else {
        $smoke = Invoke-Compiler -Name 'package-smoke' -Arguments @(
            $architectureDefine, '-c', $source, '-o',
            (Join-Path $evidenceDirectory 'package-smoke.o'))
    }
    if ($smoke.ExitCode -ne 0) {
        throw "Package smoke test failed: $($smoke.LogPath)"
    }

    $knownFailure = Invoke-Compiler -Name 'known-failure' -Arguments @(
        '-fsyntax-only'
        (Join-Path $PSScriptRoot 'tc-0007-known-failure.c')
    )
    if ($knownFailure.ExitCode -eq 0) {
        throw 'The controlled failing child was incorrectly reported as Pass.'
    }
    if ($knownFailure.Output -notmatch 'undeclared') {
        throw 'The controlled failing child had an unexpected diagnostic.'
    }

    $metadata.verdict = 'Pass'
    Write-Output "TCC-CX-TC-0007: Pass ($evidenceDirectory)"
}
finally {
    $metadata.completed_utc = (Get-Date).ToUniversalTime().ToString('o')
    $metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (
        Join-Path $evidenceDirectory 'metadata.json')
}
