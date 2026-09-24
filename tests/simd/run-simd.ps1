[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Compiler,
    [Parameter(Mandatory)][ValidateSet('x86', 'x64')][string]$TargetArchitecture,
    [string]$EvidenceRoot = 'out/test-evidence/simd'
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$compilerPath = (Resolve-Path $Compiler).Path
$include = Join-Path (Split-Path $compilerPath) 'include'
$headerText = ('mmintrin.h','xmmintrin.h','emmintrin.h','mm_malloc.h' | ForEach-Object {
    Get-Content (Join-Path $include $_) -Raw
}) -join "`n"
$manifest = Get-Content "$PSScriptRoot/header-interfaces.json" -Raw | ConvertFrom-Json
foreach ($header in $manifest.headers.PSObject.Properties) {
    foreach ($name in $header.Value) {
        if ($headerText -notmatch ('\b' + [regex]::Escape($name) + '\b')) {
            throw "Missing public intrinsic interface: $name"
        }
    }
}
$root = (Resolve-Path "$PSScriptRoot/../..").Path
if (-not [IO.Path]::IsPathRooted($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $root $EvidenceRoot
}
$work = (New-Item -ItemType Directory -Force -Path (Join-Path $EvidenceRoot (
    $TargetArchitecture + '-' + (Get-Date -Format 'yyyyMMddTHHmmssfff') + "-$PID"))).FullName
$fixtures = Get-Content "$PSScriptRoot/encodings.json" -Raw | ConvertFrom-Json
$cases = if ($TargetArchitecture -eq 'x86') { $fixtures.x32 } else { $fixtures.x64 }
$source = [Collections.Generic.List[string]]::new()
$source.Add('#include <stdio.h>')
$source.Add('#include <string.h>')
for ($i = 0; $i -lt $cases.Count; ++$i) {
    $source.Add(('extern const unsigned char c{0}[] __asm__("simd_case_{0}");' -f $i))
    $source.Add(('extern const unsigned char e{0}[] __asm__("simd_end_{0}");' -f $i))
    $source.Add(('__asm__(".text\n.globl simd_case_{0}\nsimd_case_{0}:\n{1}\n.globl simd_end_{0}\nsimd_end_{0}:\n");' -f $i, $cases[$i].asm))
}
$source.Add('int main(void) { int failures = 0;')
for ($i = 0; $i -lt $cases.Count; ++$i) {
    $bytes = $cases[$i].hex -replace '(..)', '\x$1'
    $length = $cases[$i].hex.Length / 2
    $source.Add(('if (e{0} - c{0} != {2} || memcmp(c{0}, "{1}", {2})) {{ puts("FAIL: {3}"); ++failures; }}' -f $i, $bytes, $length, $cases[$i].asm))
}
$source.Add(('printf("Encoding checks: {0}, failures: %d\n", failures); return failures != 0; }}' -f $cases.Count))
$casePath = Join-Path $work 'encodings.c'
$source | Set-Content -LiteralPath $casePath
function Invoke-Checked([string[]]$Arguments, [string]$LogName) {
    $output = & $compilerPath @Arguments 2>&1
    $result = $LASTEXITCODE
    $output | Set-Content -LiteralPath (Join-Path $work $LogName)
    if ($result -ne 0) { throw "Compiler failed ($result): $output ($work/$LogName)" }
}
$exe = Join-Path $work 'encodings.exe'
Invoke-Checked @($casePath, '-o', $exe) 'encodings-build.log'
& $exe | Tee-Object -FilePath (Join-Path $work 'encodings-run.log')
if ($LASTEXITCODE -ne 0) { throw "SIMD encoding mismatch: $work" }

# Invalid register banks, widths, memory-only forms and immediate ranges.
$invalid = @(
    'movups %eax, %xmm0', 'movaps %xmm0, %eax',
    'movhps %xmm1, %xmm0', 'movlpd %xmm1, %xmm0',
    'paddb %mm1, %xmm0', 'paddb %xmm1, %mm0',
    'pavgb %mm1, %xmm0', 'psllw %xmm1, %mm0',
    'movnti %ax, (%eax)', 'movnti %al, (%eax)',
    'pshufd $256, %xmm1, %xmm0', 'pslldq $256, %xmm0',
    'addpd %mm0, %mm1', 'movntpd %xmm0, %xmm1',
    'addps %xmm16, %xmm0', 'addps %xmm08, %xmm0'
)
if ($TargetArchitecture -eq 'x86') { $invalid += 'addps %xmm8, %xmm0' }
for ($i = 0; $i -lt $invalid.Count; ++$i) {
    $path = Join-Path $work "invalid-$i.c"
    ('__asm__("' + $invalid[$i] + '");') | Set-Content -LiteralPath $path
    $output = & $compilerPath -c $path -o (Join-Path $work "invalid-$i.o") 2>&1
    $result = $LASTEXITCODE
    $output | Set-Content -LiteralPath (Join-Path $work "invalid-$i.log")
    if ($result -eq 0) { throw "Accepted invalid SIMD instruction: $($invalid[$i])" }
}
Write-Output "Rejected $($invalid.Count) invalid instructions."
$exe = Join-Path $work 'runtime.exe'
Invoke-Checked @("$PSScriptRoot/runtime.c", "$PSScriptRoot/runtime.S", '-o', $exe) 'runtime-build.log'
& $exe | Tee-Object -FilePath (Join-Path $work 'runtime-run.log')
if ($LASTEXITCODE -ne 0) { throw "SIMD execution failed: $work" }
$exe = Join-Path $work 'intrinsics.exe'
Invoke-Checked @("$PSScriptRoot/intrinsics.c", "$PSScriptRoot/preserve.S", '-o', $exe) 'intrinsics-build.log'
& $exe | Tee-Object -FilePath (Join-Path $work 'intrinsics-run.log')
if ($LASTEXITCODE -ne 0) { throw "SIMD C intrinsics failed: $work" }
$exe = Join-Path $work 'headers.exe'
Invoke-Checked @('-c', "$PSScriptRoot/header-interfaces.c", '-o', (Join-Path $work 'interfaces.o')) 'interfaces-build.log'
Invoke-Checked @("$PSScriptRoot/headers.c", '-bt', '-o', $exe) 'headers-build.log'
& $exe | Tee-Object -FilePath (Join-Path $work 'headers-run.log')
if ($LASTEXITCODE -ne 0) { throw "SIMD header execution failed: $work" }
foreach ($case in @('callsite', 'slide-hash')) {
    $exe = Join-Path $work "$case.exe"
    Invoke-Checked @("$PSScriptRoot/$case.c", '-o', $exe) "$case-build.log"
    & $exe | Tee-Object -FilePath (Join-Path $work "$case-run.log")
    if ($LASTEXITCODE -ne 0) { throw "SIMD $case correctness failed: $work" }
}
# Timings from slide-hash are informational, never pass/fail thresholds.
$invalidC = @(
    '__m128i f(__m128 a) { return _mm_subs_epu16(a,a); }',
    'void f(const __m128i *p, __m128i a) { _mm_store_si128(p,a); }',
    '__m128 f(__m128 a, int n) { return _mm_shuffle_ps(a,a,n); }',
    '__m128i f(__m128i a) { return _mm_slli_si128(a,256); }',
    '__m128 f(__m128i a) { return a; }',
    'int f(__m128i a) { return _mm_extract_epi16(a,8); }',
    'int f(__m64 a) { return _mm_extract_pi16(a,4); }',
    'void f(char *p) { _mm_prefetch(p,4); }',
    '__m128 f(__m128 a) { return _mm_cmp_ps(a,a,8); }',
    'void f(void) { __builtin_tcc_simd(99999,0,0,0,0); }',
    'void f(void) { __builtin_tcc_simd(0,123,0,0,0); }',
    'void f(const __m128 *p) { __builtin_tcc_simd(0,p,p,p,0); }',
    'void f(void) { __asm__("" ::: "xmm16"); }'
)
if ($TargetArchitecture -eq 'x86') {
    $invalidC += 'void g(int,...); void f(__m128 a) { g(1,a); }'
}
for ($i = 0; $i -lt $invalidC.Count; ++$i) {
    $path = Join-Path $work "invalid-c-$i.c"
    @('#include <emmintrin.h>', $invalidC[$i]) | Set-Content -LiteralPath $path
    $output = & $compilerPath -Werror -c $path -o (Join-Path $work "invalid-c-$i.o") 2>&1
    $result = $LASTEXITCODE
    $output | Set-Content -LiteralPath (Join-Path $work "invalid-c-$i.log")
    if ($result -eq 0) { throw "Accepted invalid SIMD C: $($invalidC[$i])" }
}
Write-Output "Rejected $($invalidC.Count) invalid SIMD C cases."
Write-Output "SIMD $TargetArchitecture passed. Evidence: $work"
