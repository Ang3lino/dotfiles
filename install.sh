#!/usr/bin/env bash
# ponytail: OS-aware dotfiles installer
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINIMAL=false
[[ "${1:-}" == "--minimal" ]] && MINIMAL=true

if command -v brew &>/dev/null; then
  if $MINIMAL; then
    brew install tmux neovim fzf zoxide ripgrep fd jq
  else
    brew install tmux starship neovim lazygit fzf zoxide ripgrep fd jq awscli terraform
  fi
elif command -v apt &>/dev/null; then
  sudo apt install -y zsh tmux git neovim fzf zoxide ripgrep fd-find jq unzip
  if ! $MINIMAL; then
    # starship: apt first, curl fallback
    if ! command -v starship &>/dev/null; then
      if apt-cache show starship &>/dev/null 2>&1; then
        sudo apt install -y starship
      else
        curl -sS https://starship.rs/install.sh | sh -s -- -y || echo "WARN: starship install failed (SSL/network?). Install manually."
      fi
    fi
    # lazygit: curl with fallback warning
    if ! command -v lazygit &>/dev/null; then
      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') || true
      if [ -n "$LAZYGIT_VERSION" ]; then
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit && sudo install /tmp/lazygit /usr/local/bin
      else
        echo "WARN: lazygit install failed (SSL/network?). Install manually."
      fi
    fi
    # aws cli
    if ! command -v aws &>/dev/null; then
      curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
      unzip -qo /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install || echo "WARN: AWS CLI install failed."
      rm -rf /tmp/awscliv2.zip /tmp/aws
    fi
    # terraform
    if ! command -v terraform &>/dev/null; then
      wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
      sudo apt update -qq && sudo apt install -y terraform || echo "WARN: terraform install failed."
    fi
  fi
elif command -v dnf &>/dev/null; then
  sudo dnf install -y zsh tmux git neovim fzf zoxide ripgrep fd-find jq unzip
  if ! $MINIMAL; then
    # starship: dnf first, curl fallback
    if ! command -v starship &>/dev/null; then
      if dnf info starship &>/dev/null 2>&1; then
        sudo dnf install -y starship
      else
        curl -sS https://starship.rs/install.sh | sh -s -- -y || echo "WARN: starship install failed (SSL/network?). Install manually."
      fi
    fi
    # lazygit
    if ! command -v lazygit &>/dev/null; then
      sudo dnf copr enable -y atim/lazygit && sudo dnf install -y lazygit || echo "WARN: lazygit install failed. Install manually."
    fi
    # aws cli
    if ! command -v aws &>/dev/null; then
      curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
      unzip -qo /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install || echo "WARN: AWS CLI install failed."
      rm -rf /tmp/awscliv2.zip /tmp/aws
    fi
    # terraform
    if ! command -v terraform &>/dev/null; then
      sudo dnf install -y dnf-plugins-core
      sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
      sudo dnf install -y terraform || echo "WARN: terraform install failed."
    fi
  fi
fi

# Run sub-installers
"$SCRIPT_DIR/zsh/install.sh"
"$SCRIPT_DIR/tmux/install.sh"
"$SCRIPT_DIR/nvim/install.sh"
"$SCRIPT_DIR/vim/install.sh"
"$SCRIPT_DIR/opencode/install.sh"

if command -v zsh &>/dev/null && [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

echo "Done. Restart your shell."
