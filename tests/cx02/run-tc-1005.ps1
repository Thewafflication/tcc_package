[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Compiler,
    [ValidateSet('Native', 'CompileOnly')][string]$ExecutionMode = 'Native'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$compilerPath = (Resolve-Path $Compiler).Path

function Find-LlvmObjdump {
    $command = Get-Command llvm-objdump.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    foreach ($edition in 'Community', 'Enterprise', 'Professional',
             'BuildTools') {
        $candidate = Join-Path ${env:ProgramFiles} (
            "Microsoft Visual Studio\2022\$edition" +
            '\VC\Tools\Llvm\x64\bin\llvm-objdump.exe')
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }
    throw 'llvm-objdump.exe is required for ARM64 helper ABI inspection.'
}

& "$PSScriptRoot\Invoke-Cx02Case.ps1" -Compiler $compilerPath `
    -Source 'tc-1005-arithmetic-hardening.c' -TestId 'TC-1005' `
    -RequirementIds @('TCC-CX-REQ-1005') -ExecutionMode $ExecutionMode
if (-not $?) { exit 1 }

$target = (& $compilerPath -dumpmachine 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'TinyCC target discovery failed.'
}
if ($target -notmatch '^aarch64') {
    exit 0
}

$temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) (
    'tcc-cx02-tc-1005-' + [guid]::NewGuid().ToString('N'))
$objectPath = Join-Path $temporaryDirectory 'helper-caller.o'
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
try {
    $sourcePath = Join-Path $PSScriptRoot 'tc-1005-arithmetic-hardening.c'
    $compileOutput = & $compilerPath '-std=c11' '-c' $sourcePath `
        '-o' $objectPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "ARM64 helper ABI probe compilation failed: $compileOutput"
    }

    $llvmObjdump = Find-LlvmObjdump
    $dump = & $llvmObjdump '-dr' '--no-show-raw-insn' $objectPath 2>&1 |
        Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "ARM64 helper ABI disassembly failed: $dump"
    }

    $lines = @($dump -split "`r?`n")
    $callCount = 0
    for ($index = 0; $index -lt $lines.Count; ++$index) {
        if ($lines[$index] -notmatch
            'R_AARCH64_CALL26\s+__tcc_(?:mul|div)[dx]c3') {
            continue
        }
        ++$callCount
        $start = [Math]::Max(0, $index - 20)
        $context = $lines[$start..$index] -join "`n"
        if ($context -match '\bfmov\s+x[0-4],\s*d[0-9]+\b') {
            throw 'ARM64 complex helper call used the variadic integer ABI.'
        }
        foreach ($register in 'd0', 'd1', 'd2', 'd3') {
            if ($context -notmatch
                "\b(?:ldr|ldur|fmov|fcvt)\s+$register\b") {
                throw "ARM64 complex helper call did not populate $register."
            }
        }
        if ($context -notmatch '\b(?:add|sub|mov)\s+x0\b') {
            throw 'ARM64 complex helper result pointer was not placed in x0.'
        }
    }
    if ($callCount -lt 4) {
        throw "Expected at least four complex helper calls, found $callCount."
    }
    Write-Output "TCC-CX-TC-1005 ARM64 helper ABI: Pass ($callCount calls)"
}
finally {
    if (Test-Path -LiteralPath $objectPath) {
        Remove-Item -LiteralPath $objectPath -Force
    }
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Force
    }
}
