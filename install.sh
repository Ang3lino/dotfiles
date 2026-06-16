#!/usr/bin/env bash
# ponytail: OS-aware dotfiles installer
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install system deps
if command -v brew &>/dev/null; then
  brew install tmux starship neovim lazygit fzf
elif command -v apt &>/dev/null; then
  sudo apt install -y tmux git neovim fzf
  curl -sS https://starship.rs/install.sh | sh -s -- -y
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf /tmp/lazygit.tar.gz -C /tmp lazygit && sudo install /tmp/lazygit /usr/local/bin
elif command -v dnf &>/dev/null; then
  sudo dnf install -y tmux git neovim fzf
  curl -sS https://starship.rs/install.sh | sh -s -- -y
  sudo dnf copr enable -y atim/lazygit && sudo dnf install -y lazygit
fi

# Run sub-installers
"$SCRIPT_DIR/zsh/install.sh"
"$SCRIPT_DIR/tmux/install.sh"
"$SCRIPT_DIR/nvim/install.sh"

echo "Done. Restart your shell."
