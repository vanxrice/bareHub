# --- Secrets Integration (GCP / Berglas) ---

# Sourced automatically. Safe conditional loading.

# Check if 'secrets' feature is enabled in ~/.dotfiles.profile
if [[ " ${DOTFILES_ENABLED_FEATURES[@]} " =~ " secrets " ]]; then
    # 1. Ensure berglas is installed
    if command -v berglas &>/dev/null; then
        # 2. Ensure gcloud is installed and actively authenticated to prevent shell hangs
        if command -v gcloud &>/dev/null && gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
            
            # Allow configuring Project ID and Bucket ID locally in ~/.dotfiles.profile
            export PROJECT_ID="${DOTFILES_GCP_PROJECT:-gen-lang-client-0329933647}"
            export BUCKET_ID="${DOTFILES_GCP_BUCKET:-key-secrets}"
            
            # Fetch secrets
            export OPENCLAW_GATEWAY_TOKEN=$(berglas access ${BUCKET_ID}/OPENCLAW_GATEWAY_TOKEN 2>/dev/null)
        fi
    fi
fi
