[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Compiler,
    [ValidateSet('x86', 'x64', 'arm64')]
    [Parameter(Mandatory)][string]$TargetArchitecture
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$compilerPath = (Resolve-Path $Compiler).Path
$runId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ') + "-$PID"
$evidenceDirectory = New-Item -ItemType Directory -Force -Path (
    Join-Path $repositoryRoot "out/test-evidence/cx02/tc-1007/$runId")
$objectPath = Join-Path $evidenceDirectory 'debug-types.o'
$logPath = Join-Path $evidenceDirectory 'compile.log'
$metadata = [ordered]@{
    test_id = 'TCC-CX-TC-1007'
    requirement_ids = @('TCC-CX-REQ-1007')
    started_utc = (Get-Date).ToUniversalTime().ToString('o')
    compiler = $compilerPath
    target_architecture = $TargetArchitecture
    verdict = 'Fail'
}

function Find-ByteSequence {
    param([byte[]]$Bytes, [byte[]]$Sequence)
    for ($offset = 0; $offset -le $Bytes.Length - $Sequence.Length;
         ++$offset) {
        $matches = $true
        for ($index = 0; $index -lt $Sequence.Length; ++$index) {
            if ($Bytes[$offset + $index] -ne $Sequence[$index]) {
                $matches = $false
                break
            }
        }
        if ($matches) { return $offset }
    }
    return -1
}

try {
    $source = Join-Path $PSScriptRoot 'tc-1007-debug-types.c'
    $arguments = @('-gdwarf', '-c', $source, '-o', $objectPath)
    $output = & $compilerPath @arguments 2>&1
    $exitCode = $LASTEXITCODE
    @(
        "command=$compilerPath $($arguments -join ' ')"
        "exit_code=$exitCode"
        $output
    ) | Set-Content -LiteralPath $logPath
    if ($exitCode -ne 0) { throw "DWARF compile failed: $logPath" }

    $bytes = [IO.File]::ReadAllBytes($objectPath)
    $text = [Text.Encoding]::ASCII.GetString($bytes)
    foreach ($name in @(
        'float _Complex'
        'double _Complex'
        'long double _Complex'
    )) {
        if (-not $text.Contains($name)) {
            throw "Missing DWARF complex type name: $name"
        }
    }
    if ((Find-ByteSequence $bytes ([byte[]](2, 8, 3))) -lt 0) {
        throw 'Missing 8-byte DW_ATE_complex_float base type.'
    }
    if ((Find-ByteSequence $bytes ([byte[]](2, 16, 3))) -lt 0) {
        throw 'Missing 16-byte DW_ATE_complex_float base type.'
    }

    $metadata.object_sha256 = (Get-FileHash $objectPath).Hash
    $metadata.verdict = 'Pass'
    Write-Output "TCC-CX-TC-1007: Pass ($evidenceDirectory)"
}
finally {
    $metadata.completed_utc = (Get-Date).ToUniversalTime().ToString('o')
    $metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (
        Join-Path $evidenceDirectory 'metadata.json')
}
