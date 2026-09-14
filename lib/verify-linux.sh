#!/usr/bin/env bash
# lib/verify-linux.sh - run `make all` for REAL inside throwaway Ubuntu and Fedora
# containers. Linux is the one path this repo cannot exercise on a macOS dev host,
# so os/ubuntu.mk and os/fedora.mk are executed here, never merely static-checked.
#
# The repo is mounted READ-ONLY and copied to a writable path INSIDE the container.
# A container must never be able to modify the developer's working tree.
#
# Usage:
#   lib/verify-linux.sh                    # ubuntu + fedora + the bootstrap probe
#   lib/verify-linux.sh ubuntu             # one distro
#   lib/verify-linux.sh bootstrap          # only the no-make manual-QA probe
#   TIMEOUT=1800 lib/verify-linux.sh       # raise the per-container hard timeout
#   DOCKER=/path/to/docker lib/verify-linux.sh
#
# Exit 0 only when every requested check PASSES.

# Deliberately NOT `set -e`: a failing container is a RESULT to record, not a
# reason to abort before the logs and the cleanup run.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE="$REPO/.omo/evidence/install-makefile-refactor"
# Hard per-container bound. This host has broken IPv6 (AAAA-first lookups stall
# ~127s each), so apt/dnf/curl can hang; report BLOCKED instead of hanging forever.
TIMEOUT="${TIMEOUT:-1200}"
NAME_PREFIX="omo-dotfiles-gate"

DOCKER="${DOCKER:-$(command -v docker 2>/dev/null || true)}"
# Rancher Desktop installs docker here and does not always export it on PATH.
if [ -z "$DOCKER" ] && [ -x "$HOME/.rd/bin/docker" ]; then DOCKER="$HOME/.rd/bin/docker"; fi
if [ -z "$DOCKER" ]; then
  echo "ERROR: docker not found. Install Docker or Rancher Desktop, or set DOCKER=/path/to/docker." >&2
  exit 2
fi

tmp="$(mktemp -d)"
# Fresh container per run (--rm), so no cached state can mask a failure; the trap
# is the belt-and-braces for an interrupted run leaving an orphan behind.
cleanup() {
  local leftovers
  leftovers="$("$DOCKER" ps -aq --filter "name=$NAME_PREFIX" 2>/dev/null)"
  [ -n "$leftovers" ] && "$DOCKER" rm -f $leftovers >/dev/null 2>&1
  rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

mkdir -p "$EVIDENCE"

# ---------------------------------------------------------------------------
# The in-container gate. Quoted heredoc: nothing here is expanded by the host.
# Args: $1 = apt|dnf   $2 = full|bootstrap
# ---------------------------------------------------------------------------
cat > "$tmp/gate.sh" <<'GATE'
#!/usr/bin/env bash
set -uo pipefail
pm="$1"; mode="$2"
fail=0

hr() { echo; echo "=== $* ==="; }

hr "[1] image identity"
grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release
echo "uname: $(uname -srm)"
echo "HOME=$HOME  USER=${USER:-<unset>}  whoami=$(whoami)  cwd=$(pwd)"
echo "mode=$mode  pm=$pm"

hr "[2] bootstrap prerequisites in the STOCK image (evidence for the documented 'make' prerequisite)"
for c in make stow git sudo curl tar; do
  if command -v "$c" >/dev/null 2>&1; then echo "PRESENT: $c -> $(command -v "$c")"; else echo "ABSENT : $c"; fi
done

if [ "$mode" = bootstrap ]; then
  hr "[3] BOOTSTRAP PROBE - deliberately NOT installing make"
  echo "This captures exactly what a user on a stock image sees when they follow"
  echo "the README and run 'make'. Copying the repo needs no package."
# tar, not `cp -a`: the host worktree carries a live unix socket at
# .codegraph/daemon.sock and cp -a aborts on it. .codegraph/ and .omo/ are
# host-local artifacts (both gitignored) that `make all` never reads, so the
# copy is what a fresh `git clone` would give you, minus nothing that matters.
mkdir -p "$HOME/df"
if ! tar -C /dotfiles --exclude=./.codegraph --exclude=./.omo -cf - . | tar -C "$HOME/df" -xf -; then
  echo "GATE-ERROR: repo copy failed"; exit 21
fi
  cd "$HOME/df" || exit 21
  echo "--- user runs: make all ---"
  make all; rc=$?
  echo "--- observable exit code: $rc ---"
  echo "--- user runs: make (bare) ---"
  make; rc2=$?
  echo "--- observable exit code: $rc2 ---"
  echo "--- fallback still on disk until todo 11: ---"
  ls -l install.sh 2>&1 | sed 's/^/    /'
  echo
  echo "--- GRADING ---"
  echo "QA criterion: the failure must name 'make' as a missing PREREQUISITE with"
  echo "guidance, not die with a bare 'command not found'."
  if make all 2>&1 | grep -qiE 'prerequisite|apt install make|dnf install make|xcode-select'; then
    echo "BOOTSTRAP-PASS: the failure text carries actionable guidance."
  else
    echo "BOOTSTRAP-FINDING: the observable is a BARE 'make: command not found' (exit 127)."
    echo "  It names the binary but offers NO install guidance."
    echo "  This is NOT fixable in the Makefile: make cannot print anything when make"
    echo "  itself is the missing binary. The guidance can therefore only live in"
    echo "  README.md / AGENTS.md - which is precisely what todo 12 mandates."
    echo "  => This log is the EVIDENCE FOR todo 12, not a pass of it."
  fi
  exit 0
fi

hr "[3] install bootstrap prerequisites the stock image LACKS (make git sudo)"
if [ "$pm" = apt ]; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq && apt-get install -y -qq make git sudo
else
  dnf install -y -q make git sudo
fi
brc=$?
echo "bootstrap install exit=$brc"
[ "$brc" -eq 0 ] || { echo "GATE-ERROR: bootstrap install failed - BLOCKED, not a Makefile failure"; exit 20; }
for c in make git sudo; do echo "now: $c -> $(command -v "$c" || echo STILL-MISSING)"; done
echo "make version: $(make --version | head -1)"

hr "[4] copy the repo OUT of the read-only mount (host worktree must stay untouchable)"
mount | grep -E ' /dotfiles ' | sed 's/^/    /'
echo "-- definitive proof the host worktree is unreachable: write probe against /dotfiles --"
if touch /dotfiles/.container-write-probe 2>&1 | sed 's/^/    /'; then
  echo "RO-FAIL: /dotfiles is WRITABLE - the container can modify the developer's worktree"; rm -f /dotfiles/.container-write-probe; fail=1
else
  echo "RO-OK: /dotfiles rejected the write (read-only mount)"
fi
  mkdir -p "$HOME/df"
  tar -C /dotfiles --exclude=./.codegraph --exclude=./.omo -cf - . | tar -C "$HOME/df" -xf - || { echo "GATE-ERROR: repo copy failed"; exit 21; }
cd "$HOME/df" || exit 21
echo "copied to: $(pwd)"
echo "writable check: $(touch "$HOME/df/.writeprobe" && echo yes || echo no)"; rm -f "$HOME/df/.writeprobe"
echo "repo symlink preserved by the copy: $(ls -l opencode/.config/opencode/oh-my-openagent.json | sed 's/.*oh-my/oh-my/')"

hr "[5] HOME is clean before anything runs"
for p in "$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/nvim" "$HOME/.config/starship.toml" "$HOME/znap" "$HOME/zsh-users"; do
  if [ -e "$p" ] || [ -L "$p" ]; then echo "PRE-EXISTS: $p"; else echo "clean: $p"; fi
done

hr "[6] make all - RUN 1"
t0=$(date +%s)
make all 2>&1 | tee /tmp/run1.log
rc1=${PIPESTATUS[0]}
t1=$(date +%s)
echo "EXIT-RUN1=$rc1   elapsed=$((t1-t0))s"

hr "[7] anti-false-pass: did the PACKAGES really install?"
echo "(exit 0 from a run that printed WARNs and skipped everything is a FALSE PASS)"
for c in stow zsh tmux git nvim fzf zoxide rg jq unzip; do
  printf '  %-8s %s\n' "$c" "$(command -v "$c" 2>/dev/null || echo MISSING)"
done
for c in stow zsh tmux nvim; do
  command -v "$c" >/dev/null 2>&1 || { echo "PKG-FAIL: core package '$c' is NOT installed - deps did not really run"; fail=1; }
done

hr "[8] anti-false-pass: did STOW really run? verbatim LINK: lines from run 1"
if grep -E '^(LINK|UNLINK):' /tmp/run1.log; then :; else
  echo "STOW-FAIL: run 1 emitted NO 'LINK:' lines - stow did not link anything"; fail=1
fi

hr "[9] LINK ASSERTIONS - this, not the exit code, is the gate"
for p in "$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/nvim" "$HOME/.config/starship.toml"; do
  if [ -L "$p" ]; then
    r="$(readlink -f "$p" 2>/dev/null)"
    if [ -e "$p" ] && [ -n "$r" ]; then echo "LINK-OK   $p -> $(readlink "$p")   [resolves: $r]"
    else echo "LINK-FAIL $p is a DANGLING symlink -> $(readlink "$p")"; fail=1; fi
  else
    echo "LINK-FAIL $p is not a symlink: $(ls -ld "$p" 2>/dev/null || echo MISSING)"; fail=1
  fi
done

hr "[10] TODO-16 ASSERTION on a clean HOME - zsh/.stow-local-ignore must suppress the vendored trees"
echo "(never demonstrated on the macOS host: before/after dry-runs there were identical)"
for p in "$HOME/znap" "$HOME/zsh-users"; do
  if [ -e "$p" ] || [ -L "$p" ]; then
    echo "TODO16-FAIL: $p EXISTS -> $(ls -ld "$p")"; echo "             => todo 16's .stow-local-ignore fix does NOT work."; fail=1
  else
    echo "TODO16-OK: $p absent"
  fi
done
echo "-- stow dry-run must mention neither tree --"
stow -d "$HOME/df" -n -v --target="$HOME" --restow zsh 2>&1 | grep -Ei 'znap|zsh-users' && { echo "TODO16-FAIL: dry-run still references a vendored tree"; fail=1; } || echo "TODO16-OK: dry-run references neither znap nor zsh-users"
echo "-- and the trees must still exist IN THE REPO (nothing destroyed) --"
for d in "$HOME/df/zsh/znap" "$HOME/df/zsh/zsh-users"; do
  echo "  $d: $( [ -d "$d" ] && echo "present, $(find "$d" | wc -l) entries" || echo MISSING )"
done

hr "[11] lib/lazygit-version.sh HAPPY PATH (GNU grep -Po; BSD grep on macOS cannot run this)"
echo "grep -P support: $(echo v1.2.3 | grep -Po 'v\K[0-9.]+' 2>&1 || echo 'NO -P SUPPORT')"
lgout="$(bash "$HOME/df/lib/lazygit-version.sh" 2>&1)"; lgrc=$?
echo "exit=$lgrc  output='$lgout'"
if [ "$lgrc" -ne 0 ]; then
  echo "LAZYGIT-FAIL: helper exited non-zero ($lgrc) - it must never fail the target"; fail=1
elif echo "$lgout" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "LAZYGIT-OK: real version string returned (happy path exercised)"
else
  echo "LAZYGIT-OK: empty/no version -> the WARN path is what runs; helper still exited 0"
fi
echo "lazygit on PATH after deps: $(command -v lazygit || echo 'absent (WARN path)')"
grep -n 'lazygit' /tmp/run1.log | head -5

hr "[12] chsh logic - the getent passwd (non-Darwin) branch, untestable on macOS"
echo "raw: getent passwd \"\$USER\" | cut -d: -f7  ->  '$(getent passwd "${USER:-$(whoami)}" | cut -d: -f7)'"
echo "with USER unset (docker default, no login(1)): '$(env -u USER bash -c 'getent passwd "$USER" | cut -d: -f7' 2>/dev/null)'  <- empty, harmless: the line's exit status comes from the trailing if"
echo "command -v zsh: $(command -v zsh || echo absent)"
echo "/etc/shells contains zsh: $(grep -c zsh /etc/shells 2>/dev/null || echo '0 (file absent)')"
echo "-- what run 1 actually printed --"
grep -n 'login shell' /tmp/run1.log || echo "NO 'login shell:' line - the chsh recipe line did not run"
echo "-- resulting login shell --"
getent passwd "$(whoami)" | cut -d: -f7

hr "[13] '|| echo WARN' really prevents a target failure"
echo "-- WARNs emitted by the REAL run (each is an optional install that failed and did NOT kill the target) --"
grep -n 'WARN:' /tmp/run1.log || echo "(no WARNs this run)"
echo "-- deterministic probe of the same construct under make --"
printf '.PHONY: p\np:\n\tcurl -sf --max-time 3 https://invalid.invalid/awscli.zip -o /tmp/x || echo "WARN: AWS CLI install failed."\n' > /tmp/warnprobe.mk
make -f /tmp/warnprobe.mk p; wrc=$?
echo "warnprobe exit=$wrc (must be 0)"
[ "$wrc" -eq 0 ] || { echo "WARN-FAIL: '|| echo WARN' did NOT protect the target"; fail=1; }

hr "[14] make all - RUN 2 (idempotence)"
t2=$(date +%s)
make all 2>&1 | tee /tmp/run2.log
rc2=${PIPESTATUS[0]}
t3=$(date +%s)
echo "EXIT-RUN2=$rc2   elapsed=$((t3-t2))s   (run 1 was $((t1-t0))s)"
echo "-- links still good after run 2 --"
for p in "$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/nvim" "$HOME/.config/starship.toml"; do
  [ -L "$p" ] && [ -e "$p" ] && echo "LINK-OK   $p" || { echo "LINK-FAIL $p after run 2"; fail=1; }
done
for p in "$HOME/znap" "$HOME/zsh-users"; do
  [ -e "$p" ] || [ -L "$p" ] && { echo "TODO16-FAIL: $p appeared on run 2"; fail=1; } || echo "TODO16-OK: $p still absent"
done

hr "[14b] lib/lazygit-version.sh TRUE happy path - rerun with curl present"
echo "Phase [11] ran it on the stock image, where curl is absent (PKGS_CORE ships"
echo "neither curl nor wget), so only the empty/WARN branch was reached. Install"
echo "curl now - AFTER run 2, so idempotence above stays uncontaminated - and rerun."
if [ "$pm" = apt ]; then apt-get install -y -qq curl >/dev/null 2>&1; else dnf install -y -q curl >/dev/null 2>&1; fi
echo "curl now: $(command -v curl || echo STILL-ABSENT)"
lgout2="$(bash "$HOME/df/lib/lazygit-version.sh" 2>&1)"; lgrc2=$?
echo "exit=$lgrc2  output='$lgout2'"
if [ "$lgrc2" -ne 0 ]; then
  echo "LAZYGIT-FAIL: helper exited non-zero ($lgrc2) with curl present - it must never fail the target"; fail=1
elif echo "$lgout2" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "LAZYGIT-HAPPY-PROVEN: grep -Po extracted a real version from the live GitHub API"
else
  echo "LAZYGIT-OK: still empty (rate-limited or offline) - WARN branch, exit 0; happy path NOT proven this run"
fi

hr "[15] VERDICT"
echo "EXIT-RUN1=$rc1"
echo "EXIT-RUN2=$rc2"
[ "$rc1" -eq 0 ] || { echo "FAIL: make all run 1 exited $rc1"; fail=1; }
[ "$rc2" -eq 0 ] || { echo "FAIL: make all run 2 exited $rc2 - not idempotent"; fail=1; }
if [ "$fail" -eq 0 ]; then echo "RESULT: PASS"; exit 0; else echo "RESULT: FAIL"; exit 1; fi
GATE

chmod +x "$tmp/gate.sh"

# ---------------------------------------------------------------------------
# Host side
# ---------------------------------------------------------------------------
run_container() {
  local label="$1" image="$2" pm="$3" mode="$4" log="$5"
  local name="$NAME_PREFIX-$label-$$"
  local marker="$tmp/timeout-$label"

  {
    echo "########################################################################"
    echo "# $label | image=$image | pm=$pm | mode=$mode"
    echo "# started: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "# docker : $DOCKER ($("$DOCKER" version --format '{{.Server.Version}}' 2>/dev/null))"
    echo "# timeout: ${TIMEOUT}s hard bound (host has broken IPv6; apt/dnf/curl can stall)"
    echo "# mount  : $REPO -> /dotfiles:ro   (READ-ONLY; copied inside the container)"
    echo "########################################################################"
  } | tee "$log"

  # Watchdog: kills the CONTAINER, not just the client, so no orphan survives.
  { sleep "$TIMEOUT" && touch "$marker" && "$DOCKER" kill "$name" >/dev/null 2>&1; } &
  local wd=$!

  # USER is set because every real login shell sets it; docker leaving it unset is
  # the artificial case. Section [12] records the unset case too.
  "$DOCKER" run --rm --name "$name" -e USER=root \
    -v "$REPO:/dotfiles:ro" -v "$tmp:/gate:ro" \
    "$image" bash /gate/gate.sh "$pm" "$mode" 2>&1 | tee -a "$log"
  local rc=${PIPESTATUS[0]}

  kill "$wd" 2>/dev/null; wait "$wd" 2>/dev/null

  local verdict
  if [ -e "$marker" ]; then verdict="BLOCKED (hard timeout after ${TIMEOUT}s)"
  elif [ "$mode" = bootstrap ]; then verdict="CAPTURED (observable recorded; see GRADING above - this mode asserts nothing)"
  elif [ "$rc" -eq 0 ]; then verdict="PASS"
  else verdict="FAIL (exit $rc)"; fi
  { echo; echo "########################################################################"
    echo "# $label VERDICT: $verdict"
    echo "# finished: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "########################################################################"; } | tee -a "$log"

  case "$verdict" in PASS|CAPTURED*) return 0 ;; *) return 1 ;; esac
}

targets="${*:-ubuntu fedora bootstrap}"
overall=0
for t in $targets; do
  case "$t" in
    ubuntu)    run_container ubuntu "ubuntu:24.04"  apt full        "$EVIDENCE/10-docker-ubuntu.log" ;;
    fedora)    run_container fedora "fedora:latest" dnf full        "$EVIDENCE/10-docker-fedora.log" ;;
    bootstrap) run_container bootstrap "ubuntu:24.04" apt bootstrap "$EVIDENCE/10-docker-bootstrap.log" ;;
    *) echo "ERROR: unknown target '$t'. Expected: ubuntu fedora bootstrap" >&2; exit 2 ;;
  esac
  [ $? -eq 0 ] || overall=1
done

echo
echo "logs: $EVIDENCE/10-docker-*.log"
exit "$overall"
