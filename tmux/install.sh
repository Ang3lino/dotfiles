#!/usr/bin/env bash
# ponytail: one-shot tmux setup — works on macOS, Linux, devcontainers, codespaces
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install tpm
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Symlink config
ln -sf "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"

# Install plugins headlessly
"$HOME/.tmux/plugins/tpm/bin/install_plugins"

echo "tmux ready."
