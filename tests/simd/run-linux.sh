#!/bin/sh
# Usage: sh tests/simd/run-linux.sh compiler headers [evidence-dir] [32|64]
set -eu
compiler=$(realpath "$1")
headers=$(realpath "$2")
base=$(dirname "$compiler")
tests=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
work=${3:-"$tests/../../out/test-evidence/simd-linux"}
mkdir -p "$work"
work=$(realpath "$work")
arch=${4:-64}
"$compiler" -B"$base" -L"$base" -I"$headers" -c "$tests/header-interfaces.c" -o "$work/interfaces.o"
"$compiler" -B"$base" -L"$base" -I"$headers" -bt "$tests/headers.c" -o "$work/headers"
"$work/headers"
"$compiler" -B"$base" -L"$base" -I"$headers" -bt "$tests/intrinsics.c" -o "$work/intrinsics"
"$work/intrinsics"
for name in callsite slide-hash; do
    "$compiler" -B"$base" -L"$base" -I"$headers" "$tests/$name.c" -o "$work/$name"
    "$work/$name"
done
gcc -m"$arch" -O2 -msse2 "$tests/intrinsics.c" -o "$work/reference"
"$work/reference"
gcc -m"$arch" -shared -fPIC -O2 -msse2 -mmmx "$tests/abi-peer.c" -o "$work/peer.so"
"$compiler" -B"$base" -L"$base" -I"$headers" -bt "$tests/abi-driver.c" -ldl -o "$work/abi"
"$work/abi" "$work/peer.so"
