#!/usr/bin/env bash
# ponytail: OS-aware dotfiles installer
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINIMAL=false
[[ "${1:-}" == "--minimal" ]] && MINIMAL=true

if command -v brew &>/dev/null; then
  if $MINIMAL; then
    brew install tmux neovim fzf zoxide ripgrep fd jq
  else
    brew install tmux starship neovim lazygit fzf zoxide ripgrep fd jq
  fi
elif command -v apt &>/dev/null; then
  sudo apt install -y tmux git neovim fzf zoxide ripgrep fd-find jq
  if ! $MINIMAL; then
    # starship: apt first, curl fallback
    if ! command -v starship &>/dev/null; then
      if apt-cache show starship &>/dev/null 2>&1; then
        sudo apt install -y starship
      else
        curl -sS https://starship.rs/install.sh | sh -s -- -y || echo "WARN: starship install failed (SSL/network?). Install manually."
      fi
    fi
    # lazygit: curl with fallback warning
    if ! command -v lazygit &>/dev/null; then
      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') || true
      if [ -n "$LAZYGIT_VERSION" ]; then
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit && sudo install /tmp/lazygit /usr/local/bin
      else
        echo "WARN: lazygit install failed (SSL/network?). Install manually."
      fi
    fi
  fi
elif command -v dnf &>/dev/null; then
  sudo dnf install -y tmux git neovim fzf zoxide ripgrep fd-find jq
  if ! $MINIMAL; then
    # starship: dnf first, curl fallback
    if ! command -v starship &>/dev/null; then
      if dnf info starship &>/dev/null 2>&1; then
        sudo dnf install -y starship
      else
        curl -sS https://starship.rs/install.sh | sh -s -- -y || echo "WARN: starship install failed (SSL/network?). Install manually."
      fi
    fi
    # lazygit
    if ! command -v lazygit &>/dev/null; then
      sudo dnf copr enable -y atim/lazygit && sudo dnf install -y lazygit || echo "WARN: lazygit install failed. Install manually."
    fi
  fi
fi

# Run sub-installers
"$SCRIPT_DIR/zsh/install.sh"
"$SCRIPT_DIR/tmux/install.sh"
"$SCRIPT_DIR/nvim/install.sh"

echo "Done. Restart your shell."
