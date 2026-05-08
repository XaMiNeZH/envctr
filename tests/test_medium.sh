#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="tests/tmp/medium-node-api"
LOG_DIR="$TMP_DIR/logs"
export LOG_DIR

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

rm -rf "$TMP_DIR"
mkdir -p "$(dirname "$TMP_DIR")"
cp -R "examples/node-api" "$TMP_DIR"

gcc "helpers/fork_helper.c" -o "helpers/fork_helper"
chmod +x "helpers/fork_helper"

bash "envctr" -f -b docker -p "$TMP_DIR" > "$TMP_DIR/run.out"
test -f "$TMP_DIR/envctr.lock"
grep -q 'language = node' "$TMP_DIR/envctr.lock"
grep -q 'postgresql = detected' "$TMP_DIR/envctr.lock"
grep -q 'redis = detected' "$TMP_DIR/envctr.lock"
grep -q 'type = docker' "$TMP_DIR/envctr.lock"

bash "envctr" --drift -f -b docker -p "$TMP_DIR" > "$TMP_DIR/drift.out"
grep -q 'NO DRIFT DETECTED' "$TMP_DIR/drift.out"
test -f "$LOG_DIR/history.log"

printf '%s\n' "test_medium passed"
