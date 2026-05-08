#!/bin/bash
# =============================================================
# Test Scenario 1 — Light workload
# Directive: section 3.2.4 of project guidelines
# Mode: subshell (-s)
# Backend: chroot (-b chroot)
# Project: examples/flask-simple (Python, no services)
# =============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENVCTR="$ROOT_DIR/envctr"
PROJECT="$ROOT_DIR/examples/flask-simple"
LOG_DIR="$SCRIPT_DIR/tmp/logs/light"
LOCKFILE="$PROJECT/envctr.lock"

mkdir -p "$LOG_DIR"

echo ""
echo "========================================"
echo " Test Scenario 1 — Light (subshell)"
echo "========================================"
echo " Project : $PROJECT"
echo " Mode    : subshell (-s)"
echo " Backend : chroot (-b chroot)"
echo " Ref     : directive 3.2.4 — light workload"
echo ""

# Run envctr
"$ENVCTR" -s -b chroot -p "$PROJECT" -l "$LOG_DIR"
EXIT_CODE=$?

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
else
    echo "[FAIL] Lockfile not found at: $LOCKFILE"
    exit 1
fi

# Check log
if [[ -f "$LOG_DIR/history.log" ]]; then
    echo "[PASS] Log file created: $LOG_DIR/history.log"
    echo ""
    echo "--- Last 3 log lines ---"
    tail -3 "$LOG_DIR/history.log"
    echo "------------------------"
else
    echo "[WARN] Log file not found at: $LOG_DIR/history.log"
fi

# Cleanup
rm -f "$LOCKFILE"
echo ""
echo "[PASS] Lockfile cleaned up"
echo ""
echo "========================================"
echo " Scenario 1 PASSED"
echo "========================================"
