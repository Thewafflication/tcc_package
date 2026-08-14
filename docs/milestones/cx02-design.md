# CX2 Design — Hosted Complex Library and Hardening

**Status:** Implemented and verified

**Date:** 2026-08-13

## Header and Library

The Windows `<complex.h>` declares the complete clause 7.3 function family,
defines `complex`, `_Complex_I`, and `I`, and provides C11 construction macros
through `__builtin_complex`. Because TinyCC does not implement `_Imaginary`,
the conditional imaginary macros remain absent.

One package-owned runtime object implements the complex function symbols.
Double functions are the primary algorithms. Float wrappers use double
intermediates and cast both components. Windows long-double wrappers are exact
for TinyCC's existing double-width long-double ABI.

## Arithmetic Recovery

Multiplication scales finite operands before evaluating the products and
applies compiler-runtime recovery when both result components become NaN
through infinity normalization. Division uses scaled ratios and handles zero,
infinite numerator, and infinite denominator recovery cases.

The compiler materializes operands once, calls the precision-appropriate
real-component helper, and reloads the paired result. Addition, subtraction,
equality, and conversions retain the CX1 paths.

## Library Numerics

Basic functions operate directly on components. Square root uses a scaled
principal-root algorithm. Exponential, hyperbolic, and projection functions
have explicit zero, infinity, and NaN branches. Remaining elementary
functions use standard analytic identities around those hardened primitives.

The milestone verifies the allocated C special cases and finite accuracy. It
does not claim full IEC 60559 Annex G conformance, signaling-NaN behavior,
floating-point exception flags, or `_Imaginary` support.

## Type-generic Dispatch

`<tgmath.h>` includes `<complex.h>` and extends each shared unary and power
selection to float, double, and long-double complex types. Mixed real/complex
power operands are materialized as the selected complex precision before the
call. `fabs` selects `cabs`; complex-only functions select by precision.

## Debug Information

The debug type mapper recognizes the scalar complex flag before the generic
structure path and emits cached base types using `DW_ATE_complex_float`, the
standard type spelling, and twice the corresponding real byte size.
