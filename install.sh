#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINIMAL=false
COMPONENTS=()

# ponytail: keep sudo alive throughout install — prevents repeated password prompts
if [[ "$(uname)" != "Darwin" ]]; then
  sudo -v
  while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
fi

for arg in "$@"; do
  case "$arg" in
    --minimal) MINIMAL=true ;;
    *) COMPONENTS+=("$arg") ;;
  esac
done

should_install() { [[ ${#COMPONENTS[@]} -eq 0 ]] || [[ " ${COMPONENTS[*]} " == *" $1 "* ]]; }

# --- System packages ---
if should_install deps; then
# ponytail: brew only on macOS — apt/dnf preferred on Linux even if brew exists
if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
  brew install stow
  if $MINIMAL; then
    brew install tmux neovim fzf zoxide ripgrep fd jq
  else
    brew install tmux starship neovim lazygit fzf zoxide ripgrep fd jq awscli terraform
  fi
elif command -v apt &>/dev/null; then
  sudo apt install -y stow zsh tmux git neovim fzf zoxide ripgrep fd-find jq unzip
  if ! $MINIMAL; then
    if ! command -v starship &>/dev/null; then
      curl -sS https://starship.rs/install.sh | sh -s -- -y || echo "WARN: starship install failed."
    fi
    if ! command -v lazygit &>/dev/null; then
      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') || true
      if [ -n "$LAZYGIT_VERSION" ]; then
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit && sudo install /tmp/lazygit /usr/local/bin
      else
        echo "WARN: lazygit install failed."
      fi
    fi
    if ! command -v aws &>/dev/null; then
      curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
      unzip -qo /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install || echo "WARN: AWS CLI install failed."
      rm -rf /tmp/awscliv2.zip /tmp/aws
    fi
    if ! command -v terraform &>/dev/null; then
      wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
      sudo apt update -qq && sudo apt install -y terraform || echo "WARN: terraform install failed."
    fi
  fi
elif command -v dnf &>/dev/null; then
  sudo dnf install -y dnf-plugins-core 2>/dev/null || sudo dnf install -y 'dnf5-command(copr)' 'dnf5-command(config-manager)' 2>/dev/null || true
  sudo dnf install -y stow zsh tmux git neovim fzf zoxide ripgrep fd-find jq unzip
  if ! $MINIMAL; then
    if ! command -v starship &>/dev/null; then
      curl -sS https://starship.rs/install.sh | sh -s -- -y || echo "WARN: starship install failed."
    fi
    if ! command -v lazygit &>/dev/null; then
      sudo dnf copr enable -y atim/lazygit && sudo dnf install -y lazygit || echo "WARN: lazygit install failed."
    fi
    if ! command -v aws &>/dev/null; then
      curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
      unzip -qo /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install || echo "WARN: AWS CLI install failed."
      rm -rf /tmp/awscliv2.zip /tmp/aws
    fi
    if ! command -v terraform &>/dev/null; then
      sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null || sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null || true
      sudo dnf install -y terraform || echo "WARN: terraform install failed."
    fi
  fi
fi
fi

# --- Pre-stow cleanup: remove stale symlinks and blocking dirs ---
for f in "$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/starship.toml" "$HOME/.config/nvim" \
         "$HOME/.config/opencode/opencode.jsonc" "$HOME/.config/opencode/oh-my-openagent.json"; do
  if [ -L "$f" ]; then
    # readlink -f (not plain readlink): stow writes RELATIVE targets like
    # ../../Documents/repos/dotfiles/..., which never match an absolute
    # $SCRIPT_DIR prefix. Plain readlink made this guard delete every link on
    # every run. -f resolves to an absolute path, and also follows the extra
    # hop for oh-my-openagent.json -> oh-my-openagent.<profile>.json.
    target="$(readlink -f "$f")"
    case "$target" in
      "$SCRIPT_DIR"*) ;;
      *) echo "Removing stale symlink: $f -> $target"; rm -f "$f" ;;
    esac
  fi
done
for d in "$HOME/.agents/skills" "$HOME/.config/opencode/commands"; do
  [ -d "$d" ] && [ ! -L "$d" ] && echo "Removing blocking dir: $d" && rm -rf "$d"
done
mkdir -p "$HOME/.config/opencode" "$HOME/.agents"

# --- Stow packages ---
for pkg in zsh tmux nvim opencode; do
  if should_install "$pkg"; then
    stow -v --target="$HOME" --restow "$pkg" 2>&1 | grep -v "BUG" || true
  fi
done
# NOTE: --adopt is deliberately NOT used. man stow: "This behaviour is
# specifically intended to alter the contents of your stow directory." When a
# target is a plain file, stow MOVES it into the repo, overwriting the tracked
# version. It silently gutted opencode.jsonc once (dropped the whole plugin
# array, so oh-my-openagent never loaded) and would also flatten the
# oh-my-openagent.json -> <profile> symlink back into a plain file.
# If a real file blocks a link, stow now fails loudly instead. Resolve it by
# hand: inspect the file, then delete it once you've confirmed the repo copy.

# --- Fix oh-my-openagent.json if git checked it out as a stub (core.symlinks=false) ---
_agent="$HOME/.config/opencode/oh-my-openagent.json"
if [ -f "$_agent" ] && [ ! -L "$_agent" ] && [ "$(wc -l < "$_agent")" -eq 1 ]; then
  _target="$(cat "$_agent" | tr -d '[:space:]')"
  if [ -f "$SCRIPT_DIR/opencode/.config/opencode/$_target" ]; then
    rm -f "$_agent"
    ln -s "$SCRIPT_DIR/opencode/.config/opencode/$_target" "$_agent"
    echo "Fixed oh-my-openagent.json stub -> $_target"
  fi
fi

# --- Post-stow bootstrap (plugins that need cloning) ---
if should_install zsh; then
  if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y || echo "WARN: starship install failed."
  fi
  if [ ! -d "$SCRIPT_DIR/zsh/znap" ]; then
    git clone --depth 1 https://github.com/marlonrichert/zsh-snap "$SCRIPT_DIR/zsh/znap" || echo "WARN: znap clone failed."
  fi
fi

if should_install tmux; then
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" || echo "WARN: tpm clone failed."
  fi
  "$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || echo "WARN: tpm plugins skipped. Run prefix+I inside tmux."
fi

if should_install opencode; then
  if command -v npm &>/dev/null; then
    command -v opencode &>/dev/null || npm install -g opencode-ai || echo "WARN: opencode install failed."
    # Plugins listed in opencode.jsonc are resolved from this local node_modules.
    [ -d "$HOME/.config/opencode/node_modules" ] || \
      (cd "$HOME/.config/opencode" && npm install --prefer-offline) || echo "WARN: opencode plugin install failed."
  else
    echo "WARN: npm not found - skip opencode install. Install Node.js and re-run."
  fi
fi

if should_install zsh && command -v zsh &>/dev/null; then
  # $SHELL is unreliable: /etc/bashrc hardcodes SHELL=/bin/bash. Read the real
  # login shell from passwd instead.
  login_shell="$(getent passwd "$USER" | cut -d: -f7)"
  [ "$login_shell" != "$(command -v zsh)" ] && chsh -s "$(command -v zsh)"
fi

echo "Done. Restart your shell."
