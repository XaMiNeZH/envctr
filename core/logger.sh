#!/bin/bash
LOG_DIR="${LOG_DIR:-/var/log/envctr}"
LOG_FILE="$LOG_DIR/history.log"


log_message(){
    local TYPE="$1"
    local MSG="$2"

    mkdir -p "$LOG_DIR"

    local TIMESTAMP
    TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")

    local USERNAME
    USERNAME=$(whoami)

    local LINE="$TIMESTAMP : $USERNAME : $TYPE : $MSG"

    echo "$LINE" | tee -a "$LOG_FILE"
}
