#!/usr/bin/env bash
# ponytail: one-shot neovim/lazyvim setup
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install neovim if missing
if ! command -v nvim &>/dev/null; then
  if command -v brew &>/dev/null; then
    brew install neovim
  elif command -v apt &>/dev/null; then
    sudo apt install -y neovim
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y neovim
  fi
fi

# Backup existing config
if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
fi

# Symlink
mkdir -p "$HOME/.config"
ln -sfn "$SCRIPT_DIR" "$HOME/.config/nvim"

echo "nvim ready. First launch will install plugins automatically."
