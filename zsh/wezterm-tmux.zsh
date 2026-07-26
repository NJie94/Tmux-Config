# Source this near the top of ~/.zshrc.
# It is intentionally inactive outside WezTerm.

if [[ "${TERM_PROGRAM:-}" == WezTerm ]]; then
  # Automatically enter the persistent main session only for an interactive,
  # local WezTerm shell. Set WEZTERM_AUTO_TMUX=0 to bypass once, or permanently.
  if [[ -o interactive && -z "${TMUX:-}" && "${WEZTERM_AUTO_TMUX:-1}" == 1 ]]; then
    if command -v tmux >/dev/null 2>&1; then
      exec tmux new-session -A -s "${WEZTERM_TMUX_SESSION:-main}"
    fi
  fi
fi
