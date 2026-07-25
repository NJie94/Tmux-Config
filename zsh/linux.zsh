# Linux-specific shell config, sourced by zsh/zshrc on Linux and WSL2.
#
# Note: on the original machine this config was consolidated from, the Kiro
# CLI pre-block below ran before Powerlevel10k's instant-prompt block at the
# very top of ~/.zshrc. Sourced from here it now runs after oh-my-zsh loads
# instead. If Kiro CLI's pre-block ever prints output, it will trip p10k's
# instant-prompt warning; it hasn't shown a problem so far.

# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/zshrc.pre.zsh"

# Various tools export
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

#fcitx
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx

#kiro CLI
export PATH="$HOME/.local/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$HOME/.dotnet:$HOME/.dotnet/tools
export PATH=$PATH:/usr/local/share/dotnet
eval "$(dotnet completions script zsh)"
export DOTNET_ROOT=/usr/lib64/dotnet
export PATH="$PATH:/usr/lib64/dotnet"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/zshrc.post.zsh"

# Pixi Zsh completion
if command -v pixi >/dev/null 2>&1; then
  eval "$(pixi completion --shell zsh)"
fi

# Distrobox uses Docker
export DBX_CONTAINER_MANAGER="docker"

# Pixi
export PATH="$HOME/.pixi/bin:$PATH"
