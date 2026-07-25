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

Installs any missing `tmux`/`zsh`/`git`/`fzf`/JetBrainsMono Nerd Font via
`apt` or `dnf` (asks for `sudo` as needed), sets up oh-my-zsh and
oh-my-tmux, symlinks every config into place, and clones
[`NJie94/nvim`](https://github.com/NJie94/nvim) to `~/.config/nvim` if it
isn't already there. Restart Ghostty afterward.

Ghostty itself installs automatically via `dnf` on Fedora. It is **not**
yet in Debian/Ubuntu's standard `apt` repositories, so on those distros
`install.sh` will warn instead of installing it — grab it manually from
[ghostty.org/download](https://ghostty.org/download).

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
