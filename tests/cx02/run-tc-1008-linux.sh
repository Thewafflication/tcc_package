#!/bin/sh
set -eu

if test "$#" -ne 3; then
    echo "usage: $0 TCC_BUILD REPOSITORY_ROOT EVIDENCE_DIRECTORY" >&2
    exit 2
fi

build_directory=$(CDPATH= cd -- "$1" && pwd)
repository_root=$(CDPATH= cd -- "$2" && pwd)
evidence_directory=$3
compiler=$build_directory/tcc
mkdir -p "$evidence_directory"

"$compiler" -B "$build_directory" -std=c11 -run \
    "$repository_root/tests/cx02/tc-1005-arithmetic-hardening.c" \
    >"$evidence_directory/arithmetic.log" 2>&1
make -C "$build_directory" test \
    >"$evidence_directory/make-test.log" 2>&1
grep -q -- 'ALL TESTS PASSED' "$evidence_directory/make-test.log"

printf '%s\n' \
    'test_id=TCC-CX-TC-1008' \
    'requirement_id=TCC-CX-REQ-1008' \
    'target=Linux-x86_64' \
    'verdict=Pass' >"$evidence_directory/metadata.txt"
echo "TCC-CX-TC-1008: Pass ($evidence_directory)"
