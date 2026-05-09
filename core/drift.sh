#!/bin/bash

CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/logger.sh"
source "$CORE_DIR/fingerprint.sh"
source "$CORE_DIR/lock.sh"

# detect_drift PROJECT_DIR
# Compares the saved lockfile metadata with a fresh project fingerprint.
# Returns 0 when clean, 109 for drift, 106 for lock errors, and 105 for fingerprint errors.
detect_drift() {
    local PROJECT_DIR="$1"
    local PROJECT_NAME
    local TIMESTAMP
    local HAS_DRIFT=0
    local CURRENT_BACKEND
    local LOCK_ENV_COUNT
    local DETECTED_ENV_COUNT
    local REPORT
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
    CURRENT_BACKEND="${DETECTED_BACKEND:-${BACKEND:-}}"

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

    if [[ -n "$CURRENT_BACKEND" && "$CURRENT_BACKEND" != "$LOCK_BACKEND" ]]; then
        WARNING_LINES+=("  [backend]  expected $LOCK_BACKEND -- found $CURRENT_BACKEND")
        HAS_DRIFT=1
    fi

    if [[ "$DETECTED_ENV_VARS" != "$LOCK_ENV_VARS" ]]; then
        LOCK_ENV_COUNT=$(awk -F',' '{ print ($0 == "" ? 0 : NF) }' <<< "$LOCK_ENV_VARS")
        DETECTED_ENV_COUNT=$(awk -F',' '{ print ($0 == "" ? 0 : NF) }' <<< "$DETECTED_ENV_VARS")
        INFO_LINES+=("  [environment]  expected $LOCK_ENV_COUNT variables -- found $DETECTED_ENV_COUNT variables (details redacted)")
        HAS_DRIFT=1
    fi

    if [[ "$HAS_DRIFT" -eq 0 ]]; then
        REPORT=$(printf 'envctr drift report -- %s\nProject : %s\nStatus  : NO DRIFT DETECTED\n' "$TIMESTAMP" "$PROJECT_NAME")
        LAST_DRIFT_REPORT="$REPORT"
        export LAST_DRIFT_REPORT
        printf '%s\n' "$REPORT"
        return 0
    fi

    REPORT=$(
        printf 'envctr drift report -- %s\n' "$TIMESTAMP"
        printf 'Project : %s\n' "$PROJECT_NAME"
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
    )

    LAST_DRIFT_REPORT="$REPORT"
    export LAST_DRIFT_REPORT
    printf '%s\n' "$REPORT"
    log_message "ERROR" "Drift detected in project: $PROJECT_DIR" || true
    return 109
}
