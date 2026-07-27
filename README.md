# Tmux Config

A portable terminal environment built around:

* [tmux](https://github.com/tmux/tmux) with [Oh My Tmux](https://github.com/gpakosz/.tmux)
* [zsh](https://www.zsh.org) with [Oh My Zsh](https://ohmyz.sh)
* [WezTerm](https://wezterm.org)
* [Neovim](https://neovim.io)

Everything is managed from one repository and installed through a single script on Linux, macOS, or Windows through WSL2.

## Features

* Stock tmux keybindings with the standard `Ctrl+b` prefix
* Catppuccin-inspired tmux theme
* Mouse support
* Large tmux scrollback history
* Persistent tmux sessions
* Automatic WezTerm-to-tmux attachment
* Seamless navigation between tmux panes and Neovim splits
* Powerlevel10k, fzf, autosuggestions, and syntax highlighting
* Portable Linux, macOS, and WSL configuration
* Safe, repeatable installation
* Read-only environment health check

## Repository structure

| Path                              | Purpose                                                      |
| --------------------------------- | ------------------------------------------------------------ |
| `tmux/tmux.conf.local`            | Oh My Tmux settings, theme, shell configuration, and plugins |
| `zsh/zshrc`                       | Portable Oh My Zsh configuration                             |
| `zsh/linux.zsh`                   | Linux-specific shell settings                                |
| `zsh/macos.zsh`                   | macOS-specific shell settings                                |
| `zsh/wezterm-tmux.zsh`            | Automatically attaches local WezTerm shells to tmux          |
| `scripts/tmux-sessionizer`        | fzf-based project and tmux session picker                    |
| `scripts/doctor.sh`               | Checks dependencies, plugins, configuration, and symlinks    |
| `nvim/tmux-navigator.lua.example` | Example Neovim configuration for tmux navigation             |

The WezTerm and Neovim configurations are maintained in separate repositories:

* [`NJie94/wezterm`](https://github.com/NJie94/wezterm)
* [`NJie94/nvim`](https://github.com/NJie94/nvim)

The installer clones these repositories only when their target directories do not already exist. Existing checkouts are never overwritten.

## Install

### Linux

```sh
git clone https://github.com/NJie94/Tmux-Config ~/dev/Tmux-Config
cd ~/dev/Tmux-Config
./install.sh
```

The installer sets up missing dependencies where supported, including:

* tmux
* zsh
* git
* fzf
* JetBrains Mono Nerd Font
* Oh My Zsh
* Oh My Tmux

It also creates the required configuration symlinks and clones the Neovim and WezTerm repositories when they are not already installed.

Restart WezTerm after installation.

#### Fedora

WezTerm can be installed automatically through `dnf`.

#### Debian and Ubuntu

WezTerm is not currently installed through the standard `apt` repositories by this script. The installer will display a warning instead.

Install WezTerm manually using the instructions at:

[wezterm.org/installation](https://wezterm.org/installation)

### macOS

[Homebrew](https://brew.sh) must already be installed. The installer exits with instructions when `brew` cannot be found.

```sh
git clone https://github.com/NJie94/Tmux-Config ~/dev/Tmux-Config
cd ~/dev/Tmux-Config
./install.sh
```

The macOS-specific configuration is stored in:

```text
zsh/macos.zsh
```

This file starts as a lightweight placeholder for settings such as:

* `brew shellenv`
* macOS-only PATH entries
* platform-specific aliases
* tool-specific initialization

It is automatically sourced by `zsh/zshrc`.

### Windows with WSL2

WezTerm runs natively on Windows, while tmux and zsh run inside a WSL2 Linux distribution.

#### 1. Install WSL2

Open an elevated PowerShell terminal:

```powershell
wsl --install
```

Restart Windows when requested, then complete the Linux distribution setup.

#### 2. Install the dotfiles inside WSL

Inside the WSL terminal:

```sh
git clone https://github.com/NJie94/Tmux-Config ~/dev/Tmux-Config
cd ~/dev/Tmux-Config
./install.sh
```

Set zsh as the login shell when necessary:

```sh
chsh -s "$(which zsh)"
```

Log out of the WSL session and reopen it after changing the shell.

#### 3. Install WezTerm on Windows

Install WezTerm from:

[wezterm.org/installation](https://wezterm.org/installation)

Alternatively, use `winget`:

```powershell
winget install wez.wezterm
```

#### 4. Install the WezTerm configuration on Windows

Native Windows WezTerm reads its configuration from the Windows filesystem, not from the WSL home directory.

Run this in PowerShell:

```powershell
git clone https://github.com/NJie94/wezterm $env:USERPROFILE\.config\wezterm
```

This Windows-side clone is separate from the copy installed inside WSL.

#### 5. Export `TERM_PROGRAM` into WSL

The tmux auto-attach script uses `TERM_PROGRAM` to confirm that the shell was launched by WezTerm.

Run this in PowerShell:

```powershell
$existing = [System.Environment]::GetEnvironmentVariable('WSLENV', 'User')

setx WSLENV $(if ($existing) {
    "$existing`:TERM_PROGRAM/u"
} else {
    "TERM_PROGRAM/u"
})
```

Restart WezTerm afterward.

### Windows known limitation

The Windows launch configuration in `NJie94/wezterm` currently opens the WSL distribution through its default login shell instead of explicitly launching zsh.

Setting zsh as the WSL login shell works around this.

A more explicit WezTerm configuration could use:

```lua
default_prog = {
  "wsl.exe",
  "-d",
  "Ubuntu",
  "--",
  "zsh",
  "-l",
}
```

That configuration belongs in the separate `NJie94/wezterm` repository.

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
| -------------- | ---------------------------------------- |
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
| ----------------------- | --------------------------------- |
| `Ctrl+b %`              | Split left and right              |
| `Ctrl+b "`              | Split top and bottom              |
| `Ctrl+b Arrow`          | Move between panes                |
| `Ctrl+b o`              | Move to the next pane             |
| `Ctrl+b q`              | Display pane numbers              |
| `Ctrl+b q`, then number | Select a pane by number           |
| `Ctrl+b x`              | Close the current pane            |
| `Ctrl+b z`              | Zoom or unzoom the current pane   |
| `Ctrl+b {`              | Move the current pane backward    |
| `Ctrl+b }`              | Move the current pane forward     |
| `Ctrl+b Ctrl+Arrow`     | Resize the pane by one cell       |
| `Ctrl+b Alt+Arrow`      | Resize the pane by multiple cells |

### Sessions

| Shortcut or command         | Action                            |
| --------------------------- | --------------------------------- |
| `Ctrl+b d`                  | Detach from tmux                  |
| `Ctrl+b s`                  | Open the interactive session list |
| `Ctrl+b $`                  | Rename the current session        |
| `tmux ls`                   | List sessions from the shell      |
| `tmux attach`               | Attach to the most recent session |
| `tmux attach -t main`       | Attach to the `main` session      |
| `tmux new -s name`          | Create a named session            |
| `tmux kill-session -t name` | Delete a named session            |

Detaching does not stop programs running inside tmux. The session continues in the background until it is reattached or terminated.

### Copy and scroll mode

| Shortcut              | Action                                     |
| --------------------- | ------------------------------------------ |
| `Ctrl+b [`            | Enter copy mode                            |
| Arrow keys            | Move through the scrollback buffer         |
| `PageUp` / `PageDown` | Scroll by page                             |
| `q`                   | Exit copy mode                             |
| `Ctrl+b ]`            | Paste the most recently copied tmux buffer |

Mouse mode is enabled, so the mouse wheel can also be used to enter and navigate scrollback.

### tmux commands

| Shortcut   | Action                                       |
| ---------- | -------------------------------------------- |
| `Ctrl+b :` | Open the tmux command prompt                 |
| `Ctrl+b ?` | List current keybindings                     |
| `Ctrl+b t` | Display the clock                            |
| `Ctrl+b i` | Display information about the current window |

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

The `vim-tmux-navigator` plugin supports movement between Neovim splits and tmux panes without using the tmux prefix.

| Shortcut | Direction |
| -------- | --------- |
| `Ctrl+h` | Left      |
| `Ctrl+j` | Down      |
| `Ctrl+k` | Up        |
| `Ctrl+l` | Right     |

Copy the example Neovim configuration into the separately managed Neovim setup:

```text
nvim/tmux-navigator.lua.example
```

The corresponding Neovim plugin must also be enabled.

## Persistent sessions

The setup includes:

* `tmux-resurrect`
* `tmux-continuum`

These plugins preserve tmux sessions, windows, pane layouts, working directories, and supported running programs.

| Shortcut        | Action                             |
| --------------- | ---------------------------------- |
| `Ctrl+b Ctrl+s` | Save the current tmux environment  |
| `Ctrl+b Ctrl+r` | Restore the saved tmux environment |

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

## WezTerm shortcuts

WezTerm manages its own tabs, panes, workspaces, and leader key independently from tmux.

Its shortcuts are documented in:

[`NJie94/wezterm`](https://github.com/NJie94/wezterm)

Be mindful of the distinction:

* `Ctrl+b` is the tmux prefix.
* `SUPER+Space` is the WezTerm leader.
* `Ctrl+h/j/k/l` navigates between Neovim splits and tmux panes.

## Auto-attach behavior

When an interactive local shell starts inside WezTerm, `zsh/wezterm-tmux.zsh` automatically attaches it to the persistent `main` tmux session.

The script avoids auto-attaching when:

* the shell is already inside tmux
* the shell is not interactive
* the terminal was not opened through WezTerm
* the environment is unsuitable for an automatic attachment

To leave tmux while keeping the session alive:

```text
Ctrl+b d
```

## Private and machine-specific settings

Do not place credentials, tokens, private paths, or machine-specific configuration directly into the tracked `zsh/zshrc`.

Use:

```text
~/.zshrc.local
```

This file is intentionally not tracked by the repository.

Example:

```sh
export OPENAI_API_KEY="..."
export WORKSPACE_ROOT="$HOME/dev"
alias work-vpn="..."
```

## Verify the installation

Run:

```sh
~/.local/bin/wezterm-tmux-doctor
```

The doctor script checks:

* required commands
* tmux and zsh installation
* configuration symlinks
* Oh My Zsh
* Oh My Tmux
* tmux plugins
* Neovim configuration
* WezTerm configuration
* sessionizer installation
* auto-attach integration

Each check prints a pass, warning, or failure result.

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
* does not overwrite existing Neovim or WezTerm repositories
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

### zsh starts with Powerlevel10k console-output warnings

Do not hide the warning before checking the output shown beneath it.

The underlying problem is usually a command in `.zshrc` that prints an error during startup, such as an unsupported option passed to an older `fzf` version.

Check the installed version and command path:

```sh
fzf --version
type -a fzf
```

Search the zsh configuration for the failing command:

```sh
grep -nR -- '--zsh' \
  ~/.zshrc \
  ~/.zprofile \
  ~/.zshenv \
  ~/.fzf.zsh \
  ~/.config/zsh \
  2>/dev/null
```

Fix the command that produces output rather than merely suppressing the Powerlevel10k warning.
