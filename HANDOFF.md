# Handoff — opencode config repair + install.sh bug report

Date: 2026-09-13
Host: macOS (Apple Silicon), repo at `~/Documents/repos/dotfiles`
Git: branch up to date at `007a0e3`, working tree clean except untracked `zsh-users/`

---

## 1. Presenting problem

Every opencode launch warned:

```
Agent build's configured model github-copilot/claude-sonnet-4.5 is not valid
```

and none of the repo's oh-my-openagent (omo) / ponytail configuration was taking effect.

There were **two independent faults**, plus a third that silently caused both to persist.

---

## 2. Root causes found

### Fault 1 — a foreign global config: ECC at `~/.opencode`

`~/.opencode` was an install of **ECC ("Everything Claude Code")** by `affaan-m`
(`github.com/affaan-m/ECC`, npm `ecc-universal@2.0.0-rc.1`), installed 2026-06-09.

- Not a git repo, not tracked by dotfiles, never referenced by `install.sh`.
- `README.md:334` credits ECC only as a *source some skills were copied from* — the full
  bundle was never meant to be installed.
- Its `~/.opencode/opencode.json` (16 KB) set `"model": "github-copilot/claude-sonnet-4.5"`,
  `"default_agent": "build"` with the same retired ID, ~27 further references to retired
  `claude-sonnet-4.5` / `claude-opus-4.5`, plus `plugin: ["./plugins"]` and 11 `instructions`
  files loaded into every session.
- It was live: the `changed-files` / `check-coverage` / `format-code` / `git-summary` /
  `lint-check` / `run-tests` / `security-audit` tools and a 21-skill catalogue came from it.

This was the source of the warning, and it competed with the dotfiles omo routing.

### Fault 2 — the dotfiles opencode config was never actually installed

`~/.config/opencode/opencode.jsonc` was a **real file** (not the stow symlink) containing only:

```json
{ "$schema": "https://opencode.ai/config.json" }
```

No `model`, no `plugin` array ⇒ **oh-my-openagent and ponytail never loaded at all**.
`oh-my-openagent.json` was absent from `~/.config/opencode/` entirely. The whole omo preset
was inert. Per `AGENTS.md`, the `plugin` array is mandatory or every `oh-my-openagent.*.json`
is dead weight.

### Fault 3 — `install.sh` died silently before ever reaching stow

See section 5. This is why Fault 2 never self-corrected.

---

## 3. Work completed

All executed and verified.

1. **Deleted ECC**: `rm -rf ~/.opencode` (user chose outright deletion over disabling).
2. **Cleared stow blockers**:
   - `rm -f ~/.config/opencode/opencode.jsonc` (the useless stub)
   - `rm -rf ~/.agents/skills/brainstorming ~/.agents/skills/find-skills` (repo owns both)
3. **Stowed**: dry-run `stow -n -v --target="$HOME" --restow opencode` came back clean, then
   ran for real. No `--adopt`, per `AGENTS.md`.
4. **Pre-installed the plugins** (see "extra step" below).

### Resulting state

| Target | State |
|---|---|
| `~/.opencode` (ECC) | deleted |
| `~/.config/opencode/opencode.jsonc` | symlink → repo; has `model: github-copilot/claude-opus-5` + `plugin` array |
| `~/.config/opencode/oh-my-openagent.json` | symlink → repo → `oh-my-openagent.github-copilot.json` |
| `~/.config/opencode/commands` | symlink → repo (4 ponytail commands) |
| `~/.agents/skills` | symlink → repo |
| `oh-my-openagent` | 4.19.4 installed |
| `@dietrichgebert/ponytail` | 4.9.0 installed |

No `claude-sonnet-4.5` / `claude-opus-4.5` references remain in any live config.
`~/.local/state/opencode/model.json` was left alone — it already held valid `claude-opus-5`.

**Extra step not in the original plan:** `~/.config/opencode/node_modules` was missing both
plugins. opencode had rewritten `package.json` down to just `@opencode-ai/plugin` while the
config had no `plugin` array. Ran
`npm install --prefer-offline oh-my-openagent@4.19.4 @dietrichgebert/ponytail@4.9.0`
in `~/.config/opencode` so startup does no registry round-trip. Both verified present at the
pinned versions.

### Action required

**Quit every running opencode instance and relaunch.** opencode reads config once per
process start; opening a new session inside a running process does not reload it.

---

## 4. Collateral damage — 3 skills destroyed

`caveman`, `codebase-study-guide`, `vue-expert-js` are **gone**. They were *not* removed by
the repair work; `./install.sh opencode` (run at 21:42) `rm -rf`'d all of `~/.agents/skills`
— see Bug B. `rm -rf` is unrecoverable.

`~/.agents/.skill-lock.json` survived and records every source:

| Skill | Source |
|---|---|
| `caveman` | `github.com/JuliusBrussee/caveman` |
| `codebase-study-guide` | `github.com/petekp/agent-skills` |
| `vue-expert-js` | `github.com/jeffallan/claude-skills` |
| `brainstorming` | `github.com/obra/superpowers` (in repo, restored) |
| `find-skills` | `github.com/vercel-labs/skills` (in repo, restored) |

All three are reinstallable. **Catch:** `~/.agents/skills` is now a *single symlink to the
repo*, so anything reinstalled there lands inside the dotfiles repo and must be committed —
arguably the correct outcome, since being unmanaged is how they got silently wiped.

**Open decision:** restore the three into the repo and commit, or leave them gone.

---

## 5. `install.sh` bug report

Investigated, not fixed. User's instruction: treat `install.sh` as reference only for now.

### Bug A — silent exit (fatal; this is "it exited without a reason")

`install.sh:91`

```bash
target="$(readlink -f "$f")"
```

`~/.config/starship.toml` is a **broken** symlink → `/Users/angel/dotfiles/zsh/starship.toml`,
the *old* dotfiles path, which no longer exists. On macOS, BSD `readlink -f` **prints the
path but exits 1** for a dangling link. Under `set -e` an assignment from command
substitution inherits that status, so the script dies mid-loop.

Verified:

```
$ readlink -f ~/.config/starship.toml
/Users/angel/dotfiles/zsh/starship.toml
exit=1

$ bash -c 'set -e; target="$(readlink -f ~/.config/starship.toml)"; echo ASSIGNED'
outer_exit=1        # "ASSIGNED" never printed
```

Matches the `bash -x` trace exactly: last line `+ target=/Users/angel/dotfiles/zsh/starship.toml`,
then nothing. **Exits before stow ever runs**, with no output because `set -e` is silent.

Mac-only because on Ubuntu/Fedora that link pointed somewhere valid. The stale `~/dotfiles`
path is Mac-specific history. Note the lines 86-90 comment is about fixing a *previous* bug
in this same expression.

*Ruled out:* the `&&` chain at lines 98-100 looks guilty but is not — `set -e` exempts
non-final commands in an `&&` list. Tested both orderings; both reached the end.

### Bug B — data loss

`install.sh:99`

```bash
[ -d "$d" ] && [ ! -L "$d" ] && echo "Removing blocking dir: $d" && rm -rf "$d"
```

Unconditional recursive delete of all of `~/.agents/skills`, not just repo-managed entries.
Destroyed the three skills in section 4.

### Bug C — stow failures swallowed

`install.sh:106`

```bash
stow -v --target="$HOME" --restow "$pkg" 2>&1 | grep -v "BUG" || true
```

The pipe discards stow's exit status and `|| true` masks the rest. Verified with a
guaranteed-failing stow:

```
stow: --target value '/tmp/nonexistent-xyz' is not a valid directory
SCRIPT CONTINUED, rc=0
```

So `WARNING! stowing opencode would cause conflicts ... All operations aborted.` scrolls past
and the script still prints `Done. Restart your shell.` The line 115 comment claims "stow now
fails loudly instead" — it does not.

### Bug D — `getent` absent on macOS

`install.sh:160`

```bash
login_shell="$(getent passwd "$USER" | cut -d: -f7)"
```

`getent` does not exist on macOS ⇒ `login_shell` empty ⇒ line 161 comparison always true ⇒
`chsh` runs on every invocation. Needs `dscl . -read /Users/$USER UserShell` on Darwin.
Not fatal: `getent` fails inside a pipeline, so `set -e` doesn't fire.

### Bug E — stale `node_modules` check

`install.sh:150` tests only that `node_modules/` *exists*. It existed here while containing
neither plugin — exactly the gap patched by hand in section 3.

### Proposed fixes (not applied)

| # | Line | Fix |
|---|---|---|
| A | 85-96 | Delete dangling links up front via `[ ! -e "$f" ]` (a broken link is stale by definition), then `readlink -f ... 2>/dev/null \|\| true` so `set -e` can't fire |
| B | 98-100 | Never `rm -rf`. Move aside to `${d}.bak.$(date +%s)` and print the path, or abort for manual inspection |
| C | 104-108 | `if ! out="$(stow ... 2>&1)"; then echo "$out" >&2; exit 1; fi` |
| D | 157-162 | Branch on `command -v getent`, else `dscl` on Darwin |
| E | 150-151 | Check `node_modules/oh-my-openagent` and `node_modules/@dietrichgebert/ponytail`, not just the dir |

Also recommended: `set -euo pipefail` plus an `ERR` trap printing the failing line number, so
a future silent death names itself.

**Open decisions:** (1) fix all five or only A + C, the two that make the script silently lie
about success; (2) for Bug B, prefer *abort with instructions* or *auto-move to `.bak` and
continue*.

---

## 6. Loose ends

- `~/.config/starship.toml` is still a **broken symlink** to the old `~/dotfiles` path. Not
  touched — `zsh` was out of scope. It will keep killing `install.sh` until Bug A is fixed or
  the link is removed.
- `~/.zshrc` is **missing**; `~/.tmux.conf` and `~/.config/nvim` are **real files/dirs**, not
  stow symlinks. The `zsh` / `tmux` / `nvim` packages are effectively unstowed on this Mac.
- Untracked `zsh-users/` at repo root.
- `~/.agents/.skill-lock.json` is a real file that survived; it sits outside the
  `~/.agents/skills` symlink and is unmanaged.

---

## 7. Reference — commands used

```bash
# diagnosis
grep -rl "claude-sonnet-4.5" ~/.config/opencode ~/.opencode ~/Documents/repos/dotfiles
readlink -f ~/.config/opencode/oh-my-openagent.json
stow -n -v --target="$HOME" --restow opencode      # dry run; ALWAYS do this first

# repair
rm -rf ~/.opencode
rm -f ~/.config/opencode/opencode.jsonc
rm -rf ~/.agents/skills/brainstorming ~/.agents/skills/find-skills
stow -v --target="$HOME" --restow opencode          # never --adopt
cd ~/.config/opencode && npm install --prefer-offline \
  oh-my-openagent@4.19.4 @dietrichgebert/ponytail@4.9.0
```

Switch omo preset (from `AGENTS.md`):

```bash
cd ~/Documents/repos/dotfiles/opencode/.config/opencode
ln -sfn oh-my-openagent.<preset>.json oh-my-openagent.json
```
