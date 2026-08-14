# ADR-0002: Runtime Helpers and a Package-owned Complex Library

**Status:** Accepted

**Date:** 2026-08-13

## Decision

Use real-component runtime helpers for robust complex multiplication and
division. The helpers accept four real components and an output pointer, so
they do not create a second complex calling convention.

Provide the Windows C99 complex functions as an object in `libtcc1.a` and the
public declarations in `win32/include/complex.h`. The library uses reviewed
real formulas and explicit exceptional-value paths. Float variants may use
double intermediates; Windows long double follows TinyCC's existing
double-width long-double model.

Represent complex values in DWARF as `DW_ATE_complex_float` base types. The
aggregate-backed internal compiler representation remains unchanged.

## Consequences

Ordinary complex multiplication and division incur a helper call unless a
future optimization proves a safe inline case. The result is stable across
backend register allocators and centralizes exceptional-value recovery.

The hosted complex library is package-owned rather than imported as an opaque
binary. Its source, tests, and non-claims remain reviewable with the compiler.
