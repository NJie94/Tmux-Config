# Dotfiles consolidation: tmux + zsh + Ghostty, cross-platform one-click setup

## Problem

Nicholas has hand-tuned a tmux (oh-my-tmux based) + zsh + Ghostty setup on his
current Linux machine, plus a separate `NJie94/nvim` config repo. None of this
is version-controlled as a portable unit — the live config lives only in
`~/.config/*` and `~/.zshrc`. Several earlier attempts at solving this exist as
abandoned zip downloads in `~/Downloads` (`ghostty-tmux-cross-platform`,
`oh-my-tmux-ghostty-reset`, `oh-my-tmux-beautiful-fix`, `ghostty-njie94`), each
exploring a different design (e.g. a hand-rolled tmux.conf with a `Ctrl+A`
prefix and vim-style pane nav), none ever turned into a real, pullable repo.

Goal: a single git repo that can be cloned onto a fresh Linux, macOS, or
Windows (WSL2) machine and set up the whole terminal environment with one
command.

## Scope

Consolidate the **current live setup** (oh-my-tmux + Catppuccin theme +
`Ctrl+Space` prefix + zsh-as-default-shell + existing Ghostty config + existing
`ghostty-tmux.zsh` auto-attach snippet) as the base, since this is what
Nicholas has already tuned and is actively using. Cherry-pick specific
features from the abandoned cross-platform attempt: TPM plugins
(`tmux-sensible`, `tmux-resurrect`, `tmux-continuum`, `vim-tmux-navigator`),
`tmux-sessionizer`, a `doctor.sh` health check, and a WSL launcher script.
Integrate the existing separately-hosted `NJie94/nvim` config by cloning it if
absent, without duplicating or vendoring it.

Explicitly out of scope: rewriting tmux.conf from scratch, switching away from
oh-my-tmux, changing the prefix key or split keys, WSL `.cmd` launcher
automation beyond providing an editable example.

## Repo layout

```
dotfiles/
├── install.sh                       # entry point, cross-platform, idempotent
├── README.md                        # setup instructions per platform
├── tmux/
│   └── tmux.conf.local              # symlinked to ~/.config/tmux/tmux.conf.local
├── zsh/
│   ├── zshrc                        # portable base, symlinked to ~/.zshrc
│   ├── linux.zsh                    # Linux-specific tool config (sourced by zshrc on Linux)
│   ├── macos.zsh                    # macOS-specific tool config (sourced by zshrc on macOS)
│   └── ghostty-tmux.zsh             # existing auto-attach-to-tmux snippet, unchanged
├── ghostty/
│   └── config.ghostty               # symlinked to ~/.config/ghostty/config.ghostty
├── nvim/
│   └── tmux-navigator.lua.example   # copy-in glue for vim-tmux-navigator, not auto-installed
├── windows/
│   └── ghostty-wsl.cmd.example      # editable Windows-side WSL launcher
└── scripts/
    ├── doctor.sh                    # health check / verification
    └── tmux-sessionizer             # fzf-based project session picker
```

### tmux/tmux.conf.local

Carries forward the existing customizations already live on this machine:

- `prefix` = `Ctrl+Space` (not the default `Ctrl+b`, not `Ctrl+a` — avoids
  colliding with zsh/readline's line-start binding)
- `\` and `-` bound to horizontal/vertical split (in addition to stock `%`/`_`)
- `default-shell` = zsh
- Catppuccin-inspired theme (colors, status bar format) as already configured
- TPM plugin declarations: `tmux-plugins/tmux-sensible`,
  `tmux-plugins/tmux-resurrect`, `tmux-plugins/tmux-continuum`,
  `christoomey/vim-tmux-navigator`
- `tmux-continuum` autosave interval: 15 minutes (matches the abandoned
  attempt's convention)
- `prefix + f` bound to run `scripts/tmux-sessionizer`

`vim-tmux-navigator` binds unprefixed `Ctrl+h/j/k/l` at the root key table for
pane navigation — this does not conflict with the existing prefixed
`Ctrl+h`/`Ctrl+l` (previous/next window) bindings, since one requires the
prefix and the other doesn't.

### zsh/zshrc (portable base)

Sources, in order:
1. oh-my-zsh (`ZSH` env + `source $ZSH/oh-my-zsh.sh`)
2. `zsh/linux.zsh` if `$OSTYPE` matches Linux, or `zsh/macos.zsh` if it matches
   Darwin
3. `zsh/ghostty-tmux.zsh` (existing snippet, unchanged)
4. `~/.zshrc.local` if it exists (untracked, gitignored — machine-specific or
   private config lives here, never committed)

### zsh/linux.zsh

Everything from the current `~/.zshrc` that is Linux/tool-specific and not
already general shell config: dotnet, pixi, kiro-cli, distrobox, LM Studio
PATH/completions setup.

### zsh/macos.zsh

Stub file with Homebrew-equivalent placeholders (e.g. `brew shellenv`), to be
filled in once a Mac is actually set up. Not left empty/TODO in a way that
blocks install — install.sh sources it unconditionally on macOS, and an empty
or minimal file is a valid state, not a placeholder needing follow-up.

### nvim/tmux-navigator.lua.example

`~/.config/nvim` already tracks the independent `NJie94/nvim` repo. This repo
does not vendor or submodule it. `install.sh` clones
`https://github.com/NJie94/nvim` to `~/.config/nvim` only if that path doesn't
already exist; it never modifies an existing checkout. The `.lua.example` file
here is documentation/glue the user copies into their nvim config's plugin
directory manually, since automatically writing into a separately-versioned
repo is out of scope.

### windows/ghostty-wsl.cmd.example

Editable launcher script (batch/cmd) that opens Ghostty inside a named WSL2
distro. README documents replacing the placeholder distro name with the
output of `wsl.exe --list --quiet`. Not automatically installed or executed by
`install.sh` (which only ever runs inside the target shell, not on the Windows
host side).

## install.sh flow

1. Detect OS: Linux, macOS, or WSL2 (via `/proc/version` containing
   `microsoft`/`WSL` on Linux).
2. For each dependency (`tmux` >= 3.2, `zsh`, `git`, `fzf`, JetBrainsMono
   Nerd Font — matching the font already set in `ghostty/config.ghostty` —
   Ghostty, oh-my-zsh, oh-my-tmux, TPM): check presence/version; if missing,
   install via the platform's package manager (`apt`/`dnf` on Linux, `brew` on
   macOS; WSL2 uses the Linux distro's package manager same as Linux).
   - oh-my-tmux: clone `gpakosz/.tmux` to `~/.local/share/oh-my-tmux` if
     missing, symlink `~/.config/tmux/tmux.conf` to its `.tmux.conf`.
   - TPM: clone `tmux-plugins/tpm` to `~/.tmux/plugins/tpm` if missing.
3. Clone `NJie94/nvim` to `~/.config/nvim` only if that path doesn't exist.
4. For each config target path (`~/.config/tmux/tmux.conf.local`,
   `~/.config/ghostty/config.ghostty`, `~/.zshrc`, `~/.config/zsh/linux.zsh`,
   `~/.config/zsh/macos.zsh`, `~/.config/zsh/ghostty-tmux.zsh`): if a real
   file (not a symlink) already exists there, move it to
   `<path>.bak.<timestamp>` before symlinking the repo's copy into place.
5. Create empty `~/.zshrc.local` if missing. It lives at `~/.zshrc.local`,
   outside the repo entirely, so it is never tracked or committed by
   anything install.sh does.
6. Run TPM's plugin install non-interactively so the four plugins are pulled
   down immediately rather than requiring a manual `prefix + I` afterward.
7. Print a summary: what was installed, what was backed up (with paths), and
   manual next steps (copy `nvim/tmux-navigator.lua.example` into the nvim
   config; on Windows, edit and use `windows/ghostty-wsl.cmd.example`).

Re-running `install.sh` at any time (e.g. after `git pull`) is safe: symlinks
that already point at the repo are left alone, missing dependencies are
(re-)checked, nothing is ever backed up or overwritten if it's already the
expected symlink.

## Verification: scripts/doctor.sh

Read-only checks, each printing pass/fail:

- `tmux -V` >= 3.2, `ghostty +version` present
- Terminal capability: RGB/truecolor support, `$TERM` is `tmux-256color`
  inside tmux
- TPM present at `~/.tmux/plugins/tpm` and all four plugin directories exist
  under it
- Each managed path (tmux.conf.local, config.ghostty, .zshrc, os zsh files) is
  a symlink pointing into the repo
- `~/.config/nvim` exists and is a git checkout of `NJie94/nvim`
- `fzf` and `tmux-sessionizer` are on `PATH`

## README.md

Documents setup per platform, each as its own section:

- **Linux**: prerequisites, `git clone` + `./install.sh`, restart Ghostty
- **macOS**: same flow via Homebrew-installed deps, note on `macos.zsh` being
  a stub to fill in
- **Windows (WSL2)**: install WSL2 + a distro, install Ghostty/tmux/zsh/git/fzf
  *inside* the distro, run `./install.sh` inside WSL, then use/edit
  `windows/ghostty-wsl.cmd.example` on the Windows side to launch Ghostty
  attached to that distro

Plus: keymap reference (prefix, splits, sessionizer, copy mode), plugin list,
`doctor.sh` usage, and troubleshooting notes (matching the level of detail the
abandoned attempt's README had).

## Testing

No automated test suite — this is shell/config, not application code.
Validation is:
1. Run `install.sh` on this machine (already has the target state mostly in
   place) and confirm it's a no-op / only creates missing pieces
   (`tmux-sessionizer`, TPM, plugins) without touching already-correct
   symlinks.
2. Run `scripts/doctor.sh` and confirm all checks pass.
3. Manually restart Ghostty and confirm tmux auto-attach, prefix, splits,
   theme, and `prefix + f` sessionizer all work as before.
