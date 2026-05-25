# --- The Conductor: Core Zsh Entrypoint ---

# 1. Load system environment paths if available
if [[ -f "$HOME/.local/bin/env" ]]; then
    source "$HOME/.local/bin/env"
fi

# 2. Load the unified dotfiles profile toggles
if [[ -f "$HOME/.dotfiles.profile" ]]; then
    source "$HOME/.dotfiles.profile"
fi

# 3. Source all custom modules automatically (alphabetically)
if [[ -d "$HOME/.zsh_custom" ]]; then
    for module in "$HOME/.zsh_custom"/*.zsh(N); do
        source "$module"
    done
fi

# Antigravity CLI binary path configuration
export PATH="$HOME/.local/bin:$PATH"

# 4. Source private custom modules if they exist
if [[ -d "$HOME/.zsh_custom_private" ]]; then
    for module in "$HOME/.zsh_custom_private"/*.zsh(N); do
        source "$module"
    done
fi
