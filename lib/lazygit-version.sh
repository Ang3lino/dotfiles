#!/usr/bin/env bash
# lib/lazygit-version.sh - print the latest lazygit release tag (no leading "v"),
# or nothing on any failure. Kept out of os/ubuntu.mk because the extraction
# regex contains quote/backslash characters that make mangles via $/# expansion.
set -euo pipefail

curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" 2>/dev/null \
  | grep -Po '"tag_name": "v\K[^"]*' || true
