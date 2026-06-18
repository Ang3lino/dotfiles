# ponytail: minimal zshrc — starship + 3 plugins via znap
# Source znap plugin manager
[[ -r ~/dotfiles/zsh/znap/znap.zsh ]] || git clone --depth 1 https://github.com/marlonrichert/zsh-snap ~/dotfiles/zsh/znap
source ~/dotfiles/zsh/znap/znap.zsh

# Plugins
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting
znap source zsh-users/zsh-completions

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_dups hist_ignore_space

# Aliases
alias ll='ls -la'
alias g='git'
alias v='nvim'
alias d='docker'
alias k='kubectl'
alias kgp='kubectl get pods'

# Completions (lazy — only if kubectl exists)
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh)
  compdef k=kubectl
fi

# Prompt
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# Navigation
eval "$(zoxide init zsh)"
