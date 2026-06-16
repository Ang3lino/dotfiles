#!/usr/bin/env bash
# ponytail: OS-aware dotfiles installer
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install system deps
if command -v brew &>/dev/null; then
  brew install tmux starship
elif command -v apt &>/dev/null; then
  sudo apt install -y tmux git
  curl -sS https://starship.rs/install.sh | sh -s -- -y
elif command -v dnf &>/dev/null; then
  sudo dnf install -y tmux git
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Run sub-installers
"$SCRIPT_DIR/zsh/install.sh"
"$SCRIPT_DIR/tmux/install.sh"

echo "Done. Restart your shell."
