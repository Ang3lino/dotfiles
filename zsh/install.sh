#!/usr/bin/env bash
# ponytail: one-shot zsh setup — works on macOS, Linux, devcontainers, codespaces
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install starship if missing
if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Install znap if missing
if [ ! -d "$SCRIPT_DIR/znap" ]; then
  git clone --depth 1 https://github.com/marlonrichert/zsh-snap "$SCRIPT_DIR/znap"
fi

# Symlink zshrc
ln -sf "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

# Symlink starship config
mkdir -p "$HOME/.config"
ln -sf "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"

echo "zsh ready. Restart your shell."
