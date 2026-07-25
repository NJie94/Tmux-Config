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
  # Plain grep (no -q) reads all of its input before exiting, so it never
  # SIGPIPEs the producer mid-stream -- with `pipefail` on, a `grep -q` that
  # quits early kills fc-list/ls with SIGPIPE and pipefail then reports that
  # as a pipeline failure even though the match was found.
  fc-list 2>/dev/null | grep -i "JetBrainsMono Nerd Font" >/dev/null && return 0
  [[ "$OS" == macos ]] && ls "$HOME/Library/Fonts" 2>/dev/null | grep -i "JetBrainsMono" >/dev/null && return 0
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
