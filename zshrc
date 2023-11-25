
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

autoload -Uz compinit

export ZIM_HOME=~/.zim

if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
    source ${ZIM_HOME}/zimfw.zsh init -q
fi

source ${ZIM_HOME}/init.zsh

#source $HOME/.local/share/zsh-antigen/antigen.zsh

#antigen init $HOME/.antigenrc

# some plugins set these the old-fashioned way, which removes the deduplication
# tag
typeset -U path
typeset -U pkg_config_path
typeset -U manpath

zstyle ":completion:*:commands" rehash 1
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
unsetopt share_history
(( $+aliases[run-help] )) && unalias run-help
autoload run-help
alias help=run-help

[[ $EMACS = t ]] && unsetopt zle

[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"

[[ -e ${HOME}/.zshrc.local ]] && source "${HOME}/.zshrc.local"
