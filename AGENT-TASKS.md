# Agent Tasks Record

**WSP Baseline:** `2198ccab08f969a789448767fe7017b774369adc`

**Related to:** PROJECT-WORK.md adoption record

**Current Focus:** Continue towards next useful project milestone

## Adoption Context

This record aligns with the WSP-PROC-0012 adoption baseline documented in PROJECT-WORK.md. Both records reference the same pinned commit and baseline requirements.

## Outstanding Work Items

- **TinyCC submodule modifications:** Review `tinycc/` modified content per git status and reconcile with adoption baselines
- **Build validation:** Run project build and test validation per git history markers (e.g., 39603eb Package SSE/SSE2 support with header and ABI regression tests)
- **SIMD support:** Review `docs/simd-support.md` and `docs/simd-roadmap.md` coverage for MMX/SSE/SSE2 intrinsics
- **Owner-index changes:** Preserve untracked `Initialize-ProjectWork.ps1` at repo root per reconciliation requirements

## Branch/Worktree

- **Branch:** `main` (up to date with `origin/main`)
- **Worktree state:** Modified tinycc submodule, untracked Initialize-ProjectWork.ps1

## Retained Checks

- Existing acceptance gates from prior work must not be weakened
- CMake baseline failures should convert to SKIP (per prior design decisions)
- Code signing and Defender validation preserved
- Windows version resource packaging preserved

## Acceptance Commands

```powershell
# Build validation (project-specific)
.\tools\Build-Documentation.ps1

# Test validation (project-specific)
.\tools\tests\run-tests.ps1
```

## Publication Target

- Configuration: WPM repository at GitHub releases
- Package presets: x86-debug, x86-release, x64-msvc, arm64-msvc
- Release artifacts: Signed Windows packages per `16494fa packages now signed`

## Next Milestone Decision

Select a bounded deliverable from the git history and requirements:

1. **SIMD regression coverage** - validate hash-slide and vector assignment operations per 39603eb
2. **Long-double arithmetic** - verify `d5c02f0 Test long double arithmetic conversions` 
3. **Complex numbers** - confirm `1609a3f Complete TinyCC complex number implementation` exit gates
4. **Package build pipeline** - verify signed package generation for all presets

Choose one bounded deliverable, implement validation, and record results. Do not create filler tests or notes just to claim a commit.

## Related Records

- `PROJECT-WORK.md` - formal adoption record (aligned baseline)
- `docs/adoption-record.md` - original adoption record
- `docs/project-plan.md` - detailed CX1/CX2 milestone plan
- `wsp/requirements/` - requirement sets per CX1/CX2 profiles