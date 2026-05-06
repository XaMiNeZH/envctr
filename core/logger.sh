#!/bin/bash
LOG_DIR="${LOG_DIR:-/var/log/envctr}"
LOG_FILE="$LOG_DIR/history.log"

log_message(){
    local TYPE="$1"
    local MSG="$2"

    if ! mkdir -p "$LOG_DIR"; then
        printf 'logger error: cannot create log directory: %s\n' "$LOG_DIR" >&2
        return 1
    fi

    local TIMESTAMP
    TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")

    local USERNAME
    USERNAME=$(whoami)

    local LINE="$TIMESTAMP : $USERNAME : $TYPE : $MSG"

    if ! printf '%s\n' "$LINE" | tee -a "$LOG_FILE"; then
        printf 'logger error: cannot append to log file: %s\n' "$LOG_FILE" >&2
        return 1
    fi
}