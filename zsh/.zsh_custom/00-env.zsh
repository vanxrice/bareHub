# --- Core Environment & Paths ---

# Sourced automatically. Safe variables only.
export PATH="$HOME/scripts:$PATH"

# Pyenv / Python setup
if command -v pyenv &>/dev/null; then
    export CLOUDSDK_PYTHON="$(pyenv root)/versions/3.12.11/bin/python"
fi

# Tooling Paths
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# OpenClaw completions & utility
if [[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]]; then
    source "$HOME/.openclaw/completions/openclaw.zsh"
fi

alias oc-refresh='$HOME/openClaw/scripts/refresh-gateway-token.sh'

# Local bin path
export PATH="$HOME/.local/bin:$PATH"
