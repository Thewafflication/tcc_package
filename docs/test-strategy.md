# TinyCC `_Complex` Test Strategy

**Document ID:** `TCC-CX-TEST-STRATEGY-0001`

**Status:** Approved and completed for CX1 and CX2

## Levels and Methods

| Level | Scope |
| --- | --- |
| Front-end | Syntax, types, constraints, diagnostics, token replay |
| Semantic | Conversions, operators, side effects, initializers, conditions |
| Representation | Size, alignment, bytes, signed zero, pointer/union views |
| ABI | Arguments, returns, nested calls, variadics, mixed compilers |
| Integration | System `<complex.h>`, pinned musl complex subsystem |
| Regression | Upstream TinyCC tests and package build matrix |
| Quality | Traceability, source review, evidence validation |

## Test Design

Use grammar-based syntax testing for specifier combinations; equivalence
partitioning and boundary analysis for precisions, zero/finite/infinite/NaN
components, storage duration, and target ABI classes; decision tables for
usual arithmetic conversions and valid operators; state/side-effect tests for
single evaluation; metamorphic properties for conjugate-independent core
arithmetic; and differential tests against GCC or another designated ABI
oracle.

## Controlled Tests

| Test | Principal coverage |
| --- | --- |
| `TC-0001` | Type syntax, identity, layout, introspection, constraints, diagnostics |
| `TC-0002` | Constants, initialization, objects, storage |
| `TC-0003` | Conversions, truth, logical and conditional behavior |
| `TC-0004` | Arithmetic, equality, compound assignment, side effects |
| `TC-0005` | Calls, returns, varargs, cross-compiler ABI |
| `TC-0006` | Pinned musl header and complex subsystem compilation |
| `TC-0007` | Package matrix and upstream regression suites |
| `TC-1001` | Windows hosted header, declarations, macros, and links |
| `TC-1002` | Basic complex functions and component representation |
| `TC-1003` | Elementary functions, identities, and finite accuracy |
| `TC-1004` | Allocated signed-zero, infinity, and NaN cases |
| `TC-1005` | Runtime multiply/divide scaling, recovery, and private helper ABI |
| `TC-1006` | Complex type-generic selection and mixed `pow` |
| `TC-1007` | DWARF complex base-type identity and size |
| `TC-1008` | CX1, package, and upstream regression matrix |

## Execution and Evidence

CTest dispatches all project-owned gates. Upstream suites run beneath a CTest
wrapper. Each run records test/spec revisions, requirement IDs, superproject
revision, TinyCC revision, target and host architecture, native/cross status,
OS, toolchain, command, timestamps, exit status, verdict, output, and artifact
hashes. Reruns archive rather than overwrite failures.

## Gates

No status other than Pass satisfies a required configuration. ARM64 build-only
evidence cannot satisfy native execution. A differential mismatch is Fail
until explained as an allowed implementation choice and approved through a
requirement or risk decision.
