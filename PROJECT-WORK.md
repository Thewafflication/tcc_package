# Project Work Record

**WSP Baseline:** `2198ccab08f969a789448767fe7017b774369adc` (WSP-PROC-0012 adoption)

**Submodule Path:** `wsp/`

**Pinned Commit:** `2198ccab08f969a789448767fe7017b774369adc`

**Status:** Adopted and active

## Common Baseline

| Requirement set or practice | Applicability | Project artifact or scope |
|---|---|---|
| Common requirements management | Yes | All controlled project requirements |
| WSP software lifecycle | Yes | Project lifecycle or mapped process |
| Project process | Yes | Planning through support and improvement |
| Documentation requirements | Yes | Controlled project documentation |
| Documentation style and identifiers | Yes | Project-authored artifacts |
| Testing requirements | Yes | Project verification and evidence |
| C source style | Yes | Owned C files, or N/A rationale |
| PowerShell style | Yes / No | In-scope automation, or reason not applicable |
| CMake style | Yes / No | In-scope build files, or reason not applicable |
| Windows version resources | Yes / No | Shipped project-owned EXEs and DLLs |
| Windows code signing and Defender | Yes / No | Shipped Windows artifacts |
| Common tools | Yes / No | Reusable validation and reporting tools |

## Selected Profiles

| Profile | Selected | Project scope or rationale |
|---|---|---|
| Personal process | Yes | Individual planning and improvement |
| Information for users | Yes | User documentation, reference, tutorials |
| Security/DFS | Yes | Security scope, design, and verification |
| C source style | Yes | Owned C files and test vectors |
| Windows code signing and Defender | Yes | Windows package signing and security |

## Requirement Dispositions

| WSP requirement | Disposition | Project artifact | Rationale or notes |
|---|---|---|---|
| `WSP-REQM-0001` | Applicable | Project requirements index | |
| `WSP-CSTYLE-0001` | Applicable | Source requirement and test | |
| `WSP-TEST-0001` | Applicable | Regression test suite | |
| `WSP-BUILD-0001` | Applicable | Build configuration and scripts | |
| `WSP-PKG-0001` | Applicable | Package build and publication | |

## WSP Adoption Details

- **Adoption commit:** `2198ccab08f969a789448767fe7017b774369adc`
- **Adoption date:** 2026-08-13 (per project-plan.md milestones)
- **Submodule state:** Modified from baseline per recent git history (2108829, 0162130)
- **CX1 status:** Completed - C99 `_Complex` language implementation with exit gate met
- **CX2 status:** Completed - Hosted library and exceptional-value hardening with exit gate met
- **milestones:** See `docs/project-plan.md` for detailed CX1/CX2 verification matrices
- **SIMD roadmap:** See `docs/simd-support.md` and `docs/simd-roadmap.md` for planned extensions

## Project-Specific Notes

- TinyCC submodule (`tinycc/`) is modified from baseline; see git history for change context
- x86/x64/ARM64 package build paths preserved per project-plan.md dependencies
- Build system fixes and signing infrastructure maintained per git history
- Owner-index changes (untracked Initialize-ProjectWork.ps1 at root) preserved per reconciliation requirements