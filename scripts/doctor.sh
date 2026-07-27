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

check "tmux >= 3.2 installed" \
  '[[ -n "$(command -v tmux)" ]] && [[ "$(tmux -V | grep -oE "[0-9]+" | head -1)" -ge 3 ]]'
check "git installed" 'command -v git >/dev/null 2>&1'
check "oh-my-tmux present" '[[ -d "$HOME/.local/share/oh-my-tmux" ]]'

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
check "~/.config/tmux/tmux.conf.local is a symlink into this repo" \
  'is_symlink_into_repo "$HOME/.config/tmux/tmux.conf.local" "tmux/tmux.conf.local"'
check "tmux-sessionizer on PATH" 'command -v tmux-sessionizer >/dev/null 2>&1'
check "tmux configured for RGB/truecolor" 'tmux show -g terminal-features 2>/dev/null | grep "RGB" >/dev/null'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
