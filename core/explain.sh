#!/bin/bash

EXPLAIN_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${EXPLAIN_SCRIPT_DIR}/logger.sh"

MISTRAL_MODEL="${MISTRAL_MODEL:-mistral-small-latest}"
MISTRAL_API_URL="${MISTRAL_API_URL:-https://api.mistral.ai/v1/chat/completions}"

# Explain a drift report with Mistral; returns 110 when explanation is unavailable.
explain_drift() {
    local PAYLOAD
    local RESPONSE
    local EXPLANATION
    local PROMPT

    if [[ -z "${1:-}" ]]; then
        log_message "ERROR" "No drift report content provided"
        return 110
    fi

    if [[ -z "${MISTRAL_API_KEY:-}" ]]; then
        log_message "ERROR" "Mistral API key not set -- set MISTRAL_API_KEY in envctr.conf"
        return 110
    fi

    if ! command -v jq > /dev/null 2>&1; then
        log_message "ERROR" "jq is required for JSON-safe Mistral request/response handling"
        return 110
    fi

    if ! curl -s --max-time 5 "$MISTRAL_API_URL" > /dev/null 2>&1; then
        log_message "ERROR" "Mistral API unreachable"
        return 110
    fi

    PROMPT="You are a developer assistant. Explain this environment drift report in plain language, say what broke, why it matters, and what to fix first. Keep it under 150 words."
    if ! PAYLOAD=$(jq -cn \
        --arg model "$MISTRAL_MODEL" \
        --arg report "$1" \
        --arg prompt "$PROMPT" \
        '{model:$model,messages:[{role:"user",content:($prompt + "\n\n" + $report)}]}'); then
        log_message "ERROR" "Mistral payload build failed"
        return 110
    fi

    if ! RESPONSE=$(curl -fsS --connect-timeout 5 --max-time 30 -X POST "$MISTRAL_API_URL" \
        -H "Authorization: Bearer $MISTRAL_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD"); then
        log_message "ERROR" "Mistral API unreachable"
        return 110
    fi

    if [[ -z "$RESPONSE" ]]; then
        log_message "ERROR" "Mistral returned empty response"
        return 110
    fi

    if ! EXPLANATION=$(printf '%s' "$RESPONSE" | jq -r '.choices[0].message.content // empty' 2> /dev/null); then
        log_message "ERROR" "Mistral returned empty response"
        return 110
    fi

    if [[ -z "$EXPLANATION" ]]; then
        log_message "ERROR" "Mistral returned empty response"
        return 110
    fi

    printf '%s\n' "$EXPLANATION"
    log_message "INFOS" "Mistral explanation received"
    return 0
}
