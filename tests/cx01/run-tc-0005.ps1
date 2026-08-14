[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Compiler,

    [Parameter(Mandatory)]
    [ValidateSet('x86', 'x64', 'arm64')]
    [string]$TargetArchitecture,

    [ValidateSet('Native', 'CompileOnly')]
    [string]$ExecutionMode = 'Native',

    [string]$EvidenceRoot = 'out/test-evidence/cx01/tc-0005'
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

$llvmBin = Join-Path ${env:ProgramFiles} (
    'Microsoft Visual Studio\2022\Community\VC\Tools\Llvm\x64\bin')
$clang = Join-Path $llvmBin 'clang.exe'
$llvmLib = Join-Path $llvmBin 'llvm-lib.exe'
$llvmObjdump = Join-Path $llvmBin 'llvm-objdump.exe'
foreach ($tool in @($clang, $llvmLib, $llvmObjdump)) {
    if (-not (Test-Path -LiteralPath $tool)) {
        throw "Required LLVM tool was not found: $tool"
    }
}

function Invoke-LoggedTool {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Tool,
        [string[]]$Arguments = @(),
        [switch]$AllowFailure
    )

    $logPath = Join-Path $evidenceDirectory "$Name.log"
    $output = & $Tool @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    @(
        "command=$Tool $($Arguments -join ' ')"
        "exit_code=$exitCode"
        $output
    ) | Set-Content -LiteralPath $logPath
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "Command failed: $logPath"
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = ($output | Out-String)
        LogPath = $logPath
    }
}

function Assert-FunctionRegisters {
    param(
        [Parameter(Mandatory)][string]$Disassembly,
        [Parameter(Mandatory)][string]$Function,
        [Parameter(Mandatory)][string]$RegisterPrefix
    )

    $pattern = "(?ms)<$Function>:.*?(?=^[0-9a-f]+\s+<|\z)"
    $match = [regex]::Match($Disassembly, $pattern)
    if (-not $match.Success) {
        throw "Function was not found in ARM64 disassembly: $Function"
    }
    foreach ($number in 0, 1) {
        if ($match.Value -notmatch "\b$RegisterPrefix$number\b") {
            throw "$Function did not use $RegisterPrefix$number as required."
        }
    }
}

$targetTriple = @{
    x86 = 'i686-pc-windows-msvc'
    x64 = 'x86_64-pc-windows-msvc'
    arm64 = 'aarch64-pc-windows-msvc'
}[$TargetArchitecture]
$machine = @{ x86 = 'x86'; x64 = 'x64'; arm64 = 'arm64' }[
    $TargetArchitecture]
$nativeSource = Join-Path $PSScriptRoot 'tc-0005-abi-native.c'
$providerSource = Join-Path $PSScriptRoot 'tc-0005-abi-provider.c'
$consumerSource = Join-Path $PSScriptRoot 'tc-0005-abi-consumer.c'

$metadata = [ordered]@{
    test_id = 'TCC-CX-TC-0005'
    requirement_ids = @('TCC-CX-REQ-0007')
    started_utc = (Get-Date).ToUniversalTime().ToString('o')
    compiler = $compilerPath
    reference_compiler = $clang
    target_architecture = $TargetArchitecture
    execution_mode = $ExecutionMode
    verdict = 'Fail'
}

try {
    if ($ExecutionMode -eq 'Native') {
        Invoke-LoggedTool -Name 'native-abi' -Tool $compilerPath -Arguments @(
            '-run', $nativeSource)
    } else {
        Invoke-LoggedTool -Name 'native-abi-compile' -Tool $compilerPath `
            -Arguments @('-c', $nativeSource, '-o', (
                Join-Path $evidenceDirectory 'native-tcc.o'))
    }

    $tccProvider = Join-Path $evidenceDirectory 'provider-tcc.o'
    $tccConsumer = Join-Path $evidenceDirectory 'consumer-tcc.o'
    $clangProvider = Join-Path $evidenceDirectory 'provider-clang.obj'
    $clangConsumer = Join-Path $evidenceDirectory 'consumer-clang.obj'
    Invoke-LoggedTool -Name 'tcc-provider-object' -Tool $compilerPath `
        -Arguments @('-c', $providerSource, '-o', $tccProvider)
    Invoke-LoggedTool -Name 'tcc-consumer-object' -Tool $compilerPath `
        -Arguments @('-c', $consumerSource, '-o', $tccConsumer)
    Invoke-LoggedTool -Name 'clang-provider-object' -Tool $clang -Arguments @(
        '-target', $targetTriple, '-O0', '-fno-addrsig', '-c',
        $providerSource, '-o', $clangProvider)
    Invoke-LoggedTool -Name 'clang-consumer-object' -Tool $clang -Arguments @(
        '-target', $targetTriple, '-O0', '-fno-addrsig', '-c',
        $consumerSource, '-o', $clangConsumer)

    if ($ExecutionMode -eq 'Native') {
        $clangDll = Join-Path $evidenceDirectory 'provider-clang.dll'
        Invoke-LoggedTool -Name 'clang-provider-dll' -Tool $clang -Arguments @(
            '-target', $targetTriple, '-shared', '-O0', $providerSource,
            '-o', $clangDll)
        $tccCallsClang = Join-Path $evidenceDirectory 'tcc-calls-clang.exe'
        Invoke-LoggedTool -Name 'tcc-calls-clang-link' -Tool $compilerPath `
            -Arguments @($consumerSource, $clangDll, '-o', $tccCallsClang)
        Invoke-LoggedTool -Name 'tcc-calls-clang-run' -Tool $tccCallsClang `
            -Arguments @()

        $tccDll = Join-Path $evidenceDirectory 'provider-tcc.dll'
        $tccDef = Join-Path $evidenceDirectory 'provider-tcc.def'
        $tccLib = Join-Path $evidenceDirectory 'provider-tcc.lib'
        Invoke-LoggedTool -Name 'tcc-provider-dll' -Tool $compilerPath `
            -Arguments @('-shared', $providerSource, '-o', $tccDll)
        Invoke-LoggedTool -Name 'tcc-provider-def' -Tool $compilerPath `
            -Arguments @('-impdef', $tccDll, '-o', $tccDef)
        Invoke-LoggedTool -Name 'tcc-provider-import-library' -Tool $llvmLib `
            -Arguments @('/nologo', "/machine:$machine", "/def:$tccDef",
                         "/out:$tccLib")
        $clangCallsTcc = Join-Path $evidenceDirectory 'clang-calls-tcc.exe'
        Invoke-LoggedTool -Name 'clang-calls-tcc-link' -Tool $clang -Arguments @(
            '-target', $targetTriple, '-O0', $consumerSource, $tccLib,
            '-o', $clangCallsTcc)
        Invoke-LoggedTool -Name 'clang-calls-tcc-run' -Tool $clangCallsTcc `
            -Arguments @()
    } else {
        $tccDump = Invoke-LoggedTool -Name 'tcc-provider-disassembly' `
            -Tool $llvmObjdump -Arguments @('-d', '--no-show-raw-insn',
                                             $tccProvider)
        $clangDump = Invoke-LoggedTool -Name 'clang-provider-disassembly' `
            -Tool $llvmObjdump -Arguments @('-d', '--no-show-raw-insn',
                                             $clangProvider)
        foreach ($dump in $tccDump.Output, $clangDump.Output) {
            Assert-FunctionRegisters -Disassembly $dump `
                -Function 'cx_float_identity' -RegisterPrefix 's'
            Assert-FunctionRegisters -Disassembly $dump `
                -Function 'cx_double_identity' -RegisterPrefix 'd'
            Assert-FunctionRegisters -Disassembly $dump `
                -Function 'cx_long_double_identity' -RegisterPrefix 'd'
        }
    }

    $metadata.verdict = 'Pass'
    Write-Output "TCC-CX-TC-0005: Pass ($evidenceDirectory)"
}
finally {
    $metadata.completed_utc = (Get-Date).ToUniversalTime().ToString('o')
    $metadata | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (
        Join-Path $evidenceDirectory 'metadata.json')
}
