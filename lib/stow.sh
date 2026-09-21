#!/usr/bin/env bash
# Stow one package into $HOME: clean stale links, abort on real files, run stow loudly.
# Usage: lib/stow.sh <zsh|tmux|nvim|opencode|alacritty>
# Self-contained by design: GNU Make 3.81 gives every recipe line its own shell,
# so this must work from any cwd with nothing exported.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pkg="${1-}"

# bash 3.2 ships on macOS and has no associative arrays, so the map is a case.
case "$pkg" in
  zsh)  targets="$HOME/.zshrc
$HOME/.config/starship.toml
$HOME/.markdownlint-cli2.jsonc
$HOME/.markdownlint.json" ;;
  tmux) targets="$HOME/.tmux.conf" ;;
  nvim) targets="$HOME/.config/nvim" ;;
  alacritty) targets="$HOME/.config/alacritty/alacritty.toml" ;;
  opencode) targets="$HOME/.config/opencode/opencode.jsonc
$HOME/.config/opencode/oh-my-openagent.json
$HOME/.config/opencode/oh-my-openagent.bedrock.json
$HOME/.config/opencode/oh-my-openagent.github-copilot.json
$HOME/.config/opencode/oh-my-openagent.mixed.json
$HOME/.config/opencode/oh-my-openagent.opencode-go.json
$HOME/.config/opencode/commands
$HOME/.agents/skills
$HOME/.config/opencode/package.json" ;;
  *) echo "ERROR: unknown package '$pkg'. Expected one of: zsh tmux nvim opencode alacritty" >&2; exit 2 ;;
esac

while IFS= read -r t; do
  if [ -L "$t" ] && [ ! -e "$t" ]; then
    # MUST precede any readlink -f: BSD/macOS readlink -f prints the path but
    # EXITS 1 on a dangling link, and under set -e that kills the script silently.
    echo "Removing broken symlink: $t"
    rm -f "$t"
  elif [ -L "$t" ]; then
    # readlink -f, not plain readlink: stow writes RELATIVE targets that never
    # match an absolute $REPO prefix, and -f also follows the extra hop for
    # oh-my-openagent.json -> oh-my-openagent.<preset>.json.
    resolved="$(readlink -f "$t" 2>/dev/null || true)"
    case "$resolved" in
      "$REPO"/*) ;;
      *) echo "Removing stale symlink: $t -> $resolved"; rm -f "$t" ;;
    esac
  elif [ -e "$t" ]; then
    # Only a blocker when this package actually supplies the file; stow mirrors
    # $HOME under <repo>/<pkg>/. An unmanaged real file stow never touches is fine.
    if [ -e "$REPO/$pkg/${t#$HOME/}" ]; then
      echo "ERROR: $t already exists as a real file or directory." >&2
      echo "       Stowing '$pkg' would overwrite it, so nothing was changed." >&2
      echo "       Inspect it, then move it aside and re-run:" >&2
      echo "" >&2
      echo "         mv \"$t\" \"$t.bak.\$(date +%s)\"" >&2
      echo "" >&2
      exit 1
    fi
  fi
  mkdir -p "$(dirname "$t")"
done <<EOF
$targets
EOF

# Never --adopt: it MOVES $HOME files INTO the repo over tracked content. It has
# already gutted opencode.jsonc once. A blocking real file must fail loudly instead.
# Assign-in-if, not a pipe: a pipe would discard stow's exit status (Bug C).
if ! out="$(stow -d "$REPO" -v --target="$HOME" --restow "$pkg" 2>&1)"; then
  echo "$out" >&2
  echo "ERROR: stow failed for package '$pkg'." >&2
  exit 1
fi
echo "$out" | grep -v "BUG" || true

# Post-stow, opencode only: git with core.symlinks=false checks the tracked
# oh-my-openagent.json symlink out as a text stub naming its preset. Ports install.sh:133-142.
if [ "$pkg" = opencode ]; then
  agent="$HOME/.config/opencode/oh-my-openagent.json"
  # -le 1: a git symlink blob has no trailing newline, so wc -l reports 0, not 1.
  if [ -f "$agent" ] && [ ! -L "$agent" ] && [ "$(wc -l < "$agent")" -le 1 ]; then
    preset="$(tr -d '[:space:]' < "$agent")"
    if [ -n "$preset" ] && [ -f "$REPO/opencode/.config/opencode/$preset" ]; then
      rm -f "$agent"
      ln -s "$REPO/opencode/.config/opencode/$preset" "$agent"
      echo "Fixed oh-my-openagent.json stub -> $preset"
    fi
  fi
fi
