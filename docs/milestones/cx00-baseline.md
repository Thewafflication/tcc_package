# CX0 Baseline Record

**Status:** Complete for the planning gate

**Date:** 2026-08-12

## Controlled Revisions

- Superproject branch: `complex_numbers`
- Prior TinyCC revision: `2be0218be4461f9e453cbdcb98f81f41a5ae8bed`
- CX1 TinyCC baseline: `2ba12e83b3599ca8f5d50c179fe5138fe956f0c9`
- WSP baseline: `2198ccab08f969a789448767fe7017b774369adc`

Both submodules were clean at the recorded revisions when this baseline was
captured.

## Windows x64 Baseline

Host CMake was version 4.4.2. The following existing package commands
completed successfully:

```powershell
cmake --preset x64-debug
cmake --build --preset x64-debug --target tinycc
```

The resulting compiler identified itself as:

```text
tcc version 0.9.28rc (x86_64 Windows)
```

The controlled absence probe was:

```c
int main(void)
{
    double _Complex value = 1.0;
    return sizeof value != 16;
}
```

Running the probe through the built compiler failed as expected with:

```text
-:1: error: _Complex is not yet supported
```

This is the feature baseline, not a regression failure.

## Linux x86-64 Baseline

WSL supplied GCC 12.2 and `/usr/bin/objdump`. TinyCC configuration did not
start because the checked-out `tinycc/configure` file had CRLF endings and the
WSL shell reported carriage-return syntax errors. No source file was changed
to bypass this result.

CX1 verification will build from a project-owned normalized copy beneath
`out/`, leaving the controlled submodule content unchanged. The native Linux
gate remains required and cannot be reported as Pass until that procedure and
the upstream suite complete.

## Planning Artifacts

Ten requirements, ten milestone allocations, seven controlled test
specifications, the representation ADR, the CX1 design, and the test strategy
are reviewable. All seven test specifications render with MiKTeX 25.12 without
LaTeX layout warnings or errors.
