#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.config/opencode/commands"
mkdir -p "$HOME/.agents/skills"

ln -sf "$SCRIPT_DIR/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
ln -sf "$SCRIPT_DIR/oh-my-openagent.json" "$HOME/.config/opencode/oh-my-openagent.json"

for cmd in "$SCRIPT_DIR"/commands/*.md; do
  ln -sf "$cmd" "$HOME/.config/opencode/commands/$(basename "$cmd")"
done

for skill in "$SCRIPT_DIR"/skills/*/; do
  skill_name="$(basename "$skill")"
  rm -rf "$HOME/.agents/skills/$skill_name"
  ln -sf "$skill" "$HOME/.agents/skills/$skill_name"
done

if ! command -v cargo &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || echo "WARN: rustup install failed."
  source "$HOME/.cargo/env" 2>/dev/null || true
fi

if command -v cargo &>/dev/null && ! command -v codegraph &>/dev/null; then
  cargo install --git https://github.com/websines/codegraph-mcp.git || echo "WARN: codegraph build failed."
fi

echo "opencode ready."
