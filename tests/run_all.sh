#!/bin/bash
# =============================================================
# Run all three test scenarios
# Directive: section 3.2.4 of project guidelines
# =============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PASS=0
FAIL=0
RESULTS=()

run_test() {
    local NAME="$1"
    local SCRIPT="$2"
    echo ""
    echo "================================================"
    echo " Running: $NAME"
    echo "================================================"
    if bash "$SCRIPT"; then
        RESULTS+=("PASS: $NAME")
        PASS=$((PASS + 1))
    else
        RESULTS+=("FAIL: $NAME")
        FAIL=$((FAIL + 1))
    fi
}

run_test "Scenario 1 — Light (subshell)" "$SCRIPT_DIR/test_light.sh"
run_test "Scenario 2 — Medium (fork)"    "$SCRIPT_DIR/test_medium.sh"
run_test "Scenario 3 — Heavy (threads)"  "$SCRIPT_DIR/test_heavy.sh"

echo ""
echo "================================================"
echo " RESULTS"
echo "================================================"
for r in "${RESULTS[@]}"; do
    echo " $r"
done
echo ""
echo " Total: $PASS passed, $FAIL failed"
echo "================================================"

[[ $FAIL -eq 0 ]]
