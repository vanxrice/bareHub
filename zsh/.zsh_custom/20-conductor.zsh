# --- bareHub Sync Functions ---

# Sourced automatically. Provides Git synchronization utility functions.

sync-barehub() {
    cd ~/git/bareHub
    git add .
    git commit -m "bareHub update: $(date +'%Y-%m-%d %H:%M')"
    git push origin main
    cd - >/dev/null
    echo "bareHub track synchronized."
}

pull-barehub() {
    cd ~/git/bareHub
    git pull origin main
    ./bin/conductor.sh
    cd - >/dev/null
    echo "Environment updated from bareHub."
}
