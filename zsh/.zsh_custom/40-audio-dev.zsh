# --- Audio & DSP Development Sandbox ---

# Sourced automatically. Safe conditional settings.

if [[ " ${DOTFILES_ENABLED_FEATURES[@]} " =~ " audio-dev " ]]; then
    # Compiler Optimizations for Local Audio DSP builds (Apple Silicon / Intel optimized)
    if [[ "$(uname -m)" == "arm64" ]]; then
        export CFLAGS="-mcpu=apple-m1 -O3 -ffast-math"
        export CXXFLAGS="-mcpu=apple-m1 -O3 -ffast-math"
    else
        export CFLAGS="-march=native -O3 -ffast-math"
        export CXXFLAGS="-march=native -O3 -ffast-math"
    fi
    
    # Common DSP Dev Environment Variables
    export RUST_BACKTRACE=1
    
    # Add cargo bin to path if available
    if [[ -d "$HOME/.cargo/bin" ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
fi
