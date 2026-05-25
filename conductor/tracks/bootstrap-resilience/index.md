# Track: Bootstrap Resilience (bootstrap-resilience)

## Objective
Improve the robustness, error-handling, and logging of the bareHub bootstrapper and background sync daemon to prevent silent failures and bootstrapping crashes.

## Status
Completed

## Tasks
- [x] **High**: Implement GNU Stow collision handling in `bin/conductor.sh` to safely backup existing physical dotfiles (e.g., `~/.zshrc`, `~/.gitconfig`) before stowing.
- [x] **High**: Implement explicit error logging for the background `git push` in `bin/sync-daemon.sh` so authentication failures do not fail silently.
- [x] **Medium**: Add a pre-fetch network connectivity check (`curl` timeout) in `bin/sync-daemon.sh` to prevent the script from hanging indefinitely on captive portals or offline networks.
- [x] **Low**: Unify case sensitivity for `.openclaw` paths in `zsh/.zsh_custom/00-env.zsh` to prevent future cross-platform path resolution issues.
