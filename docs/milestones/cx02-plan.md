# CX2 Plan — Hosted Complex Library and Hardening

**Status:** Completed and verified

**Date:** 2026-08-13

## Objective

Complete `TCC-CX-REQ-1001` through `TCC-CX-REQ-1008`: provide the hosted
Windows complex library, correct type-generic dispatch, harden exceptional
arithmetic, and close the CX1 debug-type follow-up.

## Slices

| Slice | Content | Gate |
| --- | --- | --- |
| 1 | `<complex.h>` and basic functions | `TC-1001`, `TC-1002` |
| 2 | Elementary function library | `TC-1003`, `TC-1004` |
| 3 | Runtime multiply/divide recovery | `TC-1005` |
| 4 | `<tgmath.h>` complex selection | `TC-1006` |
| 5 | DWARF complex base types | `TC-1007` |
| 6 | Package and upstream regression matrix | `TC-1008` |

## Exit

CX2 exits when every requirement has passed applicable evidence, all material
review findings are resolved, all three Windows package targets pass, Linux
native and musl gates pass, and explicit non-claims remain documented.

CX2 met this exit gate on 2026-08-13. See `cx02-verification.md`.
