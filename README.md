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

Installs any missing `tmux`/`zsh`/`git`/`fzf`/JetBrainsMono Nerd Font via
`apt` or `dnf` (asks for `sudo` as needed), sets up oh-my-zsh and
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
lives inside a WSL2 distro. Getting WezTerm to launch straight into it
takes a few manual one-time steps on the Windows side, because native
WezTerm reads its config from the Windows filesystem, not from anything
inside WSL.

1. Install WSL2 and a Linux distro (e.g. Ubuntu) from an elevated PowerShell:
   `wsl --install`.
2. Inside that distro, follow the **Linux** install steps above. If zsh
   isn't already your login shell there, set it once:
   `chsh -s $(which zsh)`.
3. On the Windows side, install WezTerm natively from
   [wezterm.org/installation](https://wezterm.org/installation) (or
   `winget install wez.wezterm`).
4. Still on Windows, clone the same WezTerm config to where native WezTerm
   actually reads it from — a separate clone from the one `install.sh`
   made inside WSL, since Windows and WSL don't share this path:
   ```powershell
   git clone https://github.com/NJie94/wezterm $env:USERPROFILE\.config\wezterm
   ```
5. Make sure `TERM_PROGRAM` crosses the WSL boundary, so
   `wezterm-tmux.zsh`'s auto-attach guard can see it. Check what `WSLENV`
   is already set to first (`[System.Environment]::GetEnvironmentVariable('WSLENV','User')`
   in PowerShell) and append to it rather than overwrite if it's non-empty:
   ```powershell
   setx WSLENV "TERM_PROGRAM/u"
   ```
   Restart WezTerm after this for it to take effect.

**Known gap:** `NJie94/wezterm`'s Windows launch config
(`config/launch.lua`) opens the WSL2 distro via its *default* login shell
rather than explicitly invoking zsh, and doesn't export `TERM_PROGRAM`
itself — steps 2 and 5 above work around that from the outside. A cleaner
long-term fix is a small edit to that repo's Windows `default_prog` (e.g.
`{"wsl.exe", "-d", "Ubuntu", "--", "zsh", "-l"}`), which is out of scope
here since this repo doesn't modify `NJie94/wezterm`.

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
