# CX2 Findings Log

**Status:** Closed; all findings resolved

## CX2-F-0001 — Windows package omitted new runtime objects

**Severity:** High

**Status:** Resolved

The Windows batch build enumerates runtime objects independently of the
portable library makefile. Both `complex-arith.o` and `tcc-complex.o` are now
compiled and archived by that build, and all package targets link the symbols.

## CX2-F-0002 — Missing x86 single-precision math shims

**Severity:** High

**Status:** Resolved

The first x86 library link found that the Windows compatibility math header
lacked `hypotf` and `copysignf`. The shims now match the existing wrapper
model; the x86 library and all controlled functions link and execute.

## CX2-F-0003 — Windows long-double limits disagreed with its ABI

**Severity:** Medium

**Status:** Resolved

`float.h` advertised x87 extended limits on Windows although TinyCC's Windows
ABI treats `long double` as double width. The Windows macros now describe that
ABI, and `TC-1001` checks the invariant.

## CX2-F-0004 — Parallel evidence directories could collide

**Severity:** Medium

**Status:** Resolved

Concurrent architecture runs could start in the same millisecond and select
one evidence directory. PowerShell run IDs now include the process ID. A
concurrent 45-test matrix passed without collisions.

## CX2-F-0005 — Finite multiplication could lose cancellation

**Severity:** High

**Status:** Resolved

The initial infinity recovery did not cover finite products where both large
intermediate terms overflow before cancellation. Finite operands are now
scaled before multiplication; `TC-1005` covers the cancellation case.

## CX2-F-0006 — Mixed type-generic power exposed a SysV call defect

**Severity:** High

**Status:** Resolved

On Linux, passing a real expression directly to the selected `cpow` call lost
the real component during TinyCC's implicit argument conversion. The macro now
materializes both operands in the selected complex precision through compound
literals. Mixed `pow` passes on Windows and Linux with single evaluation.

## CX2-F-0007 — Linux regression runner omitted its runtime search path

**Severity:** Medium

**Status:** Resolved

The Linux wrapper invoked the source compiler without selecting its freshly
built runtime library. It now supplies `-B` with the build directory. The
hardened arithmetic prerequisite and full upstream suite pass from that tree.

## CX2-F-0008 — Windows ARM64 complex helper ABI mismatch

**Severity:** Critical

**Status:** Resolved

Complex multiplication and division lowered their runtime calls through the
generic old-style helper type. The Windows ARM64 backend correctly classified
those calls like variadic calls, placing the four binary64 components in
`x0`--`x3` and the result pointer in `x4`, while the typed C helper entries
expected `d0`--`d3` and `x0`. The compiler now gives these private helpers
complete ANSI prototypes. `TC-1005` executes float, double, and long-double
multiply/divide cases and inspects ARM64 call sites even on cross-build hosts.
