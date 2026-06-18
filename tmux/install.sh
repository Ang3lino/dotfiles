#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ln -sf "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" || {
    echo "WARN: tpm clone failed (SSL/network?). Tmux works, plugins skipped."
    exit 0
  }
fi

"$HOME/.tmux/plugins/tpm/bin/install_plugins" || echo "WARN: tpm plugin install failed. Run prefix+I inside tmux later."

echo "tmux ready."
