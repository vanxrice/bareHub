# bareHub System Conductor Track

This repository serves as the master orchestration protocol for configuring and synchronizing macOS environments using Git and GNU Stow.

### Rationale: Stow vs Chezmoi
If the goal is to seamlessly mirror the environment of an M3 Max MacBook Pro to another Mac with minimal overhead, **GNU Stow** is the most elegant solution. It simply creates symbolic links from the Git repository directly into the home folder, assuming target environments are mostly identical.

### Security Architecture: Berglas vs Git-Crypt
To keep this repository ready for public open-sourcing while maintaining strict local security, we implement a hybrid, "defense-in-depth" secrets paradigm:
1. **Berglas (Dynamic Cloud Secrets)**: Used for highly sensitive, frequently rotating API credentials and tokens (e.g. `OPENCLAW_GATEWAY_TOKEN`). These are stored completely outside of Git and retrieved dynamically at shell startup via Google Cloud KMS. They can be revoked instantly by disabling a machine's GCP IAM access.
2. **Git-Crypt (Static File-Level Encryption)**: Used for structured configurations that must exist as physical files in the home folder but contain private information (e.g. SSH configs, or active license identifiers like `com.knollsoft.RectanglePro.plist`). These are encrypted symmetrically before being committed to Git and decrypted transparently on local checkouts.
3. **Private Overlay Repositories**: Proprietary file system paths, internal tooling aliases (like `antigravity`), and private `.gitconfig.local` credentials are not committed to `bareHub`. Instead, `conductor.sh` supports a secondary Stow pass from a completely isolated repository configured via `$DOTFILES_OVERLAY_DIR` (default: `~/git/dotfiles`).

### Directory Structure
```text
~/git/bareHub/
├── zsh/
│   ├── .zshrc
│   └── .zsh_custom/
├── kitty/
│   └── .config/kitty/kitty.conf
├── rectangle/
│   └── .config/Rectangle/RectangleConfig.json
├── templates/
│   └── com.barehub.sync.plist
└── bin/
    ├── conductor.sh
    └── sync-daemon.sh
```
