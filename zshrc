
# ssegal: Must do this before sourcing zim
if (( $+commands[gdircolors] )); then
    eval "$(gdircolors -b)"
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
elif (( $+commands[dircolors] )); then
    eval "$(dircolors -b)"
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
fi

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

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=10000
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data
setopt append_history
setopt auto_cd
setopt interactive_comments
setopt extended_glob

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


# some plugins set these the old-fashioned way, which removes the deduplication
# tag
typeset -U path
typeset -U pkg_config_path
typeset -U manpath

zstyle ":completion:*:commands" rehash 1
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
(( $+aliases[run-help] )) && unalias run-help
autoload -Uz run-help
alias help=run-help


[[ $EMACS = t ]] && unsetopt zle

[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"

[[ -e ${HOME}/.zshrc.local ]] && source "${HOME}/.zshrc.local"
