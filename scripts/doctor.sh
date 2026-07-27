#!/usr/bin/env bash
set -uo pipefail

# Portable stand-in for GNU `readlink -f` (BSD readlink on macOS has no -f).
# Manually resolves symlinks in a loop, then canonicalizes the containing
# directory with `cd -P && pwd -P`, which is supported by both GNU and BSD.
resolve_path() {
  local target="$1" link dir base depth=0
  while [[ -L "$target" ]]; do
    depth=$((depth + 1))
    if [[ $depth -gt 40 ]]; then
      printf 'resolve_path: too many levels of symbolic links: %s\n' "$1" >&2
      return 1
    fi
    link="$(readlink "$target")"
    if [[ "$link" == /* ]]; then
      target="$link"
    else
      target="$(dirname "$target")/$link"
    fi
  done
  dir="$(cd -P "$(dirname "$target")" && pwd -P)"
  base="$(basename "$target")"
  printf '%s/%s\n' "$dir" "$base"
}

REPO_DIR="$(cd "$(dirname "$(resolve_path "${BASH_SOURCE[0]}")")/.." && pwd)"
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
  [[ -L "$path" ]] && [[ "$(resolve_path "$path")" == "$REPO_DIR/$repo_rel" ]]
}

is_wsl2() {
  [[ -f /proc/version ]] && grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null
}

check "tmux >= 3.2 installed" \
  '[[ -n "$(command -v tmux)" ]] && [[ "$(tmux -V | grep -oE "[0-9]+" | head -1)" -ge 3 ]]'
if is_wsl2; then
  check "wezterm.exe reachable from WSL (native Windows install)" 'command -v wezterm.exe >/dev/null 2>&1'
else
  check "wezterm installed" 'command -v wezterm >/dev/null 2>&1'
fi
check "zsh installed" 'command -v zsh >/dev/null 2>&1'
check "fzf installed" 'command -v fzf >/dev/null 2>&1'
check "git installed" 'command -v git >/dev/null 2>&1'
check "oh-my-tmux present" '[[ -d "$HOME/.local/share/oh-my-tmux" ]]'
check "oh-my-zsh present" '[[ -d "$HOME/.oh-my-zsh" ]]'
check "powerlevel10k theme installed" '[[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]'
check "zsh-autosuggestions plugin installed" '[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]'
check "zsh-syntax-highlighting plugin installed" '[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]'
check "zsh-history-substring-search plugin installed" \
  '[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-history-substring-search" ]]'

check "you-should-use plugin installed" \
  '[[ -d "$HOME/.oh-my-zsh/custom/plugins/you-should-use" ]]'

check "fzf installed" \
  'command -v fzf >/dev/null 2>&1'

check "fzf supports zsh integration" \
  'fzf --zsh >/dev/null 2>&1'

check "fd installed" \
  'command -v fd >/dev/null 2>&1'

check "pay-respects installed" \
  'command -v pay-respects >/dev/null 2>&1'

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
  '[[ -L "$HOME/.config/tmux/tmux.conf" ]] && [[ "$(resolve_path "$HOME/.config/tmux/tmux.conf")" == "$HOME/.local/share/oh-my-tmux/.tmux.conf" ]]'
check "~/.config/tmux/tmux.conf.local is a symlink into the dotfiles repo" \
  'is_symlink_into_repo "$HOME/.config/tmux/tmux.conf.local" "tmux/tmux.conf.local"'
check "~/.config/wezterm exists and is a git checkout" '[[ -d "$HOME/.config/wezterm/.git" ]]'
check "~/.zshrc is a symlink into the dotfiles repo" \
  'is_symlink_into_repo "$HOME/.zshrc" "zsh/zshrc"'
check "~/.config/zsh/wezterm-tmux.zsh is a symlink into the dotfiles repo" \
  'is_symlink_into_repo "$HOME/.config/zsh/wezterm-tmux.zsh" "zsh/wezterm-tmux.zsh"'
check "~/.config/nvim exists and is a git checkout" '[[ -d "$HOME/.config/nvim/.git" ]]'
check "tmux-sessionizer on PATH" 'command -v tmux-sessionizer >/dev/null 2>&1'
check "~/.zshrc.local exists" '[[ -f "$HOME/.zshrc.local" ]]'
check "tmux configured for RGB/truecolor" 'tmux show -g terminal-features 2>/dev/null | grep "RGB" >/dev/null'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
