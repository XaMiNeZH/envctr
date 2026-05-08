#!/bin/bash
# =============================================================
# Test Scenario 2 — Medium workload
# Directive: section 3.2.4 of project guidelines
# Mode: fork (-f)
# Backend: docker (-b docker)
# Project: examples/node-api (Node.js, PostgreSQL, Redis)
# =============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENVCTR="$ROOT_DIR/envctr"
PROJECT="$ROOT_DIR/examples/node-api"
LOG_DIR="$SCRIPT_DIR/tmp/logs/medium"
LOCKFILE="$PROJECT/envctr.lock"

mkdir -p "$LOG_DIR"

echo ""
echo "========================================"
echo " Test Scenario 2 — Medium (fork)"
echo "========================================"
echo " Project : $PROJECT"
echo " Mode    : fork (-f)"
echo " Backend : docker (-b docker)"
echo " Ref     : directive 3.2.4 — medium workload"
echo ""

# Run envctr
"$ENVCTR" -f -b docker -p "$PROJECT" -l "$LOG_DIR"
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
    echo ""
    echo "--- Lockfile contents ---"
    cat "$LOCKFILE"
    echo "-------------------------"
else
    echo "[FAIL] Lockfile not found at: $LOCKFILE"
    exit 1
fi

# Check log
if [[ -f "$LOG_DIR/history.log" ]]; then
    echo "[PASS] Log file created: $LOG_DIR/history.log"
else
    echo "[WARN] Log file not found at: $LOG_DIR/history.log"
fi

# Cleanup
rm -f "$LOCKFILE"
echo ""
echo "[PASS] Lockfile cleaned up"
echo ""
echo "========================================"
echo " Scenario 2 PASSED"
echo "========================================"
