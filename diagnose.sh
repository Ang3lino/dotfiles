#!/usr/bin/env bash
# Run on the target machine, pushes diagnostics for remote debugging
set -uo pipefail

OUT="/tmp/dotfiles-diag-$(date +%Y%m%d-%H%M%S).md"

{
echo "# Dotfiles Diagnostics"
echo "- Date: $(date)"
echo "- OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2)"
echo "- Kernel: $(uname -a)"
echo "- Shell: $SHELL"
echo "- User: $USER"
echo "- Home: $HOME"
echo ""

echo "## Package managers"
for pm in brew apt dnf pacman; do
  printf -- "- %s: %s\n" "$pm" "$(command -v $pm 2>/dev/null || echo 'not found')"
done
echo ""

echo "## Required binaries"
for bin in zsh tmux git nvim stow fzf zoxide rg fd starship lazygit aws terraform gh curl wget python3 sqlite3; do
  printf -- "- %-12s %s\n" "$bin:" "$(command -v $bin 2>/dev/null && $bin --version 2>/dev/null | head -1 || echo 'NOT INSTALLED')"
done
echo ""

echo "## Stow symlinks"
for f in ~/.zshrc ~/.tmux.conf ~/.config/starship.toml ~/.config/nvim ~/.config/opencode/opencode.jsonc ~/.agents/skills; do
  if [ -L "$f" ]; then
    printf -- "- %-40s -> %s\n" "$f" "$(readlink -f "$f")"
  elif [ -e "$f" ]; then
    printf -- "- %-40s EXISTS (not a symlink!)\n" "$f"
  else
    printf -- "- %-40s MISSING\n" "$f"
  fi
done
echo ""

echo "## Dotfiles repo"
if [ -d ~/dotfiles ]; then
  echo "- Path: ~/dotfiles"
  echo "- Branch: $(cd ~/dotfiles && git branch --show-current 2>/dev/null)"
  echo "- Last commit: $(cd ~/dotfiles && git log --oneline -1 2>/dev/null)"
  echo "- Stow packages:"
  for pkg in zsh tmux nvim opencode; do
    echo "  - $pkg/: $(ls -1 ~/dotfiles/$pkg/ 2>/dev/null | tr '\n' ' ' || echo 'MISSING')"
  done
else
  echo "- ~/dotfiles NOT FOUND"
  # Check other locations
  for d in ~/Documents/repos/dotfiles ~/.dotfiles; do
    [ -d "$d" ] && echo "- Found at: $d"
  done
fi
echo ""

echo "## Zsh status"
echo "- Default shell: $SHELL"
echo "- /etc/shells:"
grep zsh /etc/shells 2>/dev/null || echo "  zsh not in /etc/shells"
echo "- znap:"
[ -d ~/dotfiles/zsh/znap ] && echo "  installed" || echo "  MISSING"
echo ""

echo "## Tmux status"
echo "- tpm:"
[ -d ~/.tmux/plugins/tpm ] && echo "  installed" || echo "  MISSING"
echo "- config:"
[ -f ~/.tmux.conf ] || [ -L ~/.tmux.conf ] && cat ~/.tmux.conf | head -3 || echo "  NO CONFIG"
echo ""

echo "## Starship status"
if command -v starship &>/dev/null; then
  echo "- installed: $(starship --version 2>&1 | head -1)"
  [ -f ~/.config/starship.toml ] && echo "- config: present" || echo "- config: MISSING"
else
  echo "- NOT INSTALLED"
fi
echo ""

echo "## Login shell PATH parity"
# $SHELL is unreliable: /etc/bashrc unconditionally sets SHELL=/bin/bash, so a
# bash subshell launched from zsh reports the wrong shell. Installers that key
# off $SHELL then write their PATH export to the wrong rc file. Probe the real
# login shell from passwd, in a clean env so nothing leaks in from this script.
# ponytail: getent is glibc-only; macOS falls back to dscl, then $SHELL.
LOGIN_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)"
[ -z "$LOGIN_SHELL" ] && LOGIN_SHELL="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
[ -z "$LOGIN_SHELL" ] && LOGIN_SHELL="$SHELL"
echo "- passwd login shell: ${LOGIN_SHELL:-unknown}"
echo "- \$SHELL (may be stale): $SHELL"
[ "$LOGIN_SHELL" != "$SHELL" ] && echo "  NOTE: \$SHELL disagrees with passwd; trust passwd"
if [ -x "$LOGIN_SHELL" ]; then
  echo "- resolved in a clean login shell:"
  for bin in opencode node npm zed starship zoxide; do
    found="$(env -i HOME="$HOME" USER="$USER" TERM=dumb "$LOGIN_SHELL" -lic \
      "command -v $bin" 2>/dev/null | tr -d '\r')"
    printf -- "  - %-10s %s\n" "$bin:" "${found:-NOT ON PATH}"
  done
  echo "- clean login PATH:"
  env -i HOME="$HOME" USER="$USER" TERM=dumb "$LOGIN_SHELL" -lic 'print -l $path' \
    2>/dev/null | sed 's/^/  - /'
else
  echo "- cannot execute login shell, skipping"
fi
echo ""

echo "## OpenCode status"
command -v opencode &>/dev/null && echo "- binary: $(which opencode)" || echo "- binary: NOT INSTALLED"
echo "  (above reflects THIS shell only; see PATH parity section for login shell)"
[ -f ~/.config/opencode/opencode.jsonc ] && echo "- config: present" || echo "- config: MISSING"
[ -f ~/.config/opencode/oh-my-openagent.json ] && echo "- oh-my-openagent: present" || echo "- oh-my-openagent: MISSING"
echo ""

echo "## gh auth"
gh auth status 2>&1 || echo "- gh not authenticated"
echo ""

echo "## Errors from last install attempt"
[ -f ~/dotfiles/minimal.log ] && tail -50 ~/dotfiles/minimal.log || echo "- no install log found"

} > "$OUT" 2>&1

echo "Diagnostics saved to: $OUT"
echo ""
cat "$OUT"
