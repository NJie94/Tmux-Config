# Migrate dotfiles from Ghostty to WezTerm

## Problem

The dotfiles repo currently manages Ghostty as its terminal layer
(`ghostty/config.ghostty`, symlinked to `~/.config/ghostty/config.ghostty`).
Ghostty has no native Windows GUI — on Windows it only ever runs as the Linux
build inside WSL2 + WSLg, launched via the `windows/ghostty-wsl.cmd.example`
helper script. Nicholas wants a terminal that runs natively on Windows,
macOS, and Linux without that limitation.

He already has a separate, actively-maintained WezTerm config repo,
`NJie94/wezterm`, checked out at `~/.config/wezterm` — a fork of a popular
cross-platform WezTerm template with its own README, git history, and lint
tooling (stylua, luacheck). Its `config/launch.lua` already sets
`default_prog = {"wsl.exe", "-d", "Ubuntu"}` on Windows, so on Windows it
launches straight into a WSL2 distro with no separate launcher script
required — a direct improvement over the current `.cmd` file. Its font
(`JetBrainsMono Nerd Font`) already matches what `install.sh` installs today.

## Scope

Swap the terminal layer from Ghostty to WezTerm, keeping tmux as the sole
owner of sessions/windows/panes exactly as before. `NJie94/wezterm` is
integrated the same way `NJie94/nvim` already is: cloned by `install.sh` if
absent, never vendored or modified by this repo. Its own keybinds
(tab/pane/workspace management under its `SUPER+Space` leader) are left
as-is — they use different modifiers than tmux's `Ctrl+Space` prefix, so
there's no collision, and trimming them to "rendering only" (the old Ghostty
philosophy) is explicitly not being done here.

Explicitly out of scope: any change to `NJie94/wezterm`'s own config or
keybinds, changing tmux's prefix/split keys, changing the WSL distro name
already baked into `launch.lua` (`Ubuntu`).

## Repo layout changes

```
dotfiles/
├── install.sh                       # clones NJie94/wezterm instead of installing/symlinking Ghostty
├── README.md                        # updated per-platform instructions
├── tmux/
│   └── tmux.conf.local              # xterm-ghostty -> xterm-256color, terminal title
├── zsh/
│   ├── zshrc                        # sources wezterm-tmux.zsh instead of ghostty-tmux.zsh
│   ├── linux.zsh / macos.zsh        # unchanged
│   └── wezterm-tmux.zsh             # renamed from ghostty-tmux.zsh, TERM_PROGRAM check updated
├── nvim/
│   └── tmux-navigator.lua.example   # unchanged
└── scripts/
    ├── doctor.sh                    # wezterm checks replace ghostty checks
    └── tmux-sessionizer             # unchanged

Removed:
├── ghostty/config.ghostty           # no longer vendored; config lives in NJie94/wezterm
└── windows/ghostty-wsl.cmd.example  # obsolete; WezTerm launches WSL2 natively via its own config
```

### zsh/wezterm-tmux.zsh (renamed from ghostty-tmux.zsh)

Same shape as the current file, with two changes:
- Guard condition checks `"${TERM_PROGRAM:-}" == "WezTerm"` instead of
  `"ghostty"`.
- The Ghostty-specific shell-integration sourcing block (which looked for
  `$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration`) is
  dropped entirely — WezTerm has no equivalent manual-source step.

The "auto-attach to the persistent main tmux session for an interactive,
local, non-nested shell" logic is otherwise unchanged, including the
`GHOSTTY_AUTO_TMUX=0`-style escape hatch (renamed to `WEZTERM_AUTO_TMUX`).

### tmux/tmux.conf.local

- `terminal-features` / `terminal-overrides` entries keyed on
  `xterm-ghostty` change to `xterm-256color` — WezTerm doesn't set a custom
  `TERM` value the way Ghostty does, so it reports as the generic
  `xterm-256color` tmux already knows how to give RGB/truecolor overrides
  to.
- `tmux_conf_theme_terminal_title` changes from `"Ghostty"` to `"WezTerm"`.
- No other theme/keybind changes — the Catppuccin-inspired palette in this
  file was already sourced from the previous WezTerm setup, so it doesn't
  need to change.

## install.sh flow changes

1. Dependency install step: drop the `ghostty` package-manager
   install/warn block. Add an equivalent `wezterm` block using the same
   shape (try `dnf`/`brew install --cask wezterm`; on Debian/Ubuntu `apt`
   doesn't carry it, so warn with a link to wezterm.org/installation,
   matching how the Ghostty warning worked).
2. Alongside the existing "clone `NJie94/nvim` to `~/.config/nvim` if
   absent" step, add: clone `NJie94/wezterm` to `~/.config/wezterm` if that
   path doesn't already exist. Never touches an existing checkout.
3. Remove the `link "$REPO_DIR/ghostty/config.ghostty" ...` line (nothing
   to vendor/symlink anymore).
4. `link "$REPO_DIR/zsh/ghostty-tmux.zsh" ...` becomes
   `link "$REPO_DIR/zsh/wezterm-tmux.zsh" "$HOME/.config/zsh/wezterm-tmux.zsh"`.
5. Final summary/next-steps messaging: drop the "Restart Ghostty" /
   Windows `.cmd` edit instructions; replace with "Restart WezTerm to pick
   up the new config" and, on Windows, a note to install WezTerm natively
   from wezterm.org (or `winget install wez.wezterm`) — no launcher script
   to edit.

Font install logic (JetBrainsMono Nerd Font check/install) is unchanged —
already matches what `NJie94/wezterm`'s `config/fonts.lua` expects.

## Verification: scripts/doctor.sh changes

- `check "ghostty installed" ...` → `check "wezterm installed"
  'command -v wezterm >/dev/null 2>&1'`.
- `check "~/.config/ghostty/config.ghostty is a symlink into the dotfiles
  repo" ...` → `check "~/.config/wezterm exists and is a git checkout"
  '[[ -d "$HOME/.config/wezterm/.git" ]]'` — mirroring the existing nvim
  checkout check, since WezTerm's config is now handled the same way.
- `check "~/.config/zsh/ghostty-tmux.zsh is a symlink ..."` updates its
  path/repo-relative target to `zsh/wezterm-tmux.zsh`.
- All other checks (tmux, TPM, plugins, oh-my-zsh, truecolor, etc.)
  unchanged.

## README.md changes

- Replace "Ghostty" with "WezTerm" throughout prose and the repo-layout
  listing.
- **Windows section rewritten**: no longer "Ghostty has no native Windows
  GUI; on Windows it always runs as the Linux build inside WSL2 + WSLg."
  New flow: install WSL2 + a distro as before; inside the distro, run the
  same Linux install steps (`./install.sh`, which now clones
  `NJie94/wezterm`); on the **Windows side**, install WezTerm natively
  (wezterm.org/installation or `winget install wez.wezterm`) — its bundled
  config already launches straight into that WSL2 distro, so there's no
  `.cmd` file to edit or run.
- "Re-running install.sh" section: no change in substance, just terminology.
- Keymap table: unchanged (tmux keybinds, not terminal keybinds).

## Testing

No automated test suite — this is shell/config, not application code.
Validation is:
1. Run `install.sh` on this machine and confirm it clones
   `NJie94/wezterm` (since it's not currently under `~/dev/dotfiles`'
   management) without touching the existing checkout's git state, and
   that already-correct symlinks (tmux, zshrc, etc.) are left alone.
2. Run `scripts/doctor.sh` and confirm all checks pass, including the new
   `wezterm installed` and `~/.config/wezterm is a git checkout` checks.
3. Manually restart WezTerm and confirm: it opens, `wezterm-tmux.zsh`
   auto-attaches the `main` tmux session, tmux prefix/splits/theme/
   `prefix + f` sessionizer all still work, and WezTerm's own keybinds
   (tabs, `SUPER+f` search, etc.) still function alongside tmux.
