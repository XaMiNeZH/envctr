#!/bin/bash

CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/logger.sh"
source "$CORE_DIR/fingerprint.sh"
source "$CORE_DIR/lock.sh"

detect_drift() {
    local PROJECT_DIR="$1"
    local PROJECT_NAME
    local TIMESTAMP
    local HAS_DRIFT=0
    local BREAKING_LINES=()
    local WARNING_LINES=()
    local INFO_LINES=()

    if ! parse_lock "$PROJECT_DIR"; then
        return 106
    fi

    if ! fingerprint "$PROJECT_DIR"; then
        return 105
    fi

    PROJECT_NAME=$(basename "$PROJECT_DIR")
    TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")

    if [[ "$DETECTED_RUNTIME" != "$LOCK_RUNTIME" ]]; then
        BREAKING_LINES+=("  [runtime]  expected $LOCK_RUNTIME -- found $DETECTED_RUNTIME")
        HAS_DRIFT=1
    fi

    if [[ "$DETECTED_VERSION" != "$LOCK_VERSION" ]]; then
        WARNING_LINES+=("  [version]  expected $LOCK_VERSION -- found $DETECTED_VERSION")
        HAS_DRIFT=1
    fi

    if [[ "$DETECTED_SERVICES" != "$LOCK_SERVICES" ]]; then
        WARNING_LINES+=("  [services]  expected $LOCK_SERVICES -- found $DETECTED_SERVICES")
        HAS_DRIFT=1
    fi

    if [[ "$DETECTED_PORTS" != "$LOCK_PORTS" ]]; then
        WARNING_LINES+=("  [ports]  expected $LOCK_PORTS -- found $DETECTED_PORTS")
        HAS_DRIFT=1
    fi

    if [[ "$DETECTED_ENV_VARS" != "$LOCK_ENV_VARS" ]]; then
        INFO_LINES+=("  [environment]  expected $LOCK_ENV_VARS -- found $DETECTED_ENV_VARS")
        HAS_DRIFT=1
    fi

    printf 'envctr drift report -- %s\n' "$TIMESTAMP"
    printf 'Project : %s\n' "$PROJECT_NAME"

    if [[ "$HAS_DRIFT" -eq 0 ]]; then
        printf 'Status  : NO DRIFT DETECTED\n'
        return 0
    fi

    printf 'Status  : DRIFT DETECTED\n'

    if ((${#BREAKING_LINES[@]} > 0)); then
        printf '\nBREAKING\n'
        printf '%s\n' "${BREAKING_LINES[@]}"
    fi

    if ((${#WARNING_LINES[@]} > 0)); then
        printf '\nWARNING\n'
        printf '%s\n' "${WARNING_LINES[@]}"
    fi

    if ((${#INFO_LINES[@]} > 0)); then
        printf '\nINFO\n'
        printf '%s\n' "${INFO_LINES[@]}"
    fi

    log_message "ERROR" "Drift detected in project: $PROJECT_DIR" || true
    return 109
}
