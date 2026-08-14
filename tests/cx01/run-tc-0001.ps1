[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Compiler,

    [ValidateSet('Native', 'CompileOnly')]
    [string]$ExecutionMode = 'Native',

    [string]$EvidenceRoot = 'out/test-evidence/cx01/tc-0001'
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
    test_id = 'TCC-CX-TC-0001'
    requirement_ids = @(
        'TCC-CX-REQ-0001'
        'TCC-CX-REQ-0002'
        'TCC-CX-REQ-0008'
    )
    started_utc = (Get-Date).ToUniversalTime().ToString('o')
    compiler = $compilerPath
    execution_mode = $ExecutionMode
    host_architecture = (
        [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    )
    process_architecture = (
        [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString()
    )
    verdict = 'Fail'
}

try {
    $positiveSource = Join-Path $PSScriptRoot 'tc-0001-types.c'
    if ($ExecutionMode -eq 'Native') {
        $positive = Invoke-Compiler -Name 'positive' -Arguments @(
            '-run'
            $positiveSource
        )
    } else {
        $objectPath = Join-Path $evidenceDirectory 'tc-0001-types.o'
        $positive = Invoke-Compiler -Name 'positive' -Arguments @(
            '-c'
            $positiveSource
            '-o'
            $objectPath
        )
    }
    if ($positive.ExitCode -ne 0) {
        throw "Positive type and layout test failed: $($positive.LogPath)"
    }

    $negativeCases = @(
        'tc-0001-invalid-bare.c'
        'tc-0001-invalid-long.c'
        'tc-0001-invalid-integer.c'
        'tc-0001-invalid-unsigned.c'
        'tc-0001-invalid-duplicate.c'
    )
    foreach ($fileName in $negativeCases) {
        $name = [IO.Path]::GetFileNameWithoutExtension($fileName)
        $result = Invoke-Compiler -Name $name -Arguments @(
            '-fsyntax-only'
            (Join-Path $PSScriptRoot $fileName)
        )
        if ($result.ExitCode -eq 0) {
            throw "Invalid declaration was accepted: $fileName"
        }
        if ($result.Output -notmatch 'too many basic types') {
            throw (
                "Invalid declaration produced an unexpected diagnostic: " +
                $fileName)
        }
    }

    $spelling = Invoke-Compiler -Name 'type-spelling' -Arguments @(
        '-fsyntax-only'
        (Join-Path $PSScriptRoot 'tc-0001-type-spelling.c')
    )
    if ($spelling.ExitCode -eq 0) {
        throw 'The incompatible complex assignment was accepted.'
    }
    if ($spelling.Output -notmatch 'double _Complex') {
        throw 'The diagnostic did not spell the complex destination type.'
    }

    $metadata.verdict = 'Pass'
    Write-Output "TCC-CX-TC-0001: Pass ($evidenceDirectory)"
}
finally {
    $metadata.completed_utc = (Get-Date).ToUniversalTime().ToString('o')
    $metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (
        Join-Path $evidenceDirectory 'metadata.json')
}
