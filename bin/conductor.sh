#!/usr/bin/env bash
# The Conductor: macOS Environment Bootstrapper (Modular & Host-Conditional)

set -e # Exit immediately if a command fails

BAREHUB_DIR=$(cd "$(dirname "$0")/.." && pwd)

echo "Starting bareHub Conductor sequence from $BAREHUB_DIR..."

# 1. Handle unified dotfiles profile toggles
PROFILE_FILE="$HOME/.dotfiles.profile"
if [[ ! -f "$PROFILE_FILE" ]]; then
    echo "Generating default ~/.dotfiles.profile..."
    cat << 'EOF' > "$PROFILE_FILE"
# --- Dotfiles Host Profile Configuration ---
# This file is machine-specific and is ignored by Git.

# Enabled features on this host
# Core features: zsh, git
# Optional features: secrets (berglas/gcloud), kitty, rectangle
export DOTFILES_ENABLED_FEATURES=(zsh git)

# The root directory of the bareHub installation
export BAREHUB_DIR="$BAREHUB_DIR"

# GCP secrets configuration (only used if 'secrets' feature is enabled)
export DOTFILES_GCP_PROJECT="__YOUR_GCP_PROJECT__"
export DOTFILES_GCP_BUCKET="__YOUR_GCP_BUCKET__"
EOF
fi

# Load profile configurations
source "$PROFILE_FILE"

# Helper to check if a feature is enabled
is_feature_enabled() {
    local feature="$1"
    for enabled in "${DOTFILES_ENABLED_FEATURES[@]}"; do
        if [[ "$enabled" == "$feature" ]]; then
            return 0
        fi
    done
    return 1
}

# 2. Install Homebrew if missing
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 3. Install Core Dependencies
echo "Installing base packages..."
brew install stow git zsh 
# Installing coreutils provides GNU tools (like 'gmv'), resolving native BSD macOS limitations
brew install coreutils 

# 4. Install Optional Software based on profile toggles
if is_feature_enabled "secrets"; then
    echo "Secrets feature enabled. Installing berglas and Google Cloud SDK..."
    brew install berglas
    if ! command -v gcloud &>/dev/null; then
        echo "google-cloud-sdk is missing. Installing..."
        brew install --cask google-cloud-sdk || echo "Warning: google-cloud-sdk install skipped."
    fi
fi

if is_feature_enabled "themes"; then
    echo "Themes feature enabled. Installing prompt, highlight, and autosuggest tools..."
    brew install starship zsh-syntax-highlighting zsh-autosuggestions eza
    brew install --cask font-jetbrains-mono || echo "Warning: font install skipped."
fi

if is_feature_enabled "audio-dev"; then
    echo "Audio Development Sandbox enabled. Installing compilers & DSP libraries..."
    brew install cmake ninja pkg-config libsndfile portaudio
    if ! command -v rustup &>/dev/null && ! command -v cargo &>/dev/null; then
        echo "Installing rustup via official installer..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path || echo "Warning: rustup install failed."
    fi
fi

if is_feature_enabled "git-crypt"; then
    echo "Git-crypt feature enabled. Installing git-crypt..."
    brew install git-crypt
fi

if is_feature_enabled "kitty"; then
    if ! command -v kitty &>/dev/null; then
        echo "Kitty feature enabled. Installing Kitty terminal..."
        brew install --cask kitty || echo "Warning: kitty install skipped."
    fi
fi

if is_feature_enabled "rectangle"; then
    if [[ ! -d "/Applications/Rectangle.app" ]]; then
        echo "Rectangle feature enabled. Installing Rectangle window manager..."
        brew install --cask rectangle || echo "Warning: rectangle install skipped."
    fi
fi

if is_feature_enabled "rectangle-pro"; then
    if [[ ! -d "/Applications/Rectangle Pro.app" ]]; then
        echo "Rectangle Pro feature enabled. Installing Rectangle Pro..."
        brew install --cask rectangle-pro || echo "Warning: rectangle-pro install skipped."
    fi
fi

# 5. Deploy Dotfiles via Stow
echo "Symlinking configurations..."
cd "$BAREHUB_DIR"

# Backup physical dotfiles to prevent Stow collisions on fresh machines
for file in ".zshrc" ".gitconfig"; do
    if [[ -f "$HOME/$file" && ! -L "$HOME/$file" ]]; then
        echo "Collision detected: Backing up physical $file to ${file}.barehub.bak"
        mv "$HOME/$file" "$HOME/${file}.barehub.bak"
    fi
done



# Core deployments
stow -R -t ~ zsh
stow -R -t ~ git

# Conditional deployments
if is_feature_enabled "kitty"; then
    echo "Stowing kitty config..."
    stow -R -t ~ kitty
fi

if is_feature_enabled "rectangle" || is_feature_enabled "rectangle-pro"; then
    echo "Stowing rectangle / rectangle-pro configs..."
    stow -R -t ~ rectangle
fi

if is_feature_enabled "antigravity"; then
    echo "Antigravity Agent Sync enabled..."
    # Ensure repository folder structure exists
    mkdir -p "$BAREHUB_DIR/antigravity/.gemini/antigravity-cli"

    # Capture existing settings.json if it is a physical file (not a symlink)
    if [[ -f "$HOME/.gemini/antigravity-cli/settings.json" && ! -L "$HOME/.gemini/antigravity-cli/settings.json" ]]; then
        echo "Capturing local settings.json configuration..."
        mv "$HOME/.gemini/antigravity-cli/settings.json" "$BAREHUB_DIR/antigravity/.gemini/antigravity-cli/"
    fi

    # Capture existing keybindings.json if it is a physical file (not a symlink)
    if [[ -f "$HOME/.gemini/antigravity-cli/keybindings.json" && ! -L "$HOME/.gemini/antigravity-cli/keybindings.json" ]]; then
        echo "Capturing local keybindings.json configuration..."
        mv "$HOME/.gemini/antigravity-cli/keybindings.json" "$BAREHUB_DIR/antigravity/.gemini/antigravity-cli/"
    fi

    # Deploy symlinks via Stow
    echo "Stowing Antigravity configurations..."
    stow -R -t ~ antigravity
fi

# Deploy Private Overlays if they exist
if [[ -d "$HOME/git/dotfiles" ]]; then
    echo "Private dotfiles overlay detected. Stowing..."
    cd "$HOME/git/dotfiles"
    
    if [[ -d "zsh-private" ]]; then
        stow -R -t ~ zsh-private
    fi
    if [[ -d "git-private" ]]; then
        stow -R -t ~ git-private
    fi
    
    # Return to bareHub for remaining operations
    cd "$BAREHUB_DIR"
fi


# 6. Bootstrapping LaunchAgent
if is_feature_enabled "launchagent"; then
    echo "Registering background LaunchAgent sync daemon (com.barehub.sync.plist)..."
    # Ensure directory exists before writing
    mkdir -p "$HOME/Library/LaunchAgents"

    # Bootstrap the new com.barehub.sync.plist
    # Unload if already loaded to ensure fresh registration
    launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.barehub.sync.plist" 2>/dev/null || true
    
    # Dynamically instantiate the plist from template, replacing placeholders
    sed -e "s|__HOME__|$HOME|g" -e "s|__BAREHUB_DIR__|$BAREHUB_DIR|g" "$BAREHUB_DIR/templates/com.barehub.sync.plist" > "$HOME/Library/LaunchAgents/com.barehub.sync.plist"
    chmod 644 "$HOME/Library/LaunchAgents/com.barehub.sync.plist"

    # Register/Load the new LaunchAgent
    launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.barehub.sync.plist" 2>/dev/null || true
    echo "LaunchAgent com.barehub.sync.plist registered successfully."
fi

# 7. Finalize
echo "bareHub Conductor sequence complete. Restart terminal to load Zsh."
