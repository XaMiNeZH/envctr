#!/bin/bash

fingerprint() {
    local PROJECT_DIR="$1"

    DETECTED_RUNTIME=""
    DETECTED_SERVICES=""
    DETECTED_PORTS=""
    DETECTED_ENV_VARS=""

    # Check if directory exists
    if [[ ! -d "$PROJECT_DIR" ]]; then
        log_message "ERROR" "Project directory not found: $PROJECT_DIR"
        return 102
    fi

    # Detect runtime
    if [[ -f "$PROJECT_DIR/package.json" ]]; then
        DETECTED_RUNTIME="node"

    elif [[ -f "$PROJECT_DIR/requirements.txt" || -f "$PROJECT_DIR/pyproject.toml" ]]; then 
        DETECTED_RUNTIME="python"

    elif [[ -f "$PROJECT_DIR/pom.xml" ]]; then
        DETECTED_RUNTIME="java"
    fi
 
    # Detect services
    if grep -Riq "redis" "$PROJECT_DIR" 2>/dev/null; then
        DETECTED_SERVICES="$DETECTED_SERVICES redis"
    fi

    if [[ -f "$PROJECT_DIR/knexfile.js" ]]; then
        DETECTED_SERVICES="$DETECTED_SERVICES postgresql"
    fi

    # Detect ports
    if [[ -f "$PROJECT_DIR/.env" ]];then
        DETECTED_PORTS=$(grep -E '^PORT=[0-9]+' "$PROJECT_DIR/.env" | cut -d '=' -f2)
    elif [[ -f "$PROJECT_DIR/.env.example" ]]; then
        DETECTED_PORTS=$(grep -E '^PORT=[0-9]+' "$PROJECT_DIR/.env.example" | cut -d '=' -f2)
    fi

    # Detect env variables
    if [[ -f "$PROJECT_DIR/.env.example" ]]; then
        DETECTED_ENV_VARS=$(grep -E '^[A-Z]+=' "$PROJECT_DIR/.env.example" | cut -d '=' -f1)
    fi

    log_message "INFO" "Fingerprint complete -- detected: $DETECTED_RUNTIME"
}
