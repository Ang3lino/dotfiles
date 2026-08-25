#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINIMAL=false
COMPONENTS=()

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

# --- Stow packages ---
# ponytail: stow replaces all manual ln -sf logic
for pkg in zsh tmux nvim opencode; do
  if should_install "$pkg"; then
    stow -v --target="$HOME" --restow "$pkg" 2>&1 | grep -v "BUG" || true
  fi
done

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

if should_install vim; then
  if [ ! -d "$HOME/.vim_runtime" ]; then
    git clone --depth=1 https://github.com/amix/vimrc.git "$HOME/.vim_runtime" || echo "WARN: vimrc clone failed."
  fi
  [ -f "$HOME/.vim_runtime/install_basic_vimrc.sh" ] && sh "$HOME/.vim_runtime/install_basic_vimrc.sh"
fi

if should_install zsh && command -v zsh &>/dev/null && [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

echo "Done. Restart your shell."
