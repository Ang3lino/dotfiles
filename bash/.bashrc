# Minimal bashrc — zoxide + aliases
# Symlinked to ~/.bashrc by bash/install.sh

# Secrets (never committed)
[[ -f ~/.secrets ]] && source ~/.secrets

# Aliases
alias ll='ls -la'
alias g='git'
alias v='nvim'
alias d='docker'
alias k='kubectl'
alias kgp='kubectl get pods'

# Navigation
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi
