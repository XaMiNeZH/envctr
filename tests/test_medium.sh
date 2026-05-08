#!/bin/bash
# =============================================================
# Test Scenario 2 — Medium workload
# Directive: section 3.2.4 of project guidelines
# Mode: fork (-f)
# Backend: docker (-b docker)
# Project: examples/node-api (Node.js, PostgreSQL, Redis)
# =============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENVCTR="$ROOT_DIR/envctr"
SOURCE_PROJECT="$ROOT_DIR/examples/node-api"
PROJECT="$SCRIPT_DIR/tmp/projects/node-api"
LOG_DIR="$SCRIPT_DIR/tmp/logs/medium"
LOCKFILE="$PROJECT/envctr.lock"
RUNNER_DIR="$SCRIPT_DIR/tmp/envctr-runner-medium"
RUNNER="$RUNNER_DIR/envctr"
export LOG_DIR

cleanup() {
    rm -rf "$PROJECT" "$RUNNER_DIR"
}
trap cleanup EXIT

prepare_runner() {
    local file

    rm -rf "$RUNNER_DIR"
    mkdir -p "$RUNNER_DIR/core" "$RUNNER_DIR/backends" "$RUNNER_DIR/configs" "$RUNNER_DIR/helpers"

    sed 's/\r$//' "$ENVCTR" > "$RUNNER"
    sed 's/\r$//' "$ROOT_DIR/configs/default.conf" > "$RUNNER_DIR/configs/default.conf"

    if [[ -f "$ROOT_DIR/envctr.conf" ]]; then
        sed 's/\r$//' "$ROOT_DIR/envctr.conf" > "$RUNNER_DIR/envctr.conf"
    fi

    for file in "$ROOT_DIR/core"/*.sh; do
        sed 's/\r$//' "$file" > "$RUNNER_DIR/core/$(basename "$file")"
    done

    for file in "$ROOT_DIR/backends"/*.sh; do
        sed 's/\r$//' "$file" > "$RUNNER_DIR/backends/$(basename "$file")"
    done

    for file in "$ROOT_DIR/helpers"/*.c; do
        sed 's/\r$//' "$file" > "$RUNNER_DIR/helpers/$(basename "$file")"
    done
}

prepare_project() {
    rm -rf "$PROJECT"
    mkdir -p "$(dirname "$PROJECT")"
    cp -R "$SOURCE_PROJECT" "$PROJECT"
    find "$PROJECT" -type f -exec sed -i 's/\r$//' {} +
}

mkdir -p "$LOG_DIR"
prepare_runner
prepare_project

echo ""
echo "========================================"
echo " Test Scenario 2 — Medium (fork)"
echo "========================================"
echo " Project : $PROJECT"
echo " Source  : $SOURCE_PROJECT"
echo " Mode    : fork (-f)"
echo " Backend : docker (-b docker)"
echo " Ref     : directive 3.2.4 — medium workload"
echo ""

if ! command -v gcc >/dev/null 2>&1; then
    echo "[FAIL] gcc is required to build helpers/fork_helper"
    exit 1
fi

gcc "$RUNNER_DIR/helpers/fork_helper.c" -o "$RUNNER_DIR/helpers/fork_helper"
chmod +x "$RUNNER_DIR/helpers/fork_helper"

# Run envctr
set +e
bash "$RUNNER" -f -b docker -p "$PROJECT" -l "$LOG_DIR"
EXIT_CODE=$?
set -e

# Check exit code
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "[PASS] envctr exited 0"
else
    echo "[FAIL] envctr exited $EXIT_CODE"
    exit 1
fi

# Check lockfile
if [[ -f "$LOCKFILE" ]]; then
    echo "[PASS] Lockfile created: $LOCKFILE"
    echo ""
    echo "--- Lockfile contents ---"
    cat "$LOCKFILE"
    echo "-------------------------"
else
    echo "[FAIL] Lockfile not found at: $LOCKFILE"
    exit 1
fi

# Check drift
set +e
bash "$RUNNER" --drift -f -b docker -p "$PROJECT" -l "$LOG_DIR"
DRIFT_CODE=$?
set -e

if [[ $DRIFT_CODE -eq 0 ]]; then
    echo "[PASS] No drift detected — environment matches lockfile"
else
    echo "[FAIL] Drift detection failed with exit code $DRIFT_CODE"
    exit 1
fi

# Check log
if [[ -f "$LOG_DIR/history.log" ]]; then
    echo "[PASS] Log file created: $LOG_DIR/history.log"
else
    echo "[WARN] Log file not found at: $LOG_DIR/history.log"
fi

# Cleanup
cleanup
echo ""
echo "[PASS] Lockfile cleaned up"
echo ""
echo "========================================"
echo " Scenario 2 PASSED"
echo "========================================"
