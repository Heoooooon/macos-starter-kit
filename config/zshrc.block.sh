# managed by macos-starter-kit — edits between the markers are overwritten on re-run.

# mise: node / python / go version manager
command -v mise >/dev/null && eval "$(mise activate zsh)"

# rust (rustup): cargo / rustc / rust-analyzer proxies
[ -d /opt/homebrew/opt/rustup/bin ] && export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
[ -d /usr/local/opt/rustup/bin ]    && export PATH="/usr/local/opt/rustup/bin:$PATH"

# bun: global packages (e.g. gjc / gajae-code) live in ~/.bun/bin
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# oh-my-zsh plugins (sourced directly so they work regardless of plugins=() line)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ] \
  && source "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] \
  && source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# fzf: fuzzy finder keybindings + completion (Ctrl-R history, Ctrl-T files, Alt-C cd)
command -v fzf >/dev/null && source <(fzf --zsh)

# bat: nicer cat
command -v bat >/dev/null && alias cat='bat --paging=never'

# starship prompt — keep LAST so it owns the prompt
command -v starship >/dev/null && eval "$(starship init zsh)"
