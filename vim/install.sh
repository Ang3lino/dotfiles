#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACK_DIR="$HOME/.vim/pack/plugins/start/vim-sensible"
if [ ! -d "$PACK_DIR" ]; then
  git clone --depth 1 https://github.com/tpope/vim-sensible "$PACK_DIR" || echo "WARN: vim-sensible clone failed (SSL/network?). Vim works without it."
fi

ln -sf "$SCRIPT_DIR/.vimrc" "$HOME/.vimrc"

echo "vim ready."
