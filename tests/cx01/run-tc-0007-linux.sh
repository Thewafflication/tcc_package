#!/bin/sh
set -eu

if test "$#" -ne 2; then
    echo "usage: $0 TCC_BUILD_DIRECTORY EVIDENCE_DIRECTORY" >&2
    exit 2
fi

build_directory=$(CDPATH= cd -- "$1" && pwd)
evidence_directory=$2
mkdir -p "$evidence_directory"

make -C "$build_directory" test >"$evidence_directory/make-test.log" 2>&1
if ! grep -q -- 'ALL TESTS PASSED' "$evidence_directory/make-test.log"; then
    echo "upstream success marker was not found" >&2
    exit 1
fi

printf '%s\n' \
    "test_id=TCC-CX-TC-0007" \
    "requirement_id=TCC-CX-REQ-0009" \
    "target=Linux-x86_64" \
    "upstream_suite=make-test" \
    "verdict=Pass" >"$evidence_directory/metadata.txt"
echo "TCC-CX-TC-0007: Pass ($evidence_directory)"
