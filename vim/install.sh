#!/usr/bin/env bash
set -e

git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime 2>/dev/null || {
  if [ -d ~/.vim_runtime ]; then
    echo "vim_runtime already installed."
  else
    echo "WARN: vimrc clone failed (SSL/network?). Vim works without it."
    exit 0
  fi
}

sh ~/.vim_runtime/install_basic_vimrc.sh

echo "vim ready."
