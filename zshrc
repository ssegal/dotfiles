
# ssegal: Must do this before sourcing antigen
[[ $OSTYPE == darwin* ]] && (( $+commands[gdircolors] )) && eval "$(gdircolors -b)"

source ~/.antidote/antidote.zsh

antidote load

zstyle ":completion:*:commands" rehash 1
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
unsetopt share_history
(( $+aliases[run-help] )) && unalias run-help
autoload run-help
alias help=run-help

[[ $EMACS = t ]] && unsetopt zle
#ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Make it a function so that we don't interfere with the alias created by plugin
if [[ $OSTYPE == darwin* ]]; then
    function grep {
        if (( $+commands[ggrep] )); then
            ggrep $*
        else
            command grep $*
        fi
    }
fi

[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"

[[ -e ${HOME}/.zshrc.local ]] && source "${HOME}/.zshrc.local"
