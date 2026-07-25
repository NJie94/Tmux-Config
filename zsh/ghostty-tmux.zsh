# Source this near the top of ~/.zshrc.
# It is intentionally inactive outside Ghostty.

if [[ "${TERM_PROGRAM:-}" == ghostty ]]; then
  # Ghostty injects integration into the first zsh it starts. tmux then starts
  # another zsh, so source the integration again inside tmux.
  if [[ -n "${TMUX:-}" && -n "${GHOSTTY_RESOURCES_DIR:-}" ]]; then
    _ghostty_zsh_integration="${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
    [[ -r "$_ghostty_zsh_integration" ]] && source "$_ghostty_zsh_integration"
    unset _ghostty_zsh_integration
  fi

  # Automatically enter the persistent main session only for an interactive,
  # local Ghostty shell. Set GHOSTTY_AUTO_TMUX=0 to bypass once, or permanently.
  if [[ -o interactive && -z "${TMUX:-}" && "${GHOSTTY_AUTO_TMUX:-1}" == 1 ]]; then
    if command -v tmux >/dev/null 2>&1; then
      exec tmux new-session -A -s "${GHOSTTY_TMUX_SESSION:-main}"
    fi
  fi
fi
