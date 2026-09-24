# SIMD expansion roadmap

Status: proposed plan, 2026-09-24. Implementation has not started.

See [SIMD support](simd-support.md) for implemented capabilities and
[the package README](../README.md) for build and installation instructions.
Milestones below describe future work, not current release guarantees.

Baseline: package `78563a4`, TinyCC `72495402`, release
`0.9.28-rc.1448+72495402`.

## Objective and priorities

Extend TinyCC's explicit SIMD intrinsics and assembler support while preserving
default target compatibility, mixed-compiler interoperability, and useful
performance. Windows x86, x64, and ARM64 are the package targets; Linux provides
additional execution and ABI validation. Automatic loop vectorization is a
separate project.

Recommended sequence:

1. Shared type, feature, lowering, and test foundations.
2. SSE3 and SSSE3.
3. ARM64 Advanced SIMD (NEON), starting with compression kernels.
4. SSE4.1 and SSE4.2, with independently tracked companion extensions.
5. AVX, then AVX2, FMA3, and F16C.
6. Workload-driven ARM64 optional extensions.
7. Separate advanced projects for AVX-512 and SVE/SVE2.

NEON and the later x86 milestones can proceed independently after the shared
foundation is stable. This is a dependency roadmap, not a calendar estimate.

## Current state and constraints

The existing MMX/SSE/SSE2 implementation includes headers, checked builtins,
assembler encodings, vector objects, inline assembly, and x86 ABI coverage.
Issue #4 added call-site expansion for three hot-loop intrinsics and native
128-bit vector copies. Most wrappers still use functions, and intermediates
remain memory-backed.

`VT_SIMD`, `simd_types`, alignment logic, and the new assignment path contain
x86/128-bit assumptions. `x86-simd.c` and `include/tccsimd.h` provide a useful
operation catalogue, but cannot simply be reused unchanged for wider vectors
or ARM. ARM64 already has scalar FP register handling and some Q-register
memory operations; that does not constitute an ACLE vector type/header/ABI
implementation.

The ARM64 package currently runs an x64-hosted cross-compiler. Generating an
ARM64 executable on this host is not evidence that it executes correctly.

## Architecture correspondence

These are functional comparisons, not interchangeable instruction sets.

| x86 work | ARM64 counterpart | Planning consequence |
| --- | --- | --- |
| SSE through SSE4, fixed 128-bit operations | Advanced SIMD / NEON, with 64- and 128-bit vector forms | Implement native `arm_neon.h` interfaces and ARM semantics |
| AVX/AVX2, fixed 256-bit vectors | Multiple NEON vectors, or an SVE algorithm | No universal single-instruction NEON equivalent |
| AVX-512 masks and wider operations | SVE/SVE2 predicates and scalable vectors | Separate type, lowering, and ABI projects |
| AES, carryless multiply, SHA, CRC | ARM crypto, polynomial multiply, SHA, CRC extensions | Track each extension and runtime capability independently |
| Specialized matrix facilities | SME and related matrix extensions | Deferred until a concrete workload justifies them |

NEON uses fixed-width vectors; SVE's scalable/sizeless model is a materially
different compiler feature. See the [Arm architecture comparison][arm-compare]
and [ACLE specification][acle].

## Milestones and exit gates

| ID | Scope and deliverable | Dependency | Exit gate |
| --- | --- | --- | --- |
| SIMD-0 | Feature policy, vector representation ADR, lowering design, coverage manifests, test infrastructure | Released baseline | Existing suites pass; proposed types/features/ABI contracts are reviewable |
| X86-1 | SSE3 and SSSE3 headers, direct lowering, assembler forms, immediate validation | SIMD-0 | Declared header inventory covered; semantic, encoding, ABI, and kernel tests pass |
| ARM-1A | ARM64 64/128-bit integer and FP vector types, copies, calls, loads/stores, saturation; initial NEON kernel slice | SIMD-0 | Hash-slide kernel and mixed-compiler vector calls execute correctly on ARM64 |
| ARM-1B | Remaining declared baseline AArch64 NEON surface, permutations, widening/narrowing, reductions, structured loads/stores, tuple types | ARM-1A | Baseline manifest complete; Windows ARM64 ABI and runtime gates pass |
| X86-2 | SSE4.1 and SSE4.2; separate POPCNT capability | X86-1 | Immediate/string/CRC semantics and independent feature selection verified |
| X86-3 | VEX encoder, AVX 128/256-bit operations, `__m256*` types, YMM ABI and transition handling | SIMD-0, X86-2 | Both x86 targets pass encoding, CPU/OS dispatch, ABI, and runtime gates |
| X86-4 | AVX2 integer operations and gather; separate FMA3 and F16C capabilities | X86-3 | Boundary/masking/rounding cases, independent feature gates, and real kernels pass |
| ARM-2 | Optional CRC, AES/PMULL/SHA, dot product, FP16, BF16 and integer matrix operations selected by workload | ARM-1B | Each selected extension closes its own inventory and runtime/ABI gates |
| X86-5 | AVX-512F first, then explicit subsets such as BW/DQ/VL and workload-driven additions | X86-4 | EVEX, mask registers, ZMM ABI, state detection, and subset-specific tests pass |
| ARM-3 | SVE foundation, then SVE2 and explicit optional subsets | ARM-1B; scalable-vector ADR and supported OS runner | Predication, multiple vector lengths, scalable ABI, and runtime detection verified |

SSE3 and SSSE3 remain separate feature bits even if delivered together. SSE4a
is not SSE4.1/4.2. AES-NI, PCLMULQDQ, SHA, BMI1/BMI2, and POPCNT are not
implicitly enabled by a broad SSE/AVX label. Add x86 crypto and BMI support as
separate companion work where actual consumers need it. FMA4, XOP, AVX10,
AMX, ARM SME, ARM32 NEON, and generic vector-language extensions are deferred.
The authoritative x86 inventories are the [Intel manuals][intel-sdm] and
[Intrinsics Guide][intel-intrinsics].

## SIMD-0 design decisions

### Representation and lowering

Introduce width/element/lane metadata and target-specific ABI classification.
Keep vector identity distinct from ordinary structs and from other vector
types. Audit size, alignment, casts, temporaries, assignment, aggregates,
varargs, debug information, inline assembly, and call lowering. Do not change
the released `__m128*` or `__m64` ABI as an incidental refactor.

Define a typed intrinsic operation schema with operand kinds, result type,
immediate restrictions, required features, and lowering rules. Derive header
coverage manifests and validation data from it where practical. Keep encoding
and ABI logic target-specific rather than forcing unrelated instructions into
one x86-shaped builtin interface.

Use direct call-site lowering for new simple operations. Preserve single
argument evaluation, diagnostics, nesting, and existing addressable intrinsic
function forms. Start with correct memory-backed values, then add bounded
register reuse within expressions/basic blocks where measured kernels need it.
Register reuse requires alias, volatile, spill, call-clobber, and inline-asm
invalidation rules; it is not a prerequisite for publishing SSE3 headers.

### Compile-time features and runtime dispatch

Maintain three distinct concepts: compiler support, permitted code generation,
and runtime CPU/OS availability. Define a feature dependency graph rather than
a single numeric SIMD level.

Proposed policy: retain current SSE/SSE2 behavior for compatibility; make new
extensions explicit through target options and per-function target attributes.
Specify feature predefines and header behavior alongside those options. A
mixed binary must be able to contain a baseline dispatcher and optimized
functions without globally raising its minimum instruction set. Start with
explicit caller dispatch; automatic multiversioning can follow separately.

AVX availability requires CPU feature checks and OS-enabled extended register
state; gate XGETBV itself before reading XCR0. AVX-512 needs additional enabled
state and the actual subset bits. Test synthetic feature combinations so a
modern development CPU cannot hide dispatch bugs. SSE-era i386 OS support
remains part of the runtime contract.

On ARM64 use platform-supported capability queries for optional extensions.
Pin the Windows baseline and the Linux capability mapping in the design.
Do not infer availability solely from a CPU model or `__aarch64__`. Windows
SVE execution is a separate platform-support decision, not implied by NEON
support or by successful cross-compilation.

## Target-specific implementation work

For SSE3/SSSE3, extend the legacy opcode maps and prefix handling, including
the additional maps needed by SSSE3. Add the conventional `pmmintrin.h` and
`tmmintrin.h` surfaces. SSE4 adds `smmintrin.h` and `nmmintrin.h`; audit related
umbrella headers rather than exposing partial support accidentally.

AVX requires two- and three-byte VEX encodings, three-operand forms, upper-lane
semantics, 32-byte types/alignment, register constraints, and ABI decisions for
each Windows/System V target. Design `vzeroupper` placement around live values
and call boundaries; unconditional insertion can destroy a YMM result.
AVX2 and FMA must preserve lane-local behavior, mask semantics, and fused
rounding rather than approximate them with scalar C. AVX-512 adds EVEX, masks,
merge/zero behavior, extra register/state rules, and subset-specific claims.

For NEON, implement ACLE signed/unsigned integer, floating and polynomial
types, vector tuples, lane operations, reinterpretation, and intrinsic names.
Use `arm64-asm.c`, `arm64-gen.c`, and a new ARM intrinsic catalogue. Verify
short-vector arguments/results, homogeneous vector aggregates, register
preservation, stack overflow arguments, callbacks, and variadic boundaries
against the applicable ABI. Windows requirements come from
[Microsoft's ARM64 ABI][windows-arm64]; intrinsic signatures and lane semantics
come from the [Arm Neon reference][neon]. Pin AAPCS64 for Linux separately.

For the first shared kernel, test equivalent scalar, SSE2, and NEON hash
sliding: load eight unsigned 16-bit lanes, saturating-subtract the window size,
and store. Native NEON support comes first; an SSE-to-NEON compatibility header
is optional follow-up work with its own floating-point and exception tests.

SVE needs scalable vector and predicate types, sizeless-type restrictions,
predicated memory/arithmetic, runtime-sized spills, and a scalable calling
convention. Decide these in a separate ADR before attempting `arm_sve.h`.
Use Linux AArch64 as the initial execution platform if a suitable Windows
runtime/ABI is unavailable; label that scope explicitly.

## Validation and release policy

Each milestone uses requirements, a design/ADR where needed, controlled tests,
review findings, and a verification record with exact compiler/submodule
revisions. Completion is measured against a pinned intrinsic inventory, not
the number of header names added.

- Encoding: compare emitted bytes with an independent assembler; cover register
  limits, addressing forms, prefixes, immediates, and rejected forms.
- Semantics: compare scalar oracles and reference compilers; include saturation,
  signedness, lane boundaries, NaNs, signed zero, rounding, aliasing, alignment,
  masks, page boundaries, and argument side effects as applicable.
- ABI: compile callers and callees in both directions with MSVC/Clang on Windows
  and GCC/Clang on Linux; include aggregates, callbacks, register exhaustion,
  preserved registers and supported variadic interfaces.
- Compatibility: rerun existing SIMD, complex-number, assembler, and upstream
  regressions. Inspect baseline dispatch code for accidental advanced opcodes.
- Performance: use hash sliding, Adler/checksum, byte shuffle, dot product, and
  floating kernels selected per milestone. Gate stable code-generation properties
  such as absence of wrapper calls; report timing distributions without universal
  speed thresholds. Retain hardware, flags, inputs and scalar comparisons.
- Integration: pin a real consumer, initially zlib-ng, and exercise the intrinsic
  kernel, byte-for-byte output comparisons where applicable, and round trips.
- Execution: feature-aware tests distinguish pass, skip, and compile-only results.
  Emulation helps functional coverage but is not native performance evidence.
  Require native Windows ARM64 evidence before claiming that runtime supported.

Wire the required CTest gates into CI before publishing each new capability;
the current packaging workflow builds and verifies package signatures but does
not run the SIMD suites. Keep build/signature success separate from execution
success. Record unavailable hardware as a remaining gate, not a passing test.

## First implementation batch

Prepare SIMD-0 requirements and the representation/feature ADR; capture the
current x86 ABI and performance baseline; add feature-aware CTest dispatch;
establish ARM64 execution infrastructure. Then implement X86-1 and ARM-1A as
independently verifiable increments. Re-estimate the wider-vector projects
after these establish the cost of lowering and ABI changes.

[intel-sdm]: https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html
[intel-intrinsics]: https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html
[acle]: https://arm-software.github.io/acle/main/acle.html
[neon]: https://arm-software.github.io/acle/neon_intrinsics/advsimd.html
[arm-compare]: https://learn.arm.com/learning-paths/cross-platform/vectorization-comparison/1-vectorization/
[windows-arm64]: https://learn.microsoft.com/en-us/cpp/build/arm64-windows-abi-conventions?view=msvc-170
