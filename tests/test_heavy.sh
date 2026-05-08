#!/bin/bash
# =============================================================
# Test Scenario 3 — Heavy workload
# Directive: section 3.2.4 of project guidelines
# Mode: thread (-t)
# Backend: docker (-b docker)
# Project: examples/microservices-monorepo (6 services)
# Also demonstrates drift detection
# =============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENVCTR="$ROOT_DIR/envctr"
PROJECT="$ROOT_DIR/examples/microservices-monorepo"
LOG_DIR="$SCRIPT_DIR/tmp/logs/heavy"
LOCKFILE="$PROJECT/envctr.lock"
RUNNER_DIR="$SCRIPT_DIR/tmp/envctr-runner-heavy"
RUNNER="$RUNNER_DIR/envctr"
export LOG_DIR

cleanup() {
    rm -f "$LOCKFILE"
    rm -rf "$RUNNER_DIR"
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

mkdir -p "$LOG_DIR"
prepare_runner

echo ""
echo "========================================"
echo " Test Scenario 3 — Heavy (threads)"
echo "========================================"
echo " Project : $PROJECT"
echo " Mode    : thread (-t)"
echo " Backend : docker (-b docker)"
echo " Ref     : directive 3.2.4 — heavy workload"
echo ""

if ! command -v gcc >/dev/null 2>&1; then
    echo "[FAIL] gcc is required to build helpers/thread_helper"
    exit 1
fi

gcc "$RUNNER_DIR/helpers/thread_helper.c" -o "$RUNNER_DIR/helpers/thread_helper" -lpthread
chmod +x "$RUNNER_DIR/helpers/thread_helper"

# Phase 1: Provision with threads
echo "--- Phase 1: Fingerprint + Lock (thread mode) ---"
set +e
bash "$RUNNER" -t -b docker -p "$PROJECT" -l "$LOG_DIR"
EXIT_CODE=$?
set -e

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "[PASS] Thread mode completed"
else
    echo "[FAIL] Thread mode failed with exit code $EXIT_CODE"
    exit 1
fi

# Check lockfile
if [[ -f "$LOCKFILE" ]]; then
    echo "[PASS] Lockfile created: $LOCKFILE"
else
    echo "[FAIL] Lockfile not found at: $LOCKFILE"
    exit 1
fi

# Phase 2: Drift detection
echo ""
echo "--- Phase 2: Drift detection ---"
set +e
bash "$RUNNER" -b docker --drift -p "$PROJECT" -l "$LOG_DIR"
DRIFT_CODE=$?
set -e

if [[ $DRIFT_CODE -eq 0 ]]; then
    echo "[PASS] No drift detected — environment matches lockfile"
elif [[ $DRIFT_CODE -eq 109 ]]; then
    echo "[INFO] Drift detected — see report above"
    echo "[PASS] Drift detection ran successfully"
else
    echo "[FAIL] Drift detection failed with exit code $DRIFT_CODE"
    exit 1
fi

# Check log
if [[ -f "$LOG_DIR/history.log" ]]; then
    echo "[PASS] Log file exists: $LOG_DIR/history.log"
    echo ""
    echo "--- Last 5 log lines ---"
    tail -5 "$LOG_DIR/history.log"
    echo "------------------------"
else
    echo "[WARN] Log file not found"
fi

# Cleanup
cleanup
echo ""
echo "[PASS] Lockfile cleaned up"
echo ""
echo "========================================"
echo " Scenario 3 PASSED"
echo "========================================"
