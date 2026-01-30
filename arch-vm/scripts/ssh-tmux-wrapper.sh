#!/usr/bin/env bash
# ========================================
# SSH Tmux Wrapper for Arch Linux AgentVM
# ========================================
# Creates unique tmux session per SSH connection
# Optional asciinema recording support

set -euo pipefail

# Configuration
SESSION_PREFIX="ssh-"
DEFAULT_RETENTION_DAYS="${RETENTION_DAYS:-30}"

# Extract client IP from SSH connection
CLIENT_IP="unknown"
if [[ -n "${SSH_CONNECTION:-}" ]]; then
    CLIENT_IP=$(echo "$SSH_CONNECTION" | awk '{print $1}' | tr '.' '-')
fi

# Generate unique session name with timestamp
SESSION_NAME="${SESSION_PREFIX}$(whoami)-$CLIENT_IP-$(date +%Y%m%d-%H%M%S)"

# Check if recording is enabled
RECORDING_ENABLED="${TMUX_RECORD:-false}"
if [[ "$RECORDING_ENABLED" == "true" ]]; then
    # Set up asciinema recording
    RECORD_DIR="$HOME/ssh-recordings"
    mkdir -p "$RECORD_DIR"
    RECORD_FILE="$RECORD_DIR/$SESSION_NAME.cast"
    
    echo "[SSH] Starting recording session: $SESSION_NAME"
    echo "[SSH] Recording to: $RECORD_FILE"
    
    # Start recording with tmux as the command
    exec /usr/bin/asciinema rec \
        --overwrite \
        --command="tmux new-session -A -s \"$SESSION_NAME\"" \
        "$RECORD_FILE"
else
    echo "[SSH] Starting session: $SESSION_NAME"
    exec tmux new-session -A -s "$SESSION_NAME"
fi