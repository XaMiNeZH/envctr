#!/bin/bash

fingerprint() {
    local PROJECT_DIR="$1"

    DETECTED_RUNTIME=""
    DETECTED_VERSION=""
    DETECTED_SERVICES=""
    DETECTED_PORTS=""
    DETECTED_ENV_VARS=""

    # Check if directory exists
    if [[ ! -d "$PROJECT_DIR" ]]; then
        log_message "ERROR" "Project directory not found: $PROJECT_DIR"
        return 102
    fi

    # Dockerfile first: skip inference
    if [[ -f "$PROJECT_DIR/Dockerfile" ]]; then
        DETECTED_RUNTIME="docker"
        log_message "INFO" "Dockerfile detected -- skipping inference"
        return 0
    fi

    # Detect runtime
    if [[ -f "$PROJECT_DIR/package.json" ]]; then
        DETECTED_RUNTIME="node"
        DETECTED_VERSION=$(grep -A 5 '"engines"' "$PROJECT_DIR/package.json" \
            | grep '"node"' \
            | sed 's/.*"node"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

    elif [[ -f "$PROJECT_DIR/requirements.txt" || -f "$PROJECT_DIR/pyproject.toml" ]]; then 
        DETECTED_RUNTIME="python"

    elif [[ -f "$PROJECT_DIR/Makefile" ]] && find "$PROJECT_DIR" -name "*.c" | grep -q .; then
        DETECTED_RUNTIME="c/c++"

    elif [[ -f "$PROJECT_DIR/pom.xml" || -f "$PROJECT_DIR/build.gradle" ]]; then
        DETECTED_RUNTIME="java"

    elif [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
        DETECTED_RUNTIME="rust"

    elif [[ -f "$PROJECT_DIR/go.mod" ]]; then
        DETECTED_RUNTIME="go"
    fi

    # Detect services
    if [[ -f "$PROJECT_DIR/knexfile.js" || -f "$PROJECT_DIR/database.yml" || -f "$PROJECT_DIR/alembic.ini" ]]; then
        DETECTED_SERVICES="$DETECTED_SERVICES postgresql"
    fi

    if grep -Riq "redis" "$PROJECT_DIR" 2>/dev/null; then
        DETECTED_SERVICES="$DETECTED_SERVICES redis"
    fi

    DETECTED_SERVICES=$(echo "$DETECTED_SERVICES" | xargs)

    # Detect ports
    if [[ -f "$PROJECT_DIR/.env" ]];then
        DETECTED_PORTS=$(grep -E '^PORT=[0-9]+' "$PROJECT_DIR/.env" | cut -d '=' -f2 | tr '\n' ',' | sed 's/,$//')
    elif [[ -f "$PROJECT_DIR/.env.example" ]]; then
        DETECTED_PORTS=$(grep -E '^PORT=[0-9]+' "$PROJECT_DIR/.env.example" | cut -d '=' -f2 | tr '\n' ',' | sed 's/,$//')
    fi

    # Detect env variables
    if [[ -f "$PROJECT_DIR/.env.example" ]]; then
        DETECTED_ENV_VARS=$(grep -E '^[A-Z][A-Z0-9_]*=' "$PROJECT_DIR/.env.example" \
            | cut -d '=' -f1\
            | tr '\n' ',' \
            | sed 's/,$//')
    fi

    log_message "INFO" "Fingerprint complete -- detected: $DETECTED_RUNTIME"
}
