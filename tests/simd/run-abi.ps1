[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Compiler,
    [Parameter(Mandatory)][ValidateSet('x86','x64')][string]$TargetArchitecture,
    [string]$EvidenceRoot = 'out/test-evidence/simd-abi'
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$compilerPath = (Resolve-Path $Compiler).Path
$root = (Resolve-Path "$PSScriptRoot/../..").Path
if (-not [IO.Path]::IsPathRooted($EvidenceRoot)) { $EvidenceRoot = Join-Path $root $EvidenceRoot }
$work = (New-Item -ItemType Directory -Force -Path (Join-Path $EvidenceRoot (
    $TargetArchitecture + '-' + (Get-Date -Format 'yyyyMMddTHHmmssfff') + "-$PID"))).FullName
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if ($LASTEXITCODE -ne 0 -or -not $vs) { throw 'MSVC is required for the independent SIMD ABI test.' }
$setup = Join-Path $vs 'Common7/Tools/VsDevCmd.bat'
$peer = Join-Path $work 'peer.dll'
$batch = Join-Path $work 'build-peer.cmd'
@(
    '@echo off'
    ('call "{0}" -no_logo -arch={1} -host_arch=x64' -f $setup,$TargetArchitecture)
    'if errorlevel 1 exit /b 1'
    ('cl /nologo /LD /O2 /arch:SSE2 "{0}" /Fo"{1}" /Fe"{2}" /link /IMPLIB:"{3}"' -f (
        Join-Path $PSScriptRoot 'abi-peer.c'),(Join-Path $work 'peer.obj'),$peer,(Join-Path $work 'peer.lib'))
    'exit /b %errorlevel%'
) | Set-Content -LiteralPath $batch
$output = & cmd.exe /d /c $batch 2>&1
$code = $LASTEXITCODE
$output | Set-Content (Join-Path $work 'peer-build.log')
if ($code -ne 0) { throw "MSVC peer build failed: $output" }
$exe = Join-Path $work 'driver.exe'
$output = & $compilerPath -bt "$PSScriptRoot/abi-driver.c" -o $exe 2>&1
$code = $LASTEXITCODE
$output | Set-Content (Join-Path $work 'driver-build.log')
if ($code -ne 0) { throw "TinyCC ABI driver build failed: $output" }
& $exe $peer | Tee-Object -FilePath (Join-Path $work 'execution.log')
if ($LASTEXITCODE -ne 0) { throw "SIMD ABI test failed: $work" }
Write-Output "MSVC/TinyCC $TargetArchitecture ABI passed: $work"
