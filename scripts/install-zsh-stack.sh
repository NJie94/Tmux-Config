#!/usr/bin/env bash
set -euo pipefail

log()  { printf '==> %s\n' "$1"; }
warn() { printf 'WARN: %s\n' "$1" >&2; }
die()  { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

export PATH="$HOME/.local/bin:$PATH"

if [[ "$(uname -s)" == "Darwin" ]]; then
  OS="macos"
elif [[ "$(uname -s)" == "Linux" ]]; then
  OS="linux"
else
  die "Unsupported operating system: $(uname -s)"
fi

command -v git >/dev/null 2>&1 || die "git must be installed first"
command -v curl >/dev/null 2>&1 || die "curl must be installed first"
command -v zsh >/dev/null 2>&1 || die "zsh must be installed first"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share"

ensure_git_checkout() {
  local name="$1"
  local repository="$2"
  local destination="$3"

  if [[ -d "$destination/.git" ]]; then
    log "Found $name"
    return 0
  fi

  if [[ -e "$destination" ]]; then
    die "$destination exists but is not a Git checkout; move or remove it, then re-run the installer"
  fi

  log "Installing $name"
  git clone --depth 1 "$repository" "$destination"
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "Found Oh My Zsh"
    return 0
  fi

  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

# zsh/zshrc's FZF_DEFAULT_OPTS uses --style=full (added in fzf 0.55.0), which
# is newer than --zsh (added in 0.48.0). A system-packaged fzf can pass the
# --zsh check yet still be too old for --style, so both must be verified --
# otherwise the shell breaks at startup with "unknown option: --style=full".
fzf_supports_style() {
  command -v fzf >/dev/null 2>&1 || return 1
  local current
  current="$(fzf --version 2>/dev/null | awk '{print $1}')"
  [[ -n "$current" ]] || return 1
  [[ "$(printf '%s\n%s\n' "0.55.0" "$current" | sort -V | head -1)" == "0.55.0" ]]
}

install_fzf() {
  local install_dir="$HOME/.local/share/fzf"
  local binary_link="$HOME/.local/bin/fzf"

  if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1 && fzf_supports_style; then
    log "Found compatible fzf: $(fzf --version)"
    return 0
  fi

  ensure_git_checkout \
    "fzf" \
    "https://github.com/junegunn/fzf.git" \
    "$install_dir"

  log "Installing the fzf binary"
  "$install_dir/install" --bin --no-update-rc
  ln -sfn "$install_dir/bin/fzf" "$binary_link"
  hash -r

  command -v fzf >/dev/null 2>&1 || die "fzf installation completed but the binary is not on PATH"
  fzf --zsh >/dev/null 2>&1 || die "installed fzf does not provide zsh integration"
  fzf_supports_style || die "installed fzf does not support --style (need >= 0.55.0)"
}

install_fd() {
  if command -v fd >/dev/null 2>&1; then
    log "Found fd"
    return 0
  fi

  case "$OS" in
    macos)
      command -v brew >/dev/null 2>&1 || die "Homebrew is required to install fd on macOS"
      log "Installing fd"
      brew install fd
      ;;

    linux)
      if command -v apt-get >/dev/null 2>&1; then
        log "Installing fd-find"
        sudo apt-get update -y
        sudo apt-get install -y fd-find

        local fdfind_path
        fdfind_path="$(command -v fdfind || true)"
        [[ -n "$fdfind_path" ]] || die "fd-find installed but fdfind was not found"
        ln -sfn "$fdfind_path" "$HOME/.local/bin/fd"
        hash -r
      elif command -v dnf >/dev/null 2>&1; then
        log "Installing fd-find"
        sudo dnf install -y fd-find
      else
        die "No supported Linux package manager found for fd (supported: apt-get, dnf)"
      fi
      ;;
  esac

  command -v fd >/dev/null 2>&1 || die "fd installation completed but fd is not on PATH"
}

# pay-respects is a nice-to-have (not one of the plugins this stack must
# provide), so a failure here must never abort the rest of the install --
# unlike the die()-based checks above, every path through this function
# ends in a warning rather than a hard failure.
install_pay_respects() {
  if command -v pay-respects >/dev/null 2>&1; then
    log "Found pay-respects"
    return 0
  fi

  case "$OS" in
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        warn "Homebrew not found; skipping pay-respects (optional)"
        return 0
      fi
      log "Installing pay-respects"
      brew install timescam/homebrew-tap/pay-respects ||
        warn "Failed to install pay-respects; continuing without it"
      ;;

    linux)
      # The upstream installer unpacks a .tar.zst release archive, which
      # needs zstd on PATH -- make a best-effort attempt to have it first.
      if ! command -v zstd >/dev/null 2>&1; then
        if command -v apt-get >/dev/null 2>&1; then
          sudo apt-get update -y && sudo apt-get install -y zstd || true
        elif command -v dnf >/dev/null 2>&1; then
          sudo dnf install -y zstd || true
        fi
      fi

      log "Installing pay-respects"
      curl -sSfL https://raw.githubusercontent.com/iffse/pay-respects/main/install.sh | sh ||
        warn "pay-respects installer failed; continuing without it"
      ;;
  esac

  hash -r
  command -v pay-respects >/dev/null 2>&1 ||
    warn "pay-respects is not on PATH; it's optional and can be installed later from https://github.com/iffse/pay-respects"
}

verify_installation() {
  local zsh_custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  local failures=0

  check_path() {
    local description="$1"
    local path="$2"

    if [[ -e "$path" ]]; then
      log "Verified $description"
    else
      warn "Missing $description: $path"
      failures=$((failures + 1))
    fi
  }

  check_command() {
    local command_name="$1"

    if command -v "$command_name" >/dev/null 2>&1; then
      log "Verified command: $command_name"
    else
      warn "Missing command: $command_name"
      failures=$((failures + 1))
    fi
  }

  check_path "Oh My Zsh" "$HOME/.oh-my-zsh"
  check_path "Powerlevel10k" "$zsh_custom_dir/themes/powerlevel10k"
  check_path "zsh-autosuggestions" "$zsh_custom_dir/plugins/zsh-autosuggestions"
  check_path "zsh-syntax-highlighting" "$zsh_custom_dir/plugins/zsh-syntax-highlighting"
  check_path "zsh-history-substring-search" "$zsh_custom_dir/plugins/zsh-history-substring-search"
  check_path "you-should-use" "$zsh_custom_dir/plugins/you-should-use"

  check_command fzf
  check_command fd

  if command -v pay-respects >/dev/null 2>&1; then
    log "Verified command: pay-respects"
  else
    warn "pay-respects not found (optional correction tool -- doesn't count against the check)"
  fi

  (( failures == 0 )) || die "$failures zsh dependency check(s) failed"
}

install_oh_my_zsh

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM_DIR/plugins" "$ZSH_CUSTOM_DIR/themes"

ensure_git_checkout \
  "Powerlevel10k" \
  "https://github.com/romkatv/powerlevel10k.git" \
  "$ZSH_CUSTOM_DIR/themes/powerlevel10k"

ensure_git_checkout \
  "zsh-autosuggestions" \
  "https://github.com/zsh-users/zsh-autosuggestions.git" \
  "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"

ensure_git_checkout \
  "zsh-syntax-highlighting" \
  "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
  "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"

ensure_git_checkout \
  "zsh-history-substring-search" \
  "https://github.com/zsh-users/zsh-history-substring-search.git" \
  "$ZSH_CUSTOM_DIR/plugins/zsh-history-substring-search"

ensure_git_checkout \
  "you-should-use" \
  "https://github.com/MichaelAquilina/zsh-you-should-use.git" \
  "$ZSH_CUSTOM_DIR/plugins/you-should-use"

install_fzf
install_fd
install_pay_respects
verify_installation

log "Zsh stack installation complete"
