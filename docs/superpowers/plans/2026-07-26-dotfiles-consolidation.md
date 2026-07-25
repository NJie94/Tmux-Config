# Dotfiles Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Populate the `dotfiles` repo (already created at `~/dev/dotfiles`, pushed to `github.com/NJie94/dotfiles`) with the actual tmux/zsh/Ghostty configs, an `install.sh` that symlinks them onto a fresh Linux/macOS/WSL2 machine and bootstraps every dependency, a `doctor.sh` health check, and a README — then run it on this machine to confirm it reproduces the live setup.

**Architecture:** A flat, symlink-based dotfiles repo. `install.sh` is the only executable entry point: it detects the OS, installs missing dependencies via the platform package manager, clones the two upstream frameworks this setup depends on (oh-my-tmux, oh-my-zsh) plus their sub-plugins, then symlinks every managed config file from the repo into its real target path (backing up any real file it would overwrite). `scripts/doctor.sh` re-checks all of that non-destructively.

**Tech Stack:** POSIX-ish Bash (`set -euo pipefail`), tmux 3.2+ (oh-my-tmux), zsh (oh-my-zsh), Ghostty, fzf, git.

## Global Constraints

- Repo root: `~/dev/dotfiles`, remote `https://github.com/NJie94/dotfiles.git`, branch `master`.
- Platforms: Linux, macOS, Windows-via-WSL2 (spec §Scope).
- Install method: symlinks only, never copies (spec §Install method decision).
- `install.sh` must be idempotent — safe to re-run any time (spec §install.sh flow point 7).
- Any real (non-symlink) file at a target path must be backed up (renamed, not deleted) before being replaced (spec §install.sh flow point 4).
- tmux plugin manager path for this setup is **`~/.config/tmux/plugins`**, not the commonly-documented `~/.tmux/plugins` — oh-my-tmux derives it as `dirname($TMUX_CONF)/plugins`, and `$TMUX_CONF` here is `~/.config/tmux/tmux.conf` (verified live on this machine: that directory already exists and is empty, pre-created by oh-my-tmux itself).
- Do **not** add `set -g @plugin 'tmux-plugins/tpm'` or `run '~/.tmux/plugins/tpm/tpm'` to `tmux.conf.local` — oh-my-tmux's own file explicitly says not to (it manages TPM internally once any other `@plugin` line is present and `tmux_conf_update_plugins_on_launch=true`, which is already set).
- `~/.zshrc.local` is never created inside the repo and never tracked — it must always be a plain file directly at `$HOME`, gitignored from nowhere because it's simply never inside the repo tree.
- JetBrainsMono Nerd Font is the specific font required (matches `ghostty/config.ghostty`'s `font-family`).

---

### Task 1: `tmux/tmux.conf.local`

**Files:**
- Create: `tmux/tmux.conf.local`

**Interfaces:**
- Produces: the file symlinked by Task 9's `install.sh` to `~/.config/tmux/tmux.conf.local`. Declares `@plugin` lines consumed by oh-my-tmux's built-in TPM integration (no other task reads these values directly).

- [ ] **Step 1: Write the file**

Copy the exact live content below (this is the current working `~/.config/tmux/tmux.conf.local` on this machine, byte-for-byte, so the base behavior doesn't change), then append the new TPM/sessionizer section at the end.

```bash
cp ~/.config/tmux/tmux.conf.local ~/dev/dotfiles/tmux/tmux.conf.local
```

- [ ] **Step 2: Append the TPM plugins + sessionizer section**

Append this block to the end of `tmux/tmux.conf.local`:

```tmux
# --- Nicholas: TPM plugins + sessionizer --------------------------------------

# tmux-sessionizer: fzf-driven project/session picker. scripts/tmux-sessionizer
# in this repo is symlinked to ~/.local/bin/tmux-sessionizer by install.sh.
# This overrides oh-my-tmux's default `prefix + f` (find-window) binding.
bind f display-popup -E "tmux-sessionizer" #!important

# Oh My Tmux integrates its own TPM instance automatically once any @plugin
# line is declared here (tmux_conf_update_plugins_on_launch=true, set above
# in this file). Do NOT add `set -g @plugin 'tmux-plugins/tpm'` or `run
# '~/.tmux/plugins/tpm/tpm'` -- oh-my-tmux manages TPM itself and installs
# plugins under $(dirname "$TMUX_CONF")/plugins, i.e. ~/.config/tmux/plugins
# for this setup.
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'christoomey/vim-tmux-navigator'

set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# --- End Nicholas: TPM plugins + sessionizer -----------------------------------
```

- [ ] **Step 3: Verify no duplicate/conflicting `bind f`**

Run: `grep -n "bind.*[[:space:]]f[[:space:]]" ~/dev/dotfiles/tmux/tmux.conf.local`
Expected: only one line matches — the new `bind f display-popup -E "tmux-sessionizer" #!important` line (the original file has no other standalone `f` binding at column position for a key named exactly `f`).

- [ ] **Step 4: Commit**

```bash
cd ~/dev/dotfiles
git add tmux/tmux.conf.local
git commit -m "Add tmux.conf.local: base config plus TPM plugins and sessionizer binding"
```

---

### Task 2: `zsh/zshrc` (portable base)

**Files:**
- Create: `zsh/zshrc`

**Interfaces:**
- Produces: the file symlinked by Task 9 to `~/.zshrc`. Sources (by path, at runtime) `~/.config/zsh/ghostty-tmux.zsh` (Task 3), `~/.config/zsh/linux.zsh` or `~/.config/zsh/macos.zsh` (Task 3), and `~/.zshrc.local` (created empty by Task 9, never part of this repo).

- [ ] **Step 1: Write the file**

```zsh
# Ghostty + tmux integration
[[ -r "$HOME/.config/zsh/ghostty-tmux.zsh" ]] && source "$HOME/.config/zsh/ghostty-tmux.zsh"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Use fd for fzf file search
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# OS-specific extras (installed by install.sh to ~/.config/zsh/)
[[ -r "$HOME/.config/zsh/linux.zsh" ]] && source "$HOME/.config/zsh/linux.zsh"
[[ -r "$HOME/.config/zsh/macos.zsh" ]] && source "$HOME/.config/zsh/macos.zsh"

# Machine-specific / private config, never committed.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
```

Save this to `~/dev/dotfiles/zsh/zshrc`.

- [ ] **Step 2: Verify it parses as valid zsh**

Run: `zsh -n ~/dev/dotfiles/zsh/zshrc && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
cd ~/dev/dotfiles
git add zsh/zshrc
git commit -m "Add portable zshrc base"
```

---

### Task 3: `zsh/linux.zsh`, `zsh/macos.zsh`, `zsh/ghostty-tmux.zsh`

**Files:**
- Create: `zsh/linux.zsh`
- Create: `zsh/macos.zsh`
- Create: `zsh/ghostty-tmux.zsh`

**Interfaces:**
- Consumes: nothing (leaf shell files).
- Produces: files symlinked by Task 9 to `~/.config/zsh/linux.zsh`, `~/.config/zsh/macos.zsh` (only the one matching the detected OS), and `~/.config/zsh/ghostty-tmux.zsh` (always). Sourced at runtime by `zsh/zshrc` (Task 2).

- [ ] **Step 1: Write `zsh/linux.zsh`**

```zsh
# Linux-specific shell config, sourced by zsh/zshrc on Linux and WSL2.
#
# Note: on the original machine this config was consolidated from, the Kiro
# CLI pre-block below ran before Powerlevel10k's instant-prompt block at the
# very top of ~/.zshrc. Sourced from here it now runs after oh-my-zsh loads
# instead. If Kiro CLI's pre-block ever prints output, it will trip p10k's
# instant-prompt warning; it hasn't shown a problem so far.

# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/zshrc.pre.zsh"

# Various tools export
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

#fcitx
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx

#kiro CLI
export PATH="$HOME/.local/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$HOME/.dotnet:$HOME/.dotnet/tools
export PATH=$PATH:/usr/local/share/dotnet
eval "$(dotnet completions script zsh)"
export DOTNET_ROOT=/usr/lib64/dotnet
export PATH="$PATH:/usr/lib64/dotnet"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/zshrc.post.zsh"

# Pixi Zsh completion
if command -v pixi >/dev/null 2>&1; then
  eval "$(pixi completion --shell zsh)"
fi

# Distrobox uses Docker
export DBX_CONTAINER_MANAGER="docker"

# Pixi
export PATH="$HOME/.pixi/bin:$PATH"
```

Save to `~/dev/dotfiles/zsh/linux.zsh`.

- [ ] **Step 2: Write `zsh/macos.zsh`**

```zsh
# macOS-specific shell config, sourced by zsh/zshrc on macOS.
# Fill in once a Mac is set up. Homebrew's shellenv is the most common
# addition here, e.g.:
#
#   eval "$(/opt/homebrew/bin/brew shellenv)"
```

Save to `~/dev/dotfiles/zsh/macos.zsh`.

- [ ] **Step 3: Write `zsh/ghostty-tmux.zsh`**

```zsh
# Source this near the top of ~/.zshrc.
# It is intentionally inactive outside Ghostty.

if [[ "${TERM_PROGRAM:-}" == ghostty ]]; then
  # Ghostty injects integration into the first zsh it starts. tmux then starts
  # another zsh, so source the integration again inside tmux.
  if [[ -n "${TMUX:-}" && -n "${GHOSTTY_RESOURCES_DIR:-}" ]]; then
    _ghostty_zsh_integration="${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
    [[ -r "$_ghostty_zsh_integration" ]] && source "$_ghostty_zsh_integration"
    unset _ghostty_zsh_integration
  fi

  # Automatically enter the persistent main session only for an interactive,
  # local Ghostty shell. Set GHOSTTY_AUTO_TMUX=0 to bypass once, or permanently.
  if [[ -o interactive && -z "${TMUX:-}" && "${GHOSTTY_AUTO_TMUX:-1}" == 1 ]]; then
    if command -v tmux >/dev/null 2>&1; then
      exec tmux new-session -A -s "${GHOSTTY_TMUX_SESSION:-main}"
    fi
  fi
fi
```

Save to `~/dev/dotfiles/zsh/ghostty-tmux.zsh`. (This must be byte-identical to the current live `~/.config/zsh/ghostty-tmux.zsh` — diff to confirm in the next step.)

- [ ] **Step 4: Verify all three parse and match**

```bash
zsh -n ~/dev/dotfiles/zsh/linux.zsh && echo "linux.zsh OK"
zsh -n ~/dev/dotfiles/zsh/macos.zsh && echo "macos.zsh OK"
zsh -n ~/dev/dotfiles/zsh/ghostty-tmux.zsh && echo "ghostty-tmux.zsh OK"
diff ~/dev/dotfiles/zsh/ghostty-tmux.zsh ~/.config/zsh/ghostty-tmux.zsh && echo "ghostty-tmux.zsh matches live file"
```
Expected: all four lines print, `diff` prints nothing before its echo (identical files).

- [ ] **Step 5: Commit**

```bash
cd ~/dev/dotfiles
git add zsh/linux.zsh zsh/macos.zsh zsh/ghostty-tmux.zsh
git commit -m "Add OS-specific zsh files and ghostty-tmux auto-attach snippet"
```

---

### Task 4: `ghostty/config.ghostty`

**Files:**
- Create: `ghostty/config.ghostty`

**Interfaces:**
- Produces: file symlinked by Task 9 to `~/.config/ghostty/config.ghostty`.

- [ ] **Step 1: Copy the live file verbatim**

```bash
mkdir -p ~/dev/dotfiles/ghostty
cp ~/.config/ghostty/config.ghostty ~/dev/dotfiles/ghostty/config.ghostty
```

- [ ] **Step 2: Verify it matches the live file**

Run: `diff ~/.config/ghostty/config.ghostty ~/dev/dotfiles/ghostty/config.ghostty && echo IDENTICAL`
Expected: `IDENTICAL`

- [ ] **Step 3: Commit**

```bash
cd ~/dev/dotfiles
git add ghostty/config.ghostty
git commit -m "Add Ghostty config"
```

---

### Task 5: `scripts/tmux-sessionizer`

**Files:**
- Create: `scripts/tmux-sessionizer`

**Interfaces:**
- Consumes: `fzf`, `tmux` (both required to be on `PATH`; Task 9 ensures this).
- Produces: executable script symlinked by Task 9 to `~/.local/bin/tmux-sessionizer`. Invoked by the `bind f display-popup -E "tmux-sessionizer"` binding from Task 1.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

search_paths=("$HOME/dev" "$HOME")

if [[ $# -eq 1 ]]; then
  selected="$1"
else
  selected=$(find "${search_paths[@]}" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | fzf)
fi

if [[ -z "${selected:-}" ]]; then
  exit 0
fi

selected_name=$(basename "$selected" | tr . _)

if [[ -z "${TMUX:-}" ]] && ! pgrep -x tmux >/dev/null 2>&1; then
  tmux new-session -s "$selected_name" -c "$selected"
  exit 0
fi

if ! tmux has-session -t "$selected_name" 2>/dev/null; then
  tmux new-session -ds "$selected_name" -c "$selected"
fi

if [[ -z "${TMUX:-}" ]]; then
  tmux attach-session -t "$selected_name"
else
  tmux switch-client -t "$selected_name"
fi
```

Save to `~/dev/dotfiles/scripts/tmux-sessionizer` (no file extension — it's invoked by bare name once on `PATH`).

- [ ] **Step 2: Make it executable and verify syntax**

```bash
chmod +x ~/dev/dotfiles/scripts/tmux-sessionizer
bash -n ~/dev/dotfiles/scripts/tmux-sessionizer && echo OK
```
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
cd ~/dev/dotfiles
git add scripts/tmux-sessionizer
git commit -m "Add tmux-sessionizer project picker script"
```

---

### Task 6: `scripts/doctor.sh`

**Files:**
- Create: `scripts/doctor.sh`

**Interfaces:**
- Produces: executable script symlinked by Task 9 to `~/.local/bin/ghostty-tmux-doctor`. Depends on all paths Task 9 establishes (read-only checks, no side effects).

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0
fail=0

check() {
  local desc="$1" cond="$2"
  if eval "$cond"; then
    printf 'PASS  %s\n' "$desc"
    pass=$((pass + 1))
  else
    printf 'FAIL  %s\n' "$desc"
    fail=$((fail + 1))
  fi
}

is_symlink_into_repo() {
  local path="$1" repo_rel="$2"
  [[ -L "$path" ]] && [[ "$(readlink -f "$path")" == "$REPO_DIR/$repo_rel" ]]
}

check "tmux >= 3.2 installed" \
  '[[ -n "$(command -v tmux)" ]] && [[ "$(tmux -V | grep -oE "[0-9]+" | head -1)" -ge 3 ]]'
check "ghostty installed" 'command -v ghostty >/dev/null 2>&1'
check "zsh installed" 'command -v zsh >/dev/null 2>&1'
check "fzf installed" 'command -v fzf >/dev/null 2>&1'
check "git installed" 'command -v git >/dev/null 2>&1'
check "oh-my-tmux present" '[[ -d "$HOME/.local/share/oh-my-tmux" ]]'
check "oh-my-zsh present" '[[ -d "$HOME/.oh-my-zsh" ]]'
check "powerlevel10k theme installed" '[[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]'
check "zsh-autosuggestions plugin installed" '[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]'
check "zsh-syntax-highlighting plugin installed" '[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]'

# oh-my-tmux installs TPM plugins under dirname($TMUX_CONF)/plugins. This
# repo's install.sh always symlinks ~/.config/tmux/tmux.conf, so that path is
# always ~/.config/tmux/plugins for this setup.
TMUX_PLUGINS_DIR="$HOME/.config/tmux/plugins"
check "TPM present" "[[ -d \"$TMUX_PLUGINS_DIR/tpm\" ]]"
check "tmux-sensible plugin installed" "[[ -d \"$TMUX_PLUGINS_DIR/tmux-sensible\" ]]"
check "tmux-resurrect plugin installed" "[[ -d \"$TMUX_PLUGINS_DIR/tmux-resurrect\" ]]"
check "tmux-continuum plugin installed" "[[ -d \"$TMUX_PLUGINS_DIR/tmux-continuum\" ]]"
check "vim-tmux-navigator plugin installed" "[[ -d \"$TMUX_PLUGINS_DIR/vim-tmux-navigator\" ]]"

check "~/.config/tmux/tmux.conf is a symlink to oh-my-tmux" \
  '[[ -L "$HOME/.config/tmux/tmux.conf" ]] && [[ "$(readlink -f "$HOME/.config/tmux/tmux.conf")" == "$HOME/.local/share/oh-my-tmux/.tmux.conf" ]]'
check "~/.config/tmux/tmux.conf.local is a symlink into the dotfiles repo" \
  'is_symlink_into_repo "$HOME/.config/tmux/tmux.conf.local" "tmux/tmux.conf.local"'
check "~/.config/ghostty/config.ghostty is a symlink into the dotfiles repo" \
  'is_symlink_into_repo "$HOME/.config/ghostty/config.ghostty" "ghostty/config.ghostty"'
check "~/.zshrc is a symlink into the dotfiles repo" \
  'is_symlink_into_repo "$HOME/.zshrc" "zsh/zshrc"'
check "~/.config/zsh/ghostty-tmux.zsh is a symlink into the dotfiles repo" \
  'is_symlink_into_repo "$HOME/.config/zsh/ghostty-tmux.zsh" "zsh/ghostty-tmux.zsh"'
check "~/.config/nvim exists and is a git checkout" '[[ -d "$HOME/.config/nvim/.git" ]]'
check "tmux-sessionizer on PATH" 'command -v tmux-sessionizer >/dev/null 2>&1'
check "~/.zshrc.local exists" '[[ -f "$HOME/.zshrc.local" ]]'
check "tmux reports RGB/truecolor capability" 'tmux info 2>/dev/null | grep -q "Tc:"'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
```

Save to `~/dev/dotfiles/scripts/doctor.sh`.

- [ ] **Step 2: Make it executable and verify syntax**

```bash
chmod +x ~/dev/dotfiles/scripts/doctor.sh
bash -n ~/dev/dotfiles/scripts/doctor.sh && echo OK
```
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
cd ~/dev/dotfiles
git add scripts/doctor.sh
git commit -m "Add doctor.sh health check script"
```

---

### Task 7: `nvim/tmux-navigator.lua.example` and `windows/ghostty-wsl.cmd.example`

**Files:**
- Create: `nvim/tmux-navigator.lua.example`
- Create: `windows/ghostty-wsl.cmd.example`

**Interfaces:**
- Produces: two standalone example files, never symlinked or executed by `install.sh`. Copied/edited manually by the user per README instructions (Task 10).

- [ ] **Step 1: Write `nvim/tmux-navigator.lua.example`**

```lua
-- Enables seamless Ctrl+h/j/k/l navigation between Neovim splits and tmux
-- panes (see tmux/tmux.conf.local's christoomey/vim-tmux-navigator plugin).
-- Written for lazy.nvim; adapt the spec table if this nvim config uses a
-- different plugin manager. Copy this file into the nvim config's plugin
-- directory (e.g. ~/.config/nvim/lua/plugins/tmux-navigator.lua).
return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  keys = {
    { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
    { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
    { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
    { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
    { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
  },
}
```

Save to `~/dev/dotfiles/nvim/tmux-navigator.lua.example`.

- [ ] **Step 2: Write `windows/ghostty-wsl.cmd.example`**

```bat
@echo off
REM Launches Ghostty inside a specific WSL2 distribution.
REM Replace DISTRO_NAME below with one line of output from:
REM   wsl.exe --list --quiet
set DISTRO_NAME=Ubuntu
wsl.exe -d %DISTRO_NAME% -- ghostty
```

Save to `~/dev/dotfiles/windows/ghostty-wsl.cmd.example`.

- [ ] **Step 3: Verify both files exist**

Run: `test -f ~/dev/dotfiles/nvim/tmux-navigator.lua.example && test -f ~/dev/dotfiles/windows/ghostty-wsl.cmd.example && echo OK`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
cd ~/dev/dotfiles
git add nvim/tmux-navigator.lua.example windows/ghostty-wsl.cmd.example
git commit -m "Add nvim tmux-navigator example and Windows WSL launcher example"
```

---

### Task 8: `install.sh`

**Files:**
- Create: `install.sh`

**Interfaces:**
- Consumes: `tmux/tmux.conf.local` (Task 1), `zsh/zshrc`, `zsh/linux.zsh`, `zsh/macos.zsh`, `zsh/ghostty-tmux.zsh` (Tasks 2–3), `ghostty/config.ghostty` (Task 4), `scripts/tmux-sessionizer`, `scripts/doctor.sh` (Tasks 5–6) — all read relative to `$REPO_DIR` (the directory containing `install.sh`).
- Produces: the fully-configured machine state that Task 6's `doctor.sh` checks.

- [ ] **Step 1: Write the script**

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

if ! command -v ghostty >/dev/null 2>&1; then
  case "$OS" in
    macos) brew install --cask ghostty ;;
    linux) linux_pkg_install ghostty || warn "Install Ghostty manually: https://ghostty.org/download" ;;
    wsl2) linux_pkg_install ghostty || warn "Install Ghostty manually inside this WSL2 distro: https://ghostty.org/download" ;;
    *) warn "Unsupported OS; install Ghostty manually" ;;
  esac
fi

font_installed() {
  fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font" && return 0
  [[ "$OS" == macos ]] && ls "$HOME/Library/Fonts" 2>/dev/null | grep -qi "JetBrainsMono" && return 0
  return 1
}

if ! font_installed; then
  log "Installing JetBrainsMono Nerd Font"
  case "$OS" in
    macos) brew install --cask font-jetbrains-mono-nerd-font ;;
    linux|wsl2)
      mkdir -p "$HOME/.local/share/fonts"
      curl -fLo /tmp/JetBrainsMono.zip \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
      unzip -o /tmp/JetBrainsMono.zip -d "$HOME/.local/share/fonts" >/dev/null
      fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
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

chmod +x "$REPO_DIR/scripts/tmux-sessionizer" "$REPO_DIR/scripts/doctor.sh"

link "$HOME/.local/share/oh-my-tmux/.tmux.conf" "$HOME/.config/tmux/tmux.conf"
link "$REPO_DIR/tmux/tmux.conf.local" "$HOME/.config/tmux/tmux.conf.local"
link "$REPO_DIR/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
link "$REPO_DIR/zsh/zshrc" "$HOME/.zshrc"
link "$REPO_DIR/zsh/ghostty-tmux.zsh" "$HOME/.config/zsh/ghostty-tmux.zsh"

case "$OS" in
  macos) link "$REPO_DIR/zsh/macos.zsh" "$HOME/.config/zsh/macos.zsh" ;;
  linux|wsl2) link "$REPO_DIR/zsh/linux.zsh" "$HOME/.config/zsh/linux.zsh" ;;
esac

link "$REPO_DIR/scripts/tmux-sessionizer" "$HOME/.local/bin/tmux-sessionizer"
link "$REPO_DIR/scripts/doctor.sh" "$HOME/.local/bin/ghostty-tmux-doctor"

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
log "  - Restart Ghostty to pick up the new config."
log "  - Neovim: copy $REPO_DIR/nvim/tmux-navigator.lua.example into your nvim config's plugin directory."
if [[ "$OS" == wsl2 ]]; then
  log "  - Windows: edit and use $REPO_DIR/windows/ghostty-wsl.cmd.example to launch Ghostty from Windows."
fi
log "Run '$HOME/.local/bin/ghostty-tmux-doctor' to verify the setup (plugin clones may take a few seconds — re-run if it reports missing plugins right after install)."
```

Save to `~/dev/dotfiles/install.sh`.

- [ ] **Step 2: Make it executable and verify syntax**

```bash
chmod +x ~/dev/dotfiles/install.sh
bash -n ~/dev/dotfiles/install.sh && echo OK
```
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
cd ~/dev/dotfiles
git add install.sh
git commit -m "Add install.sh: cross-platform dependency bootstrap and symlink installer"
```

---

### Task 9: `README.md`

**Files:**
- Create: `README.md` (overwrite the placeholder created by `gh repo create`, if any)

**Interfaces:**
- Consumes: nothing (documentation only, references paths/commands from Tasks 1–8).

- [ ] **Step 1: Write the file**

```markdown
# dotfiles

One tmux (oh-my-tmux) + zsh (oh-my-zsh) + Ghostty setup, kept in one repo and
installed with a single script on Linux, macOS, or Windows (via WSL2).

## What's here

- `tmux/tmux.conf.local` — prefix `Ctrl+Space`, `\`/`-` splits, Catppuccin
  theme, zsh as the tmux shell, TPM plugins (tmux-sensible, tmux-resurrect,
  tmux-continuum, vim-tmux-navigator), `prefix + f` bound to a project
  session picker.
- `zsh/zshrc` — portable oh-my-zsh base (Powerlevel10k, fzf, autosuggestions,
  syntax highlighting), sourcing an OS-specific file and an untracked
  `~/.zshrc.local` for anything machine-specific or private.
- `zsh/linux.zsh` / `zsh/macos.zsh` — OS-specific shell config.
- `ghostty/config.ghostty` — Ghostty's visual layer (font, theme, padding);
  tmux owns sessions/windows/panes/status.
- `scripts/tmux-sessionizer` — fzf-based project/session picker.
- `scripts/doctor.sh` — read-only health check for the whole setup.
- `nvim/tmux-navigator.lua.example` — copy into a separately-managed nvim
  config to get seamless `Ctrl+h/j/k/l` nvim/tmux pane navigation.
- `windows/ghostty-wsl.cmd.example` — launches Ghostty inside a named WSL2
  distro from the Windows side.

## Install

### Linux

```sh
git clone https://github.com/NJie94/dotfiles ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

Installs any missing `tmux`/`zsh`/`git`/`fzf`/Ghostty/JetBrainsMono Nerd Font
via `apt` or `dnf` (asks for `sudo` as needed), sets up oh-my-zsh and
oh-my-tmux, symlinks every config into place, and clones
[`NJie94/nvim`](https://github.com/NJie94/nvim) to `~/.config/nvim` if it
isn't already there. Restart Ghostty afterward.

### macOS

Same flow, via Homebrew:

```sh
git clone https://github.com/NJie94/dotfiles ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

`zsh/macos.zsh` starts as a near-empty stub (a placeholder for
`brew shellenv` and any Mac-only tool config) — fill it in as needed; it's
sourced automatically by `zsh/zshrc` once present.

### Windows (WSL2)

Ghostty has no native Windows GUI; on Windows it always runs as the Linux
build inside WSL2 + WSLg.

1. Install WSL2 and a Linux distro (e.g. Ubuntu) from an elevated PowerShell:
   `wsl --install`.
2. Inside that distro, follow the **Linux** install steps above.
3. From Windows, edit `windows/ghostty-wsl.cmd.example`: replace
   `DISTRO_NAME` with a line from `wsl.exe --list --quiet`, then run it (or
   save it as a `.cmd` shortcut) to launch Ghostty attached to that distro.

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

## Verify

```sh
~/.local/bin/ghostty-tmux-doctor
```

Prints a pass/fail line for every dependency, plugin, and symlink this setup
depends on.

## Re-running install

`./install.sh` is safe to run again any time (e.g. after `git pull`) — it
only installs what's missing and never overwrites a symlink that already
points into this repo. Any real file it would otherwise replace is backed up
first as `<path>.bak.<timestamp>`.
```

Save to `~/dev/dotfiles/README.md`.

- [ ] **Step 2: Verify it references only files that exist**

Run: `grep -oE '`[a-zA-Z0-9_./-]+`' ~/dev/dotfiles/README.md | tr -d '`' | grep -E '^(tmux|zsh|ghostty|scripts|nvim|windows)/' | sort -u | while read -r f; do test -f "$HOME/dev/dotfiles/$f" || echo "MISSING: $f"; done`
Expected: no output (every referenced repo-relative file path exists).

- [ ] **Step 3: Commit**

```bash
cd ~/dev/dotfiles
git add README.md
git commit -m "Write README with per-platform install instructions and keymap reference"
```

---

### Task 10: Run and verify on this machine

**Files:** none created; this task exercises Tasks 1–9's output against the live machine.

**Interfaces:**
- Consumes: `install.sh` (Task 8), `scripts/doctor.sh` (Task 6).

- [ ] **Step 1: Run install.sh**

```bash
cd ~/dev/dotfiles
./install.sh
```
Expected: no errors; existing real files at each managed path (the current live `tmux.conf.local`, `config.ghostty`, `.zshrc`, `ghostty-tmux.zsh`, `linux.zsh` if present) get backed up to `<path>.bak.<timestamp>` and replaced with symlinks into `~/dev/dotfiles`. Missing pieces (TPM plugins, `tmux-sessionizer` on `PATH`) get created.

- [ ] **Step 2: Run doctor.sh**

```bash
~/.local/bin/ghostty-tmux-doctor
```
Expected: every line reads `PASS`; final line reads `N passed, 0 failed`. If any plugin line reads `FAIL` immediately after install, wait ~10 seconds (TPM clones in the background) and re-run.

- [ ] **Step 3: Re-run install.sh to confirm idempotency**

```bash
./install.sh
```
Expected: every managed path logs `Already linked: <path>` (no new backups created, no errors).

- [ ] **Step 4: Manually restart Ghostty and confirm behavior**

Restart Ghostty. Confirm: it auto-attaches to the `main` tmux session, `Ctrl+Space` is the working prefix, `Ctrl+Space \` and `Ctrl+Space -` split panes, `Ctrl+Space f` opens the sessionizer popup, and the Catppuccin theme/status bar render as before.

- [ ] **Step 5: Commit and push any final fixes**

```bash
cd ~/dev/dotfiles
git status
# If Steps 1-4 above required any fixes to files in this repo, stage and commit them:
git add -A
git commit -m "Fix issues found during on-machine verification" --allow-empty
git push origin master
```
