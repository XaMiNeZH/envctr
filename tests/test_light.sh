#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="tests/tmp/light-flask-simple"
LOG_DIR="$TMP_DIR/logs"
export LOG_DIR

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

rm -rf "$TMP_DIR"
mkdir -p "$(dirname "$TMP_DIR")"
cp -R "examples/flask-simple" "$TMP_DIR"

bash "envctr" -s -b chroot -p "$TMP_DIR" > "$TMP_DIR/run.out"
test -f "$TMP_DIR/envctr.lock"
grep -q 'type = chroot' "$TMP_DIR/envctr.lock"

bash "envctr" --drift -s -b chroot -p "$TMP_DIR" > "$TMP_DIR/drift.out"
grep -q 'NO DRIFT DETECTED' "$TMP_DIR/drift.out"
test -f "$LOG_DIR/history.log"

printf '%s\n' "test_light passed"
