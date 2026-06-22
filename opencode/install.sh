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

echo "opencode ready."
