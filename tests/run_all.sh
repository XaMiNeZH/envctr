#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT_DIR/tests/test_light.sh"
bash "$ROOT_DIR/tests/test_medium.sh"
bash "$ROOT_DIR/tests/test_heavy.sh"

printf '%s\n' "All envctr scenarios passed"
