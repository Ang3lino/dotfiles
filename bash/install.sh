#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ln -sf "$SCRIPT_DIR/.bashrc" "$HOME/.bashrc"

echo "bash ready. Restart your shell."
