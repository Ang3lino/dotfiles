#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y || echo "WARN: starship install failed (SSL/network?). Zsh works without it."
fi

if [ ! -d "$SCRIPT_DIR/znap" ]; then
  git clone --depth 1 https://github.com/marlonrichert/zsh-snap "$SCRIPT_DIR/znap" || echo "WARN: znap clone failed. Plugins skipped."
fi

ln -sf "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"

mkdir -p "$HOME/.config"
ln -sf "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"

echo "zsh ready. Restart your shell."
