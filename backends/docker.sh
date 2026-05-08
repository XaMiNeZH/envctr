#!/bin/bash
BACKEND_NAME="$(basename "$0" .sh)"
LOGGER_PATH="$(dirname "$0")/../core/logger.sh"

if ! source "$LOGGER_PATH"; then
    echo "ERROR: missing logger: $LOGGER_PATH" >&2
    exit 112
fi

if ! log_message "INFOS" "Backend selected: $BACKEND_NAME -- recorded in lockfile"; then
    exit 107
fi

exit 0