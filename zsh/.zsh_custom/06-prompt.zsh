# --- Shell Aesthetics Loader ---

# Sourced automatically. Safe conditional theme initialization.

# Load zsh-syntax-highlighting (checks both Intel /usr/local and Apple Silicon /opt/homebrew)
if [[ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -f "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Load zsh-autosuggestions
if [[ -f "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [[ -f "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Initialize Starship prompt
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
