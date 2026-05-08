#!/bin/bash

if [[ -f "core/logger.sh" ]]; then
    source "core/logger.sh"
else
    source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
fi

MISTRAL_MODEL="${MISTRAL_MODEL:-mistral-small-latest}"

explain_drift() {
    local PAYLOAD
    local RESPONSE
    local EXPLANATION

    if [[ -z "${MISTRAL_API_KEY:-}" ]]; then
        log_message "ERROR" "Mistral API key not set -- set MISTRAL_API_KEY in envctr.conf"
        return 110
    fi

    if ! curl -s --max-time 5 "https://api.mistral.ai" > /dev/null 2>&1; then
        log_message "ERROR" "Mistral API unreachable"
        return 110
    fi

    PAYLOAD=$(printf '{"model":"%s","messages":[{"role":"user","content":"You are a developer assistant. Explain this environment drift report in plain language, say what broke, why it matters, and what to fix first. Keep it under 150 words.\n\n%s"}]}' "$MISTRAL_MODEL" "$1")

    RESPONSE=$(curl -s -X POST "https://api.mistral.ai/v1/chat/completions" \
        -H "Authorization: Bearer $MISTRAL_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD")

    EXPLANATION=$(echo "$RESPONSE" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//')

    if [[ -z "$EXPLANATION" ]]; then
        log_message "ERROR" "Mistral returned empty response"
        return 110
    fi

    printf '%s\n' "$EXPLANATION"
    log_message "INFOS" "Mistral explanation received"
    return 0
}
