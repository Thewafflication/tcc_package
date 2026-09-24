"""Regenerate checked-in encoding fixtures with GNU binutils (Linux/WSL).

Run from any directory: python3 tests/simd/generate-fixtures.py
Normal tests use the JSON fixture and do not require Python or binutils.
"""
import json
from pathlib import Path
import subprocess
import tempfile


def instructions(bits):
    base = '%rax' if bits == 64 else '%eax'
    mem = '16(' + base + ')'
    forms = [('%xmm2', '%xmm1'), (mem, '%xmm1')]
    if bits == 64:
        forms += [('%xmm10', '%xmm9'), ('32(%r12,%r13,4)', '%xmm15')]
    binary = []
    for suffix in ('ps', 'ss', 'pd', 'sd'):
        binary += [stem + suffix for stem in ('add', 'mul', 'sub', 'min', 'div', 'max', 'sqrt')]
    for suffix in ('ps', 'pd'):
        binary += [stem + suffix for stem in ('and', 'andn', 'or', 'xor', 'unpckl', 'unpckh')]
    binary += ['rcpps', 'rcpss', 'rsqrtps', 'rsqrtss', 'comiss', 'ucomiss', 'comisd', 'ucomisd']
    binary += ['cvtps2pd', 'cvtpd2ps', 'cvtss2sd', 'cvtsd2ss', 'cvtdq2ps', 'cvtps2dq',
               'cvttps2dq', 'cvtdq2pd', 'cvtpd2dq', 'cvttpd2dq', 'punpcklqdq', 'punpckhqdq']
    result = [f'{op} {src}, {dst}' for op in binary for src, dst in forms]
    for suffix in ('ps', 'ss', 'pd', 'sd'):
        for pred in ('eq', 'lt', 'le', 'unord', 'neq', 'nlt', 'nle', 'ord'):
            result += [f'cmp{pred}{suffix} {src}, {dst}' for src, dst in forms]
    result += ['maskmovq %mm2, %mm1', 'maskmovdqu %xmm2, %xmm1']
    if bits == 64:
        result += ['maskmovdqu %xmm10, %xmm9']
    for op in ('movups', 'movaps', 'movss', 'movupd', 'movapd', 'movsd', 'movdqu', 'movdqa'):
        result += [f'{op} {src}, {dst}' for src, dst in forms]
        result += [f'{op} %xmm3, {mem}']
        if bits == 64:
            result += [f'{op} %xmm15, 32(%r12,%r13,4)']
    for op in ('movlps', 'movhps', 'movlpd', 'movhpd'):
        result += [f'{op} {mem}, %xmm1', f'{op} %xmm1, {mem}']
    result += ['movhlps %xmm2, %xmm1', 'movlhps %xmm2, %xmm1']
    for op in ('cmpps', 'cmpss', 'cmppd', 'cmpsd', 'shufps', 'shufpd', 'pshufd', 'pshuflw', 'pshufhw'):
        result += [f'{op} $3, {src}, {dst}' for src, dst in forms]
    for suffix in ('ss', 'sd'):
        result += [f'cvtsi2{suffix} %ecx, %xmm2', f'cvtsi2{suffix}l {mem}, %xmm2']
        for stem in ('cvt', 'cvtt'):
            result += [f'{stem}{suffix}2si %xmm2, %ecx', f'{stem}{suffix}2sil {mem}, %ecx']
        if bits == 64:
            result += [f'cvtsi2{suffix} %r9, %xmm10', f'cvtsi2{suffix}q {mem}, %xmm10']
            for stem in ('cvt', 'cvtt'):
                result += [f'{stem}{suffix}2si %xmm10, %r9', f'{stem}{suffix}2siq {mem}, %r9']
    integer = ['pavgb', 'pavgw', 'pmaxsw', 'pmaxub', 'pminsw', 'pminub', 'pmulhuw', 'psadbw',
               'paddq', 'psubq', 'pmuludq', 'paddb', 'paddw', 'paddd', 'pxor', 'pand', 'packsswb']
    for bank in ('mm', 'xmm'):
        for op in integer:
            result += [f'{op} %{bank}2, %{bank}1', f'{op} {mem}, %{bank}1']
        for op in ('psllw', 'pslld', 'psllq', 'psraw', 'psrad', 'psrlw', 'psrld', 'psrlq'):
            result += [f'{op} $3, %{bank}1', f'{op} %{bank}2, %{bank}1', f'{op} {mem}, %{bank}1']
        result += [f'pinsrw $3, %ecx, %{bank}1', f'pinsrw $3, {mem}, %{bank}1',
                   f'pextrw $3, %{bank}2, %ecx', f'pmovmskb %{bank}2, %ecx',
                   f'movd %ecx, %{bank}1', f'movd %{bank}1, %ecx']
    for op in ('psrldq', 'pslldq'):
        result += [f'{op} $3, %xmm1']
        if bits == 64: result += [f'{op} $255, %xmm15']
    result += ['pshufw $27, %mm2, %mm1', f'pshufw $27, {mem}, %mm1']
    for suffix in ('ps', 'pd'):
        result += [f'cvtpi2{suffix} %mm2, %xmm1', f'cvtpi2{suffix} {mem}, %xmm1']
        for stem in ('cvt', 'cvtt'):
            result += [f'{stem}{suffix}2pi %xmm2, %mm1', f'{stem}{suffix}2pi {mem}, %mm1']
        result += [f'movmsk{suffix} %xmm2, %ecx']
    result += ['movq2dq %mm2, %xmm1', 'movdq2q %xmm2, %mm1']
    for op in ('movntps', 'movntpd', 'movntdq'):
        result += [f'{op} %xmm1, {mem}']
    result += [f'movntq %mm1, {mem}', f'movnti %ecx, {mem}', f'movntil %ecx, {mem}']
    if bits == 64:
        result += [f'movnti %r9, {mem}', f'movntiq %r9, {mem}',
                   'movmskpd %xmm15, %r9d', 'pextrw $7, %xmm15, %r9d',
                   'pinsrw $7, %r9d, %xmm15', 'pmovmskb %xmm15, %r9d',
                   'movd %r9d, %xmm15', 'movd %xmm15, %r9d',
                   'movq %r9, %xmm15', 'movq %xmm15, %r9']
    result += [f'{op} {mem}' for op in ('ldmxcsr', 'stmxcsr', 'prefetchnta', 'prefetcht0',
                                       'prefetcht1', 'prefetcht2', 'clflush')]
    result += ['lfence', 'mfence', 'sfence']
    return result


def main():
    fixtures = {'reference': subprocess.check_output(['as', '--version'], text=True).splitlines()[0]}
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp)
        for bits in (32, 64):
            cases = instructions(bits)
            source = '.text\n' + ''.join(f'case_{i}:\n {s}\n' for i, s in enumerate(cases)) + f'case_{len(cases)}:\n'
            (path / 'cases.s').write_text(source)
            subprocess.run(['as', f'--{bits}', '-o', str(path / 'cases.o'), str(path / 'cases.s')], check=True)
            subprocess.run(['objcopy', '-O', 'binary', '-j', '.text', str(path / 'cases.o'), str(path / 'cases.bin')], check=True)
            symbols = subprocess.check_output(['nm', str(path / 'cases.o')], text=True)
            offsets = {int(line.split()[2][5:]): int(line.split()[0], 16) for line in symbols.splitlines()}
            data = (path / 'cases.bin').read_bytes()
            fixtures[f'x{bits}'] = [{'asm': s, 'hex': data[offsets[i]:offsets[i+1]].hex()} for i, s in enumerate(cases)]
    Path(__file__).with_name('encodings.json').write_text(json.dumps(fixtures, indent=2) + '\n')
    print('Generated', len(fixtures['x32']), 'x86 and', len(fixtures['x64']), 'x64 cases')


if __name__ == '__main__':
    main()
