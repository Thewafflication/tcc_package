# WSP Adoption Record — TinyCC `_Complex` Program

**Content type:** Adoption record

**Project:** TinyCC Windows packages (`tcc_package`)

**WSP baseline:** Immutable commit
`2198ccab08f969a789448767fe7017b774369adc`

**Submodule path:** `wsp/`

**Status:** Accepted for CX1 and CX2

## Common Baseline

| Requirement set or practice | Disposition | Project artifact or rationale |
| --- | --- | --- |
| Requirements management | Applicable | `docs/requirements/complex-requirements.md` |
| WSP software lifecycle | Applicable | `docs/project-process.md` and milestone records |
| Project process | Applicable | `docs/project-process.md` |
| Testing requirements | Applicable | `docs/test-strategy.md`, controlled tests, and CTest evidence |
| Documentation requirements | Tailored | Markdown and TeX control records are required; a release PDF is deferred because this is a compiler feature branch, not a package release |
| Release readiness | Deferred | Required before the feature is included in a published package |

## Selected Profiles

| Profile | Selected | Scope or rationale |
| --- | --- | --- |
| Personal process | No | Individual time and defect metrics are not required for CX1 |
| Security/DFS | Tailored | Hostile-source and resource-risk review applies; a project-wide DFS is deferred |
| C source style | Yes | TinyCC-owned C changes retain upstream style |
| PowerShell style | Yes | Project-owned test and evidence runners |
| CMake style | Yes | Package-level CTest integration |
| Windows version resources | No | CX1 does not change executable identity or resources |
| Windows signing and Defender | Deferred | Applies at package release, not feature verification |
| Common tools | Yes | Traceability and evidence validation where compatible with this repository |

## Tailoring Decisions

### Upstream source ownership

TinyCC production changes remain in the `tinycc/` submodule. Project-owned
requirements, plans, runners, and evidence definitions remain in the wrapper
repository. Generated results remain under ignored `out/` directories.

### Release matrix

CX1 requires native x86 and x64 Windows execution, ARM64 code-generation and
ABI inspection, and native x86-64 Linux execution when WSL is available.
Native ARM64 execution is a release-hardening obligation and cannot be reported
as passed from an x64-hosted cross-compiler.

### Library boundary

CX1 implements the C language `_Complex` types and the compatibility surface
needed to consume a conforming `<complex.h>`. CX2 implements the Windows C99
complex function family and C11 construction macros. `_Imaginary` and full
IEC 60559 Annex G conformance remain outside the accepted program claim.

## Baseline History

| Date | WSP baseline | Project change | Summary |
| --- | --- | --- | --- |
| 2026-08-12 | `2198ccab08f969a789448767fe7017b774369adc` | CX0 | Adopted for `_Complex` work |
| 2026-08-13 | `2198ccab08f969a789448767fe7017b774369adc` | CX2 | Applied the pinned process through hosted-library closeout |
