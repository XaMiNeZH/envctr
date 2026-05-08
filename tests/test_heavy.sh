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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENVCTR="$ROOT_DIR/envctr"
PROJECT="$ROOT_DIR/examples/microservices-monorepo"
LOG_DIR="$SCRIPT_DIR/tmp/logs/heavy"
LOCKFILE="$PROJECT/envctr.lock"

mkdir -p "$LOG_DIR"

echo ""
echo "========================================"
echo " Test Scenario 3 — Heavy (threads)"
echo "========================================"
echo " Project : $PROJECT"
echo " Mode    : thread (-t)"
echo " Backend : docker (-b docker)"
echo " Ref     : directive 3.2.4 — heavy workload"
echo ""

# Phase 1: Provision with threads
echo "--- Phase 1: Fingerprint + Lock (thread mode) ---"
"$ENVCTR" -t -b docker -p "$PROJECT" -l "$LOG_DIR"
EXIT_CODE=$?

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
"$ENVCTR" -b docker --drift -p "$PROJECT" -l "$LOG_DIR"
DRIFT_CODE=$?

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
rm -f "$LOCKFILE"
echo ""
echo "[PASS] Lockfile cleaned up"
echo ""
echo "========================================"
echo " Scenario 3 PASSED"
echo "========================================"
