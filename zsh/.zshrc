# ponytail: minimal zshrc — starship + 3 plugins via znap
# ponytail: resolve znap location from wherever .zshrc symlink points
ZSHRC_DIR="$(cd "$(dirname "$(readlink -f ~/.zshrc)")" && pwd)"
[[ -r "$ZSHRC_DIR/znap/znap.zsh" ]] || git clone --depth 1 https://github.com/marlonrichert/zsh-snap "$ZSHRC_DIR/znap"
source "$ZSHRC_DIR/znap/znap.zsh"

# PATH — zsh never sources /etc/profile (there is no /etc/zprofile), so unlike
# bash it inherits nothing from ~/.bashrc. Set the user bin dirs explicitly here
# or tools installed under $HOME (opencode, zed, kiro-cli) resolve only in bash.
# typeset -U keeps repeated zsh assignments from stacking duplicate entries.
typeset -U path
path=(
  "$HOME/.opencode/bin"
  "$HOME/.local/bin"
  "$HOME/bin"
  /usr/local/bin
  /usr/local/sbin
  $path
)

# nvm — without this zsh silently falls back to the system /bin/node, which can
# differ from the version bash uses.
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

# Plugins
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting
znap source zsh-users/zsh-completions

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_dups hist_ignore_space

# Show exit code when a command fails — without this, failed commands
# (e.g. `sudo apt install <unknown-pkg>`) can appear to produce no output
# because apt sends errors to stderr, which is easy to miss when the
# prompt redraws. print_exit_value ensures zsh prints the exit status.
setopt print_exit_value

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
else
  PROMPT='%F{blue}%~%f %F{yellow}❯%f '
fi

# Navigation
eval "$(zoxide init zsh)"

[[ -f ~/.secrets ]] && source ~/.secrets
