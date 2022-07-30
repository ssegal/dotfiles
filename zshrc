
# ssegal: Must do this before sourcing antigen
[[ $OSTYPE == darwin* ]] && (( $+commands[gdircolors] )) && eval "$(gdircolors -b)"

if [[ -n $VSCODE_IPC_HOOK_CLI ]]; then
    if [[ ! -o login ]]; then 
        # source .zprofile even on non login shells
        source ~/.zprofile
    fi
    helpers=$(dirname "$BROWSER")
    bindir=$(dirname "$helpers")
    path+=("$bindir/remote-cli")
    export PATH
fi

source $HOME/.local/share/zsh-antigen/antigen.zsh

antigen init $HOME/.antigenrc

zstyle ":completion:*:commands" rehash 1
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
unsetopt share_history
(( $+aliases[run-help] )) && unalias run-help
autoload run-help
alias help=run-help

[[ $EMACS = t ]] && unsetopt zle
#ZSH_AUTOSUGGEST_STRATEGY=(history completion)

[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"

[[ -e ${HOME}/.zshrc.local ]] && source "${HOME}/.zshrc.local"
