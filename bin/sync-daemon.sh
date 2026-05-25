#!/usr/bin/env bash
# bareHub Sync Daemon: Non-Blocking Bidirectional Background Sync

set -e

# Ensure local Tailscale is running and online
if ! command -v tailscale &>/dev/null || ! tailscale status &>/dev/null; then
    echo "Tailscale is not active on this machine. Skipping background sync."
    exit 0
fi

BAREHUB_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$BAREHUB_DIR"

# Ensure remote is configured
if ! git remote get-url origin &>/dev/null; then
    exit 0
fi

REMOTE_URL=$(git config --get remote.origin.url)

# If it is a remote host (SSH), check connectivity before proceeding
if [[ "$REMOTE_URL" =~ @([^:]+): ]]; then
    HOST="${BASH_REMATCH[1]}"
    if ! ping -c 1 -t 2 "$HOST" &>/dev/null; then
        echo "iMac Hub server ($HOST) is unreachable. Skipping background sync."
        exit 0
    fi
# If it is an HTTPS remote, check if we are offline or behind a captive portal
elif [[ "$REMOTE_URL" =~ ^https:// ]]; then
    if ! curl -s --max-time 3 -I "https://github.com" &>/dev/null; then
        echo "Internet unreachable (offline or captive portal). Skipping background sync."
        exit 0
    fi
fi

# Fetch remote status silently (let errors flow to LaunchAgent logs)
git fetch origin main

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)
BASE=$(git merge-base HEAD origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    # Completely in sync
    exit 0
elif [ "$LOCAL" = "$BASE" ]; then
    # Local is behind remote: pull and boot
    echo "Local environment is out of date. Pulling..."
    git pull origin main
    ./bin/conductor.sh
    osascript -e 'display notification "Your configurations have been automatically updated from the bareHub Hub." with title "bareHub Sync" sound name "Glass"'
elif [ "$REMOTE" = "$BASE" ]; then
    # Local is ahead of remote: push to Hub
    echo "Local environment is ahead. Pushing changes..."
    git push origin main
    osascript -e 'display notification "Local environment changes have been quietly pushed to the bareHub Hub." with title "bareHub Sync"'
else
    # Diverged: warn the user to resolve manually
    osascript -e 'display notification "Dotfiles have diverged. Please run git pull/push manually to resolve conflicts." with title "bareHub Sync Warning" sound name "Basso"'
fi
