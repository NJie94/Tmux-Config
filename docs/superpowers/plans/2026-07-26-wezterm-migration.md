# Ghostty → WezTerm Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Swap the dotfiles repo's terminal layer from Ghostty to WezTerm — cloning the existing `NJie94/wezterm` config repo the same way `NJie94/nvim` is already cloned, removing the vendored Ghostty config and Windows launcher, and updating every file that referenced Ghostty (`install.sh`, `scripts/doctor.sh`, `tmux/tmux.conf.local`, `zsh/zshrc`, the renamed `zsh/wezterm-tmux.zsh`, `README.md`) — then run and verify it on this machine.

**Architecture:** No change to the symlink-based install model. `NJie94/wezterm` joins `NJie94/nvim` as a second "clone-if-absent, never touch if present" external repo. Everything that used to say "ghostty" becomes "wezterm"; the vendored `ghostty/config.ghostty` and `windows/ghostty-wsl.cmd.example` are deleted outright since WezTerm's own config already handles both concerns (visual config lives in the cloned repo; `config/launch.lua` in that repo already launches straight into WSL2 on Windows with no separate launcher script).

**Tech Stack:** POSIX-ish Bash (`set -euo pipefail`), tmux 3.2+ (oh-my-tmux), zsh (oh-my-zsh), WezTerm, fzf, git.

## Global Constraints

- Repo root: `~/dev/dotfiles`, remote `https://github.com/NJie94/dotfiles.git`, branch `master` (matches existing repo).
- `NJie94/wezterm` is cloned to `~/.config/wezterm`, never vendored or modified by this repo — identical pattern to the existing `NJie94/nvim` clone in `install.sh` (spec §Scope, §Repo layout changes).
- Keep `NJie94/wezterm`'s own keybinds as-is; do not touch that repo's contents (spec §Scope, "explicitly out of scope").
- `install.sh` must remain idempotent (carried over from the original design's Global Constraints, unchanged by this migration).
- Two small additions beyond the literal spec text, both a direct extension of renames the spec already calls for for the same reason (avoid stale, confusing "ghostty" artifacts once Ghostty is gone):
  - `install.sh` removes the two now-orphaned symlinks from the old Ghostty setup (`~/.config/ghostty/config.ghostty`, `~/.config/zsh/ghostty-tmux.zsh`) if present, since re-running it would otherwise leave them dangling forever (nothing in the new `install.sh` ever points at those paths again).
  - The installed doctor script is renamed from `ghostty-tmux-doctor` to `wezterm-tmux-doctor`, matching the `ghostty-tmux.zsh` → `wezterm-tmux.zsh` rename the spec already specifies.
- `TERM_PROGRAM` for WezTerm is the literal string `WezTerm` (capital W, capital T) — this is WezTerm's actual runtime value, distinct from Ghostty's lowercase `ghostty`.

---

### Task 1: `zsh/wezterm-tmux.zsh` (renamed from `zsh/ghostty-tmux.zsh`) and `zsh/zshrc`

**Files:**
- Create: `zsh/wezterm-tmux.zsh`
- Delete: `zsh/ghostty-tmux.zsh`
- Modify: `zsh/zshrc:1-2`

**Interfaces:**
- Produces: `zsh/wezterm-tmux.zsh`, symlinked by Task 3's `install.sh` to `~/.config/zsh/wezterm-tmux.zsh`. Sourced at runtime by `zsh/zshrc`.

- [ ] **Step 1: Create the new file with `git mv`, then edit it**

```bash
cd ~/dev/dotfiles
git mv zsh/ghostty-tmux.zsh zsh/wezterm-tmux.zsh
```

Replace the full contents of `zsh/wezterm-tmux.zsh` with:

```zsh
# Source this near the top of ~/.zshrc.
# It is intentionally inactive outside WezTerm.

if [[ "${TERM_PROGRAM:-}" == WezTerm ]]; then
  # Automatically enter the persistent main session only for an interactive,
  # local WezTerm shell. Set WEZTERM_AUTO_TMUX=0 to bypass once, or permanently.
  if [[ -o interactive && -z "${TMUX:-}" && "${WEZTERM_AUTO_TMUX:-1}" == 1 ]]; then
    if command -v tmux >/dev/null 2>&1; then
      exec tmux new-session -A -s "${WEZTERM_TMUX_SESSION:-main}"
    fi
  fi
fi
```

(This drops the old Ghostty-specific `GHOSTTY_RESOURCES_DIR` shell-integration sourcing block entirely — WezTerm has no equivalent manual-source step, per the approved spec.)

- [ ] **Step 2: Update `zsh/zshrc`'s source line**

Current `zsh/zshrc:1-2`:

```zsh
# Ghostty + tmux integration
[[ -r "$HOME/.config/zsh/ghostty-tmux.zsh" ]] && source "$HOME/.config/zsh/ghostty-tmux.zsh"
```

Replace with:

```zsh
# WezTerm + tmux integration
[[ -r "$HOME/.config/zsh/wezterm-tmux.zsh" ]] && source "$HOME/.config/zsh/wezterm-tmux.zsh"
```

- [ ] **Step 3: Verify both files parse and the old file is gone**

```bash
zsh -n ~/dev/dotfiles/zsh/wezterm-tmux.zsh && echo "wezterm-tmux.zsh OK"
zsh -n ~/dev/dotfiles/zsh/zshrc && echo "zshrc OK"
test ! -f ~/dev/dotfiles/zsh/ghostty-tmux.zsh && echo "old file gone"
grep -c ghostty ~/dev/dotfiles/zsh/wezterm-tmux.zsh ~/dev/dotfiles/zsh/zshrc
```
Expected: `wezterm-tmux.zsh OK`, `zshrc OK`, `old file gone`, and the final `grep -c` line prints `0` for both files (no leftover "ghostty" references — `grep -c` with no match still exits 1, which is fine here since this is just an informational check, not a pass/fail gate).

- [ ] **Step 4: Commit**

```bash
cd ~/dev/dotfiles
git add zsh/wezterm-tmux.zsh zsh/zshrc
git status  # confirm zsh/ghostty-tmux.zsh shows as deleted/renamed
git commit -m "Rename ghostty-tmux.zsh to wezterm-tmux.zsh, drop Ghostty-specific integration"
```

---

### Task 2: `tmux/tmux.conf.local`

**Files:**
- Modify: `tmux/tmux.conf.local:512,532,534,558,630`

**Interfaces:**
- Consumes: nothing new.
- Produces: same file, still symlinked to `~/.config/tmux/tmux.conf.local` by `install.sh` (no change to that link).

- [ ] **Step 1: Update the section banner comments**

Current line 512:
```tmux
# --- Nicholas clean Ghostty + Oh My Tmux theme --------------------------------
```
Replace with:
```tmux
# --- Nicholas clean WezTerm + Oh My Tmux theme --------------------------------
```

Current line 630:
```tmux
# --- End Nicholas clean Ghostty + Oh My Tmux theme ----------------------------
```
Replace with:
```tmux
# --- End Nicholas clean WezTerm + Oh My Tmux theme ----------------------------
```

- [ ] **Step 2: Update the terminal-features/overrides TERM match**

Current lines 530-535:
```tmux
%if #{>=:#{version},3.2}
set -g extended-keys on #!important
set -as terminal-features ',xterm-ghostty:RGB:extkeys:focus:clipboard:hyperlinks:sync' #!important
%else
set -as terminal-overrides ',xterm-ghostty:Tc' #!important
%endif
```
Replace with:
```tmux
%if #{>=:#{version},3.2}
set -g extended-keys on #!important
set -as terminal-features ',xterm-256color:RGB:extkeys:focus:clipboard:hyperlinks:sync' #!important
%else
set -as terminal-overrides ',xterm-256color:Tc' #!important
%endif
```
(WezTerm doesn't set a custom `TERM` value the way Ghostty does — it reports the generic `xterm-256color`, per the approved spec.)

- [ ] **Step 3: Update the terminal title**

Current line 558:
```tmux
tmux_conf_theme_terminal_title="Ghostty"
```
Replace with:
```tmux
tmux_conf_theme_terminal_title="WezTerm"
```

- [ ] **Step 4: Verify no "ghostty" references remain and the file still parses**

```bash
grep -in ghostty ~/dev/dotfiles/tmux/tmux.conf.local; echo "exit: $?"
tmux -f /dev/null -f ~/dev/dotfiles/tmux/tmux.conf.local -L dotfiles_plan_check start-server \; kill-server 2>&1 | grep -i error; echo "exit: $?"
```
Expected: first command prints no matches and `exit: 1` (grep found nothing); second command's `grep -i error` prints nothing and `exit: 1` (no error lines — this file relies on oh-my-tmux's `.tmux.conf` for `%if`-block support, so loading it standalone under `-L` with `start-server`/`kill-server` just checks it doesn't throw a hard parse error, not full functional behavior; full functional verification happens in Task 7).

- [ ] **Step 5: Commit**

```bash
cd ~/dev/dotfiles
git add tmux/tmux.conf.local
git commit -m "Update tmux.conf.local for WezTerm: TERM match and terminal title"
```

---

### Task 3: `install.sh`

**Files:**
- Modify: `install.sh` (full content shown below)

**Interfaces:**
- Consumes: `zsh/wezterm-tmux.zsh` (Task 1), `tmux/tmux.conf.local` (Task 2) — both read relative to `$REPO_DIR`.
- Produces: the fully-configured machine state that Task 4's `doctor.sh` checks.

- [ ] **Step 1: Replace the full file contents**

Replace all of `install.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '==> %s\n' "$1"; }
warn() { printf 'WARN: %s\n' "$1" >&2; }

detect_os() {
  if [[ -f /proc/version ]] && grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    echo wsl2
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    echo macos
  elif [[ "$(uname -s)" == "Linux" ]]; then
    echo linux
  else
    echo unknown
  fi
}

OS="$(detect_os)"
log "Detected OS: $OS"

if [[ "$OS" == macos ]] && ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew is required on macOS but was not found. Install it from https://brew.sh and re-run this script."
  exit 1
fi

linux_pkg_install() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y && sudo apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y "$@"
  else
    warn "No supported package manager (apt/dnf) found; install manually: $*"
    return 1
  fi
}

ensure_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    log "Found dependency: $cmd"
    return 0
  fi
  log "Installing missing dependency: $cmd"
  case "$OS" in
    macos) brew install "$cmd" ;;
    linux|wsl2) linux_pkg_install "$cmd" ;;
    *) warn "Unsupported OS; install $cmd manually" ;;
  esac
}

ensure_cmd tmux
ensure_cmd zsh
ensure_cmd git
ensure_cmd fzf
ensure_cmd curl
ensure_cmd unzip

if ! command -v wezterm >/dev/null 2>&1; then
  case "$OS" in
    macos) brew install --cask wezterm ;;
    linux) linux_pkg_install wezterm || warn "Install WezTerm manually: https://wezterm.org/installation" ;;
    wsl2) linux_pkg_install wezterm || warn "Install WezTerm manually inside this WSL2 distro: https://wezterm.org/installation" ;;
    *) warn "Unsupported OS; install WezTerm manually" ;;
  esac
fi

font_installed() {
  # Plain grep (no -q) reads all of its input before exiting, so it never
  # SIGPIPEs the producer mid-stream -- with `pipefail` on, a `grep -q` that
  # quits early kills fc-list/ls with SIGPIPE and pipefail then reports that
  # as a pipeline failure even though the match was found.
  fc-list 2>/dev/null | grep -i "JetBrainsMono Nerd Font" >/dev/null && return 0
  [[ "$OS" == macos ]] && ls "$HOME/Library/Fonts" 2>/dev/null | grep -i "JetBrainsMono" >/dev/null && return 0
  return 1
}

install_linux_font() {
  mkdir -p "$HOME/.local/share/fonts"
  curl -fLo /tmp/JetBrainsMono.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip || return 1
  unzip -o /tmp/JetBrainsMono.zip -d "$HOME/.local/share/fonts" >/dev/null || return 1
  fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
  return 0
}

if ! font_installed; then
  log "Installing JetBrainsMono Nerd Font"
  case "$OS" in
    macos) brew install --cask font-jetbrains-mono-nerd-font ;;
    linux|wsl2)
      # Font is purely cosmetic -- a network hiccup, a renamed release
      # asset, or missing curl/unzip shouldn't abort the whole install.
      install_linux_font ||
        warn "Failed to install JetBrainsMono Nerd Font; continuing without it. Install manually from https://www.nerdfonts.com/ if desired."
      ;;
  esac
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [[ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]]; then
  log "Installing zsh-autosuggestions"
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
fi
if [[ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ]]; then
  log "Installing zsh-syntax-highlighting"
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
fi
if [[ ! -d "$ZSH_CUSTOM_DIR/themes/powerlevel10k" ]]; then
  log "Installing powerlevel10k theme"
  git clone --depth 1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
fi

if [[ ! -d "$HOME/.local/share/oh-my-tmux" ]]; then
  log "Installing oh-my-tmux"
  git clone --depth 1 https://github.com/gpakosz/.tmux.git "$HOME/.local/share/oh-my-tmux"
fi

if [[ ! -d "$HOME/.config/nvim" ]]; then
  log "Cloning NJie94/nvim into ~/.config/nvim"
  git clone https://github.com/NJie94/nvim "$HOME/.config/nvim"
else
  log "~/.config/nvim already exists, leaving it as-is"
fi

if [[ ! -d "$HOME/.config/wezterm" ]]; then
  log "Cloning NJie94/wezterm into ~/.config/wezterm"
  git clone https://github.com/NJie94/wezterm "$HOME/.config/wezterm"
else
  log "~/.config/wezterm already exists, leaving it as-is"
fi

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      log "Already linked: $dest"
      return 0
    fi
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
    log "Backing up existing $dest to $backup"
    mv "$dest" "$backup"
  fi
  ln -s "$src" "$dest"
  log "Linked $dest -> $src"
}

# Remove dangling symlinks left behind by the earlier Ghostty-based setup --
# nothing below points at these paths anymore, so a re-run would otherwise
# leave them orphaned forever.
for stale in "$HOME/.config/ghostty/config.ghostty" "$HOME/.config/zsh/ghostty-tmux.zsh"; do
  if [[ -L "$stale" ]]; then
    log "Removing stale symlink from the old Ghostty setup: $stale"
    rm "$stale"
  fi
done

chmod +x "$REPO_DIR/scripts/tmux-sessionizer" "$REPO_DIR/scripts/doctor.sh"

link "$HOME/.local/share/oh-my-tmux/.tmux.conf" "$HOME/.config/tmux/tmux.conf"
link "$REPO_DIR/tmux/tmux.conf.local" "$HOME/.config/tmux/tmux.conf.local"
link "$REPO_DIR/zsh/zshrc" "$HOME/.zshrc"
link "$REPO_DIR/zsh/wezterm-tmux.zsh" "$HOME/.config/zsh/wezterm-tmux.zsh"

case "$OS" in
  macos) link "$REPO_DIR/zsh/macos.zsh" "$HOME/.config/zsh/macos.zsh" ;;
  linux|wsl2) link "$REPO_DIR/zsh/linux.zsh" "$HOME/.config/zsh/linux.zsh" ;;
esac

link "$REPO_DIR/scripts/tmux-sessionizer" "$HOME/.local/bin/tmux-sessionizer"
link "$REPO_DIR/scripts/doctor.sh" "$HOME/.local/bin/wezterm-tmux-doctor"

if [[ ! -f "$HOME/.zshrc.local" ]]; then
  log "Creating empty ~/.zshrc.local"
  touch "$HOME/.zshrc.local"
fi

log "Triggering oh-my-tmux's automatic plugin installation"
tmux new-session -d -s __dotfiles_bootstrap -c /tmp 2>/dev/null || true
sleep 3
tmux kill-session -t __dotfiles_bootstrap 2>/dev/null || true

log "Install complete."
log "Next steps:"
log "  - Restart WezTerm to pick up the new config."
log "  - Neovim: copy $REPO_DIR/nvim/tmux-navigator.lua.example into your nvim config's plugin directory."
if [[ "$OS" == wsl2 ]]; then
  log "  - Windows: install WezTerm natively from https://wezterm.org/installation (or 'winget install wez.wezterm') -- its bundled config already launches straight into this WSL2 distro, no launcher script needed."
fi
log "Run '$HOME/.local/bin/wezterm-tmux-doctor' to verify the setup (plugin clones may take a few seconds — re-run if it reports missing plugins right after install)."
```

- [ ] **Step 2: Verify syntax**

```bash
bash -n ~/dev/dotfiles/install.sh && echo OK
```
Expected: `OK`

- [ ] **Step 3: Verify no "ghostty" references remain except the intentional cleanup block**

```bash
grep -in ghostty ~/dev/dotfiles/install.sh
```
Expected: exactly two matching lines, both inside the "Remove dangling symlinks" block (`$HOME/.config/ghostty/config.ghostty`, `$HOME/.config/zsh/ghostty-tmux.zsh`, and the log message mentioning "the old Ghostty setup") — no other references.

- [ ] **Step 4: Commit**

```bash
cd ~/dev/dotfiles
git add install.sh
git commit -m "install.sh: clone NJie94/wezterm instead of installing/symlinking Ghostty"
```

---

### Task 4: `scripts/doctor.sh`

**Files:**
- Modify: `scripts/doctor.sh`

**Interfaces:**
- Produces: executable script symlinked by Task 3's `install.sh` to `~/.local/bin/wezterm-tmux-doctor`.

- [ ] **Step 1: Update the Ghostty check to a WezTerm check**

Current:
```bash
check "ghostty installed" 'command -v ghostty >/dev/null 2>&1'
```
Replace with:
```bash
check "wezterm installed" 'command -v wezterm >/dev/null 2>&1'
```

- [ ] **Step 2: Update the config-symlink check to a git-checkout check**

Current:
```bash
check "~/.config/ghostty/config.ghostty is a symlink into the dotfiles repo" \
  'is_symlink_into_repo "$HOME/.config/ghostty/config.ghostty" "ghostty/config.ghostty"'
```
Replace with:
```bash
check "~/.config/wezterm exists and is a git checkout" '[[ -d "$HOME/.config/wezterm/.git" ]]'
```
(This mirrors the existing `check "~/.config/nvim exists and is a git checkout" ...` line further down, since WezTerm's config is now handled the same way nvim's is.)

- [ ] **Step 3: Update the shell-integration symlink check**

Current:
```bash
check "~/.config/zsh/ghostty-tmux.zsh is a symlink into the dotfiles repo" \
  'is_symlink_into_repo "$HOME/.config/zsh/ghostty-tmux.zsh" "zsh/ghostty-tmux.zsh"'
```
Replace with:
```bash
check "~/.config/zsh/wezterm-tmux.zsh is a symlink into the dotfiles repo" \
  'is_symlink_into_repo "$HOME/.config/zsh/wezterm-tmux.zsh" "zsh/wezterm-tmux.zsh"'
```

- [ ] **Step 4: Verify syntax and no leftover "ghostty" references**

```bash
bash -n ~/dev/dotfiles/scripts/doctor.sh && echo "syntax OK"
grep -in ghostty ~/dev/dotfiles/scripts/doctor.sh; echo "grep exit: $?"
```
Expected: `syntax OK`, then no matching lines and `grep exit: 1`.

- [ ] **Step 5: Commit**

```bash
cd ~/dev/dotfiles
git add scripts/doctor.sh
git commit -m "doctor.sh: check for WezTerm/its config checkout instead of Ghostty"
```

---

### Task 5: Remove `ghostty/config.ghostty` and `windows/ghostty-wsl.cmd.example`

**Files:**
- Delete: `ghostty/config.ghostty`
- Delete: `windows/ghostty-wsl.cmd.example`

**Interfaces:**
- Consumes: nothing (Tasks 3 and 4 already stopped referencing these paths).

- [ ] **Step 1: Remove both files and their now-empty directories**

```bash
cd ~/dev/dotfiles
git rm ghostty/config.ghostty windows/ghostty-wsl.cmd.example
rmdir ghostty windows 2>/dev/null || true
```

- [ ] **Step 2: Verify no executable/config file still references either path**

```bash
grep -rn "ghostty/config.ghostty\|ghostty-wsl.cmd" ~/dev/dotfiles --include='*.sh' --include='*.local' 2>/dev/null
```
Expected: no output. (`README.md` still mentions both paths at this point — that's expected and gets resolved by Task 6 next, which is why it's deliberately excluded from this check.)

- [ ] **Step 3: Commit**

```bash
cd ~/dev/dotfiles
git commit -m "Remove vendored Ghostty config and Windows WSL launcher (superseded by WezTerm)"
```

---

### Task 6: `README.md`

**Files:**
- Modify: `README.md` (full content shown below)

**Interfaces:**
- Consumes: nothing (documentation only, references paths/commands from Tasks 1-5).

- [ ] **Step 1: Replace the full file contents**

Replace all of `README.md` with:

```markdown
# dotfiles

One tmux (oh-my-tmux) + zsh (oh-my-zsh) + WezTerm setup, kept in one repo and
installed with a single script on Linux, macOS, or Windows.

## What's here

- `tmux/tmux.conf.local` — prefix `Ctrl+Space`, `\`/`-` splits, Catppuccin
  theme, zsh as the tmux shell, TPM plugins (tmux-sensible, tmux-resurrect,
  tmux-continuum, vim-tmux-navigator), `prefix + f` bound to a project
  session picker.
- `zsh/zshrc` — portable oh-my-zsh base (Powerlevel10k, fzf, autosuggestions,
  syntax highlighting), sourcing an OS-specific file and an untracked
  `~/.zshrc.local` for anything machine-specific or private.
- `zsh/linux.zsh` / `zsh/macos.zsh` — OS-specific shell config.
- `zsh/wezterm-tmux.zsh` — auto-attaches to the persistent `main` tmux
  session whenever an interactive, local WezTerm shell opens.
- `scripts/tmux-sessionizer` — fzf-based project/session picker.
- `scripts/doctor.sh` — read-only health check for the whole setup.
- `nvim/tmux-navigator.lua.example` — copy into a separately-managed nvim
  config to get seamless `Ctrl+h/j/k/l` nvim/tmux pane navigation.

WezTerm's own visual config (font, theme, keybinds, tabs) lives in the
separately-versioned [`NJie94/wezterm`](https://github.com/NJie94/wezterm)
repo, cloned to `~/.config/wezterm` by `install.sh` — same pattern as
[`NJie94/nvim`](https://github.com/NJie94/nvim). Neither is vendored here;
`install.sh` only clones them if that path doesn't already exist and never
touches an existing checkout.

## Install

### Linux

```sh
git clone https://github.com/NJie94/dotfiles ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

Installs any missing `tmux`/`zsh`/`git`/`fzf`/WezTerm/JetBrainsMono Nerd
Font via `apt` or `dnf` (asks for `sudo` as needed), sets up oh-my-zsh and
oh-my-tmux, symlinks every config into place, and clones
[`NJie94/nvim`](https://github.com/NJie94/nvim) to `~/.config/nvim` and
[`NJie94/wezterm`](https://github.com/NJie94/wezterm) to `~/.config/wezterm`
if either isn't already there. Restart WezTerm afterward.

WezTerm itself installs automatically via `dnf` on Fedora. It is **not**
yet in Debian/Ubuntu's standard `apt` repositories, so on those distros
`install.sh` will warn instead of installing it — grab it manually from
[wezterm.org/installation](https://wezterm.org/installation).

### macOS

Requires [Homebrew](https://brew.sh) to already be installed —
`install.sh` exits with an error pointing you there if `brew` isn't found.

Same flow, via Homebrew:

```sh
git clone https://github.com/NJie94/dotfiles ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

`zsh/macos.zsh` starts as a near-empty stub (a placeholder for
`brew shellenv` and any Mac-only tool config) — fill it in as needed; it's
sourced automatically by `zsh/zshrc` once present.

### Windows

Unlike Ghostty, WezTerm has a native Windows GUI build, so it no longer
needs WSLg to run — but this setup's shell environment (tmux, zsh) still
lives inside a WSL2 distro, and `NJie94/wezterm`'s config already launches
straight into it.

1. Install WSL2 and a Linux distro (e.g. Ubuntu) from an elevated PowerShell:
   `wsl --install`.
2. Inside that distro, follow the **Linux** install steps above.
3. On the Windows side, install WezTerm natively from
   [wezterm.org/installation](https://wezterm.org/installation) (or
   `winget install wez.wezterm`). No launcher script to edit or run — open
   WezTerm and it attaches directly to the WSL2 distro.

## Keymap

Prefix: `Ctrl+Space`

| Keys | Action |
|---|---|
| `Ctrl+Space c` | New window in current directory |
| `Ctrl+Space \` | Split left/right |
| `Ctrl+Space -` | Split top/bottom |
| `Ctrl+Space 1`–`9` | Jump to window by number |
| `Ctrl+Space f` | Project/session picker (tmux-sessionizer) |
| `Ctrl+h/j/k/l` (no prefix) | Move between tmux panes / nvim splits (vim-tmux-navigator) |

WezTerm's own tab/pane/workspace keybinds (under its `SUPER+Space` leader)
are documented in [`NJie94/wezterm`](https://github.com/NJie94/wezterm)'s
own README.

## Verify

```sh
~/.local/bin/wezterm-tmux-doctor
```

Prints a pass/fail line for every dependency, plugin, and symlink this setup
depends on.

## Re-running install

`./install.sh` is safe to run again any time (e.g. after `git pull`) — it
only installs what's missing and never overwrites a symlink that already
points into this repo. Any real file it would otherwise replace is backed up
first as `<path>.bak.<timestamp>`.
```

- [ ] **Step 2: Verify it references only files that exist, and no "ghostty" references remain**

```bash
grep -oE '`[a-zA-Z0-9_./-]+`' ~/dev/dotfiles/README.md | tr -d '`' | grep -E '^(tmux|zsh|scripts|nvim)/' | sort -u | while read -r f; do test -f "$HOME/dev/dotfiles/$f" || echo "MISSING: $f"; done
grep -in ghostty ~/dev/dotfiles/README.md; echo "grep exit: $?"
```
Expected: first command prints no output (every referenced repo-relative file path exists — note `ghostty/` and `windows/` prefixes are intentionally excluded from this check since Task 5 removed both directories). Second command prints no matches and `grep exit: 1`.

- [ ] **Step 3: Commit**

```bash
cd ~/dev/dotfiles
git add README.md
git commit -m "README: document WezTerm setup and native Windows install"
```

---

### Task 7: Run and verify on this machine

**Files:** none created; this task exercises Tasks 1-6's output against the live machine.

**Interfaces:**
- Consumes: `install.sh` (Task 3), `scripts/doctor.sh` (Task 4).

- [ ] **Step 1: Run install.sh**

```bash
cd ~/dev/dotfiles
./install.sh
```
Expected: no errors. `wezterm` is already installed on this machine, so that block is a no-op (`Found dependency` is not printed for it since it's checked with a plain `if`, not `ensure_cmd` — no log line either way, this is expected). `~/.config/wezterm` already exists as `NJie94/wezterm`'s own checkout, so the clone step logs `~/.config/wezterm already exists, leaving it as-is` and does not touch it. The two stale-symlink lines should log `Removing stale symlink from the old Ghostty setup: ...` for both `~/.config/ghostty/config.ghostty` and `~/.config/zsh/ghostty-tmux.zsh` (both exist from the prior Ghostty setup). `~/.config/zsh/wezterm-tmux.zsh` and `~/.local/bin/wezterm-tmux-doctor` get created fresh as new symlinks.

- [ ] **Step 2: Confirm the stale Ghostty symlinks are actually gone**

```bash
test ! -e ~/.config/ghostty/config.ghostty && echo "old ghostty symlink removed"
test ! -e ~/.config/zsh/ghostty-tmux.zsh && echo "old ghostty-tmux.zsh symlink removed"
```
Expected: both lines print.

- [ ] **Step 3: Run doctor.sh**

```bash
~/.local/bin/wezterm-tmux-doctor
```
Expected: every line reads `PASS`; final line reads `N passed, 0 failed`. If any plugin line reads `FAIL` immediately after install, wait ~10 seconds (TPM clones in the background) and re-run.

- [ ] **Step 4: Re-run install.sh to confirm idempotency**

```bash
./install.sh
```
Expected: every managed path logs `Already linked: <path>` (no new backups created, no errors, and the stale-symlink cleanup loop finds nothing left to remove since Step 1 already removed it).

- [ ] **Step 5: Manually restart WezTerm and confirm behavior**

Restart WezTerm. Confirm: it auto-attaches to the `main` tmux session (via `wezterm-tmux.zsh`), `Ctrl+Space` is the working tmux prefix, `Ctrl+Space \` and `Ctrl+Space -` split panes, `Ctrl+Space f` opens the sessionizer popup, the Catppuccin theme/status bar render as before (now labeled `WezTerm` in the terminal title), and WezTerm's own keybinds (tabs, `SUPER+f` search, etc., from `NJie94/wezterm`) still work alongside tmux.

- [ ] **Step 6: Commit and push any final fixes**

```bash
cd ~/dev/dotfiles
git status
# If Steps 1-5 above required any fixes to files in this repo, stage and commit them:
git add -A
git commit -m "Fix issues found during on-machine verification" --allow-empty
git push origin master
```
