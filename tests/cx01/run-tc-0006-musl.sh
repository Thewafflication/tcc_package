#!/bin/sh
set -eu

if test "$#" -ne 3; then
    echo "usage: $0 TCC MUSL_ROOT EVIDENCE_DIRECTORY" >&2
    exit 2
fi

compiler=$1
musl_root=$2
evidence_directory=$3
expected_revision=f21a96538f78fa8e2040831b4209b35f2fb581da
repository_root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
compiler=$(CDPATH= cd -- "$(dirname "$compiler")" && pwd)/$(basename "$compiler")
musl_root=$(CDPATH= cd -- "$musl_root" && pwd)
compiler_root=$(dirname "$compiler")

mkdir -p "$evidence_directory"
actual_revision=$(sed -n '1p' "$musl_root/.git/HEAD")
if test "$actual_revision" != "$expected_revision"; then
    echo "unexpected musl revision: $actual_revision" >&2
    exit 1
fi

(
    cd "$musl_root"
    CC="$compiler" sh ./configure --disable-shared
) >"$evidence_directory/configure.log" 2>&1

set --
for source in "$musl_root"/src/complex/*.c; do
    name=$(basename "$source" .c)
    set -- "$@" "obj/src/complex/$name.o"
done
make -B -C "$musl_root" "$@" >"$evidence_directory/complex-build.log" 2>&1

object_count=$(find "$musl_root/obj/src/complex" -name '*.o' -type f | wc -l)
if test "$object_count" -ne 68; then
    echo "expected 68 complex objects, found $object_count" >&2
    exit 1
fi

"$compiler" -B "$compiler_root" -std=c11 -I "$musl_root/include" \
    -run "$repository_root/tests/cx01/tc-0006-musl-header.c" -lm \
    >"$evidence_directory/header-run.log" 2>&1

printf '%s\n' \
    "test_id=TCC-CX-TC-0006" \
    "requirement_id=TCC-CX-REQ-0010" \
    "musl_revision=$actual_revision" \
    "complex_object_count=$object_count" \
    "verdict=Pass" >"$evidence_directory/metadata.txt"
echo "TCC-CX-TC-0006: Pass ($evidence_directory)"
