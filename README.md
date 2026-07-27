# Tmux Config

A portable [tmux](https://github.com/tmux/tmux) setup built on [Oh My Tmux](https://github.com/gpakosz/.tmux).

This repo covers tmux only. It's one piece of a multi-repo terminal environment:

* [`NJie94/ZshConfig`](https://github.com/NJie94/ZshConfig) — zsh, Oh My Zsh, Powerlevel10k, fzf
* [`NJie94/wezterm`](https://github.com/NJie94/wezterm) — WezTerm terminal configuration
* [`NJie94/nvim`](https://github.com/NJie94/nvim) — Neovim configuration

## Features

* Stock tmux keybindings with the standard `Ctrl+b` prefix
* Catppuccin-inspired tmux theme
* Mouse support
* Large tmux scrollback history
* Persistent tmux sessions (`tmux-resurrect` / `tmux-continuum`)
* Seamless navigation between tmux panes and Neovim splits (`vim-tmux-navigator`)
* Project session picker (`tmux-sessionizer`)
* Portable Linux, macOS, and WSL2 configuration
* Safe, repeatable installation
* Read-only environment health check

## Repository structure

| Path                       | Purpose                                                      |
| --------------------------- | ------------------------------------------------------------ |
| `tmux/tmux.conf.local`      | Oh My Tmux settings, theme, and plugin list                  |
| `scripts/tmux-sessionizer`  | fzf-based project and tmux session picker                    |
| `scripts/doctor.sh`         | Checks dependencies, plugins, and configuration symlinks     |

## Install

### Linux

```sh
git clone https://github.com/NJie94/Tmux-Config ~/dev/Tmux-Config
cd ~/dev/Tmux-Config
./install.sh
```

The installer sets up missing dependencies where supported (`tmux`, `git`) and
installs Oh My Tmux, then creates the required configuration symlinks.

### macOS

[Homebrew](https://brew.sh) must already be installed. The installer exits with instructions when `brew` cannot be found.

```sh
git clone https://github.com/NJie94/Tmux-Config ~/dev/Tmux-Config
cd ~/dev/Tmux-Config
./install.sh
```

### Windows with WSL2

tmux runs inside the WSL2 Linux distribution; the terminal itself (WezTerm) is
configured separately — see [`NJie94/wezterm`](https://github.com/NJie94/wezterm)
for the native Windows setup.

```sh
git clone https://github.com/NJie94/Tmux-Config ~/dev/Tmux-Config
cd ~/dev/Tmux-Config
./install.sh
```

## Using tmux

### Understanding the prefix

The default tmux prefix is:

```text
Ctrl+b
```

tmux shortcuts are normally entered as two separate steps:

1. Press `Ctrl+b`.
2. Release both keys.
3. Press the command key.

For example, to create a window:

```text
Ctrl+b, then c
```

It is not necessary to hold `Ctrl+b` while pressing `c`.

## tmux shortcut cheat sheet

### Essential shortcuts

| Shortcut       | Action                                |
| -------------- | ------------------------------------- |
| `Ctrl+b c`     | Create a new window                   |
| `Ctrl+b %`     | Split the current pane left and right |
| `Ctrl+b "`     | Split the current pane top and bottom |
| `Ctrl+b Arrow` | Move to the pane in that direction    |
| `Ctrl+b n`     | Move to the next window               |
| `Ctrl+b p`     | Move to the previous window           |
| `Ctrl+b 0`–`9` | Jump to a window by number            |
| `Ctrl+b d`     | Detach from the current session       |
| `Ctrl+b z`     | Zoom or unzoom the current pane       |
| `Ctrl+b ?`     | Display all active tmux keybindings   |

### Windows

A tmux window is similar to a terminal tab.

| Shortcut       | Action                                   |
| -------------- | ----------------------------------------- |
| `Ctrl+b c`     | Create a window                          |
| `Ctrl+b ,`     | Rename the current window                |
| `Ctrl+b &`     | Close the current window                 |
| `Ctrl+b n`     | Next window                              |
| `Ctrl+b p`     | Previous window                          |
| `Ctrl+b l`     | Return to the previously selected window |
| `Ctrl+b w`     | Open the interactive window list         |
| `Ctrl+b 0`–`9` | Select a window by number                |

### Panes

A pane is a split terminal area inside a tmux window.

| Shortcut                | Action                            |
| ----------------------- | ---------------------------------- |
| `Ctrl+b %`              | Split left and right               |
| `Ctrl+b "`              | Split top and bottom               |
| `Ctrl+b Arrow`          | Move between panes                 |
| `Ctrl+b o`              | Move to the next pane              |
| `Ctrl+b q`              | Display pane numbers               |
| `Ctrl+b q`, then number | Select a pane by number            |
| `Ctrl+b x`              | Close the current pane             |
| `Ctrl+b z`              | Zoom or unzoom the current pane    |
| `Ctrl+b {`              | Move the current pane backward     |
| `Ctrl+b }`              | Move the current pane forward      |
| `Ctrl+b Ctrl+Arrow`     | Resize the pane by one cell        |
| `Ctrl+b Alt+Arrow`      | Resize the pane by multiple cells  |

### Sessions

| Shortcut or command         | Action                            |
| --------------------------- | ---------------------------------- |
| `Ctrl+b d`                  | Detach from tmux                   |
| `Ctrl+b s`                  | Open the interactive session list  |
| `Ctrl+b $`                  | Rename the current session         |
| `tmux ls`                   | List sessions from the shell       |
| `tmux attach`               | Attach to the most recent session  |
| `tmux attach -t main`       | Attach to the `main` session       |
| `tmux new -s name`          | Create a named session             |
| `tmux kill-session -t name` | Delete a named session              |

Detaching does not stop programs running inside tmux. The session continues in the background until it is reattached or terminated.

### Copy and scroll mode

| Shortcut              | Action                                     |
| --------------------- | ------------------------------------------- |
| `Ctrl+b [`            | Enter copy mode                            |
| Arrow keys            | Move through the scrollback buffer         |
| `PageUp` / `PageDown` | Scroll by page                             |
| `q`                   | Exit copy mode                             |
| `Ctrl+b ]`            | Paste the most recently copied tmux buffer |

Mouse mode is enabled, so the mouse wheel can also be used to enter and navigate scrollback.

### tmux commands

| Shortcut   | Action                                       |
| ---------- | ---------------------------------------------- |
| `Ctrl+b :` | Open the tmux command prompt                  |
| `Ctrl+b ?` | List current keybindings                      |
| `Ctrl+b t` | Display the clock                             |
| `Ctrl+b i` | Display information about the current window  |

Examples entered through `Ctrl+b :`:

```tmux
source-file ~/.config/tmux/tmux.conf
```

```tmux
set -g mouse on
```

```tmux
list-keys
```

## Neovim and tmux navigation

The `vim-tmux-navigator` plugin (installed by this repo via TPM) supports
movement between Neovim splits and tmux panes without using the tmux prefix.

| Shortcut | Direction |
| -------- | --------- |
| `Ctrl+h` | Left      |
| `Ctrl+j` | Down      |
| `Ctrl+k` | Up        |
| `Ctrl+l` | Right     |

The corresponding Neovim-side plugin config lives in
[`NJie94/nvim`](https://github.com/NJie94/nvim) and must be enabled there too.

## Persistent sessions

The setup includes:

* `tmux-resurrect`
* `tmux-continuum`

These plugins preserve tmux sessions, windows, pane layouts, working directories, and supported running programs.

| Shortcut        | Action                              |
| --------------- | ------------------------------------ |
| `Ctrl+b Ctrl+s` | Save the current tmux environment   |
| `Ctrl+b Ctrl+r` | Restore the saved tmux environment  |

`tmux-continuum` periodically saves the environment and attempts to restore it when tmux starts.

## Project session picker

The repository includes:

```text
scripts/tmux-sessionizer
```

After installation, run it directly from the shell:

```sh
tmux-sessionizer
```

The picker uses `fzf` to select a project directory and then creates or attaches to the corresponding tmux session.

It intentionally does not replace a stock tmux keybinding.

A custom keybinding can be added later in `tmux/tmux.conf.local`, but the default configuration keeps the tmux keymap unchanged.

## Auto-attaching a new terminal into tmux

Automatically attaching a freshly opened WezTerm shell into the persistent
`main` tmux session is handled by `wezterm-tmux.zsh` in
[`NJie94/ZshConfig`](https://github.com/NJie94/ZshConfig), not by anything in
this repo.

To leave tmux while keeping the session alive:

```text
Ctrl+b d
```

## Verify the installation

Run:

```sh
~/.local/bin/tmux-config-doctor
```

The doctor script checks:

* required commands (`tmux`, `git`)
* Oh My Tmux installation
* tmux plugins
* configuration symlinks
* sessionizer installation

Each check prints a pass or failure result.

## Re-running the installer

The installer is safe to run repeatedly:

```sh
cd ~/dev/Tmux-Config
./install.sh
```

This is useful after pulling repository updates:

```sh
cd ~/dev/Tmux-Config
git pull
./install.sh
```

The installer:

* installs only missing dependencies
* preserves existing valid symlinks
* backs up conflicting files before replacing them

Backups use this format:

```text
<original-path>.bak.<timestamp>
```

## Reloading tmux configuration

Reload the configuration from inside tmux:

```text
Ctrl+b :
```

Then enter:

```tmux
source-file ~/.config/tmux/tmux.conf
```

When bindings from an older configuration remain active, restart the tmux server:

```sh
tmux kill-server
tmux
```

This closes all currently running tmux sessions.

Save important work before running `tmux kill-server`.

## Testing stock tmux defaults

To start an isolated tmux server without loading any configuration:

```sh
tmux -L vanilla -f /dev/null
```

This is useful for checking whether unexpected behavior comes from tmux itself, the local configuration, or a plugin.

Exit the isolated server when finished:

```sh
tmux kill-server -L vanilla
```

## Troubleshooting

### Show the active prefix

```sh
tmux show-options -g prefix
```

Expected result:

```text
prefix C-b
```

### Show active keybindings

```sh
tmux list-keys
```

### Check a specific binding

```sh
tmux list-keys | grep split-window
```

### Configuration changes are not taking effect

Reload the configuration:

```sh
tmux source-file ~/.config/tmux/tmux.conf
```

For removed or changed keybindings, restart the server:

```sh
tmux kill-server
tmux
```
