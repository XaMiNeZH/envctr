#!/bin/bash
# Backend stub — records intended backend in lockfile
# Actual environment provisioning is managed externally
BACKEND_NAME="$(basename "$0" .sh)"
source "$(dirname "$0")/../core/logger.sh"
log_message "INFOS" "Backend selected: $BACKEND_NAME -- recorded in lockfile"
exit 0
