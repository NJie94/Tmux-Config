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
ensure_cmd git

if [[ ! -d "$HOME/.local/share/oh-my-tmux" ]]; then
  log "Installing oh-my-tmux"
  git clone --depth 1 https://github.com/gpakosz/.tmux.git "$HOME/.local/share/oh-my-tmux"
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
link "$REPO_DIR/scripts/tmux-sessionizer" "$HOME/.local/bin/tmux-sessionizer"
link "$REPO_DIR/scripts/doctor.sh" "$HOME/.local/bin/tmux-config-doctor"

log "Triggering oh-my-tmux's automatic plugin installation"
tmux new-session -d -s __tmux_config_bootstrap -c /tmp 2>/dev/null || true
sleep 3
tmux kill-session -t __tmux_config_bootstrap 2>/dev/null || true

log "Install complete."
log "Run '$HOME/.local/bin/tmux-config-doctor' to verify the setup (plugin clones may take a few seconds -- re-run if it reports missing plugins right after install)."
