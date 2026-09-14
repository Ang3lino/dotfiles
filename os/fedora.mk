# os/fedora.mk - dnf backend, ported from install.sh:59-78.
# Included by the root Makefile; do not add `include`, a default goal, or a target
# named all/deps/zsh/tmux/nvim/opencode here - the root Makefile owns those.
#
# ~22 lines overlap with os/ubuntu.mk (core package list, starship/awscli curl
# fallbacks). Duplication is accepted deliberately per the plan rather than
# building an apt/dnf abstraction over two package managers.

# curl is listed for the same reason as in os/ubuntu.mk (starship + awscli fetch
# through it). fedora:latest happens to ship curl-minimal, which satisfies this
# as a no-op, but a minimal/container-stripped Fedora may not - do not rely on
# the image. wget is deliberately NOT listed: unlike apt, the terraform path
# here uses `dnf config-manager`, so nothing on this backend calls wget.
PKGS_CORE := stow zsh tmux git neovim fzf zoxide ripgrep fd-find jq unzip curl
PKGS_EXTRA := starship lazygit awscli terraform

.PHONY: deps-install

deps-install:
	sudo -v
	sudo dnf install -y dnf-plugins-core 2>/dev/null || sudo dnf install -y 'dnf5-command(copr)' 'dnf5-command(config-manager)' 2>/dev/null || true
	sudo dnf install -y $(PKGS_CORE)
	if [ -z "$(MINIMAL)" ]; then command -v starship >/dev/null 2>&1 || (curl -sS https://starship.rs/install.sh | sh -s -- -y) || echo "WARN: starship install failed."; fi
	if [ -z "$(MINIMAL)" ]; then command -v lazygit >/dev/null 2>&1 || (sudo dnf copr enable -y atim/lazygit && sudo dnf install -y lazygit) || echo "WARN: lazygit install failed."; fi
	if [ -z "$(MINIMAL)" ]; then command -v aws >/dev/null 2>&1 || (curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && unzip -qo /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install && rm -rf /tmp/awscliv2.zip /tmp/aws) || echo "WARN: AWS CLI install failed."; fi
	# config-manager's flag differs between dnf4 (--add-repo) and dnf5 (addrepo
	# --from-repofile=), same dual-fallback shape as the dnf5-command guard above;
	# this is the config-manager compatibility fallback ported from install.sh:75.
	if [ -z "$(MINIMAL)" ]; then command -v terraform >/dev/null 2>&1 || (sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null || sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo 2>/dev/null || true; sudo dnf install -y terraform) || echo "WARN: terraform install failed."; fi
# ponytail: plain `sudo -v` above, no keepalive loop - install.sh:9-12's
# backgrounded "re-authenticate sudo every 50s while this process is alive"
# loop cannot survive here: each make recipe line is its own shell, so a
# backgrounded watcher tied to that shell's own PID dies the instant the line
# it started on exits - before the next line even runs. Ceiling: a very long
# dnf run may re-prompt for the password. Upgrade path: wrap this whole recipe
# in one `sudo -s` script invoked as a single recipe line if that becomes
# annoying in practice.
