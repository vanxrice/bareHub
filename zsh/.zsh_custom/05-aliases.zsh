# --- Public Shell Aliases ---

# Sourced automatically. Safe, universal aliases.

# Directory listings (with macOS/BSD ls color compatibility support)
if ls --color &>/dev/null; then
    # GNU ls
    alias ls='ls --color=auto'
else
    # macOS/BSD ls
    alias ls='ls -G'
fi

alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Colorized search patterns
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
