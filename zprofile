if [[ $OSTYPE == linux* ]] && [[ $(lsb_release -is) == "Ubuntu" ]]; then
    emulate sh -c ". /etc/profile"
fi

if [[ -x /usr/local/bin/brew ]]; then
    HOMEBREW_PREFIX="$(/usr/local/bin/brew --prefix)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
    HOMEBREW_PREFIX="$(/opt/homebrew/bin/brew --prefix)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    HOMEBREW_PREFIX="$(/home/linuxbrew/.linuxbrew/bin/brew --prefix)"
fi

typeset -U path
[[ -d $HOMEBREW_PREFIX ]] && path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" "$path[@]")
[[ -d $HOME/.local/bin ]] && path=("$HOME/.local/bin" "$path[@]")
[[ -d $HOME/.cargo/bin ]] && path+=("$HOME/.cargo/bin")
(( $+commands[python3] )) && path+=("$(python3 -m site --user-base)/bin")
(( $+commands[go] )) && path+="$(go env GOPATH)/bin"

export PATH

if [[ -n $HOMEBREW_PREFIX ]]; then
    HOMEBREW_CELLAR="$(brew --cellar)"
    HOMEBREW_REPOSITORY="$(brew --repository)"
fi


manpaths=(
    "$HOME/.local/share/man" \
    "$HOMEBREW_PREFIX/share/man" \
    "/usr/local/share/man" \
    "/usr/share/man")

manpath=()
typeset -U manpath
for i in $manpaths; do
    if [[ -d $i ]]; then
        manpath+="$i"
    fi
done
export MANPATH

export EMAIL="ssegal127@gmail.com"

pkg_config_paths=(
    "$HOME/.local/lib/pkgconfig" \
    "$HOMEBREW_PREFIX/pkgconfig" \
    "/usr/local/lib/pkgconfig" \
    "/lib/pkgconfig" \
    "/lib/x86_64-linux-gnu/pkgconfig" \
    "/usr/lib/pkgconfig" \
    "/usr/lib/x86_64-linux-gnu/pkgconfig")

typeset -TU PKG_CONFIG_PATH pkg_config_path=()
for i in $pkg_config_paths; do
    if [[ -d $i ]]; then
        pkg_config_path+="$i"
    fi
done
export PKG_CONFIG_PATH

export LANG=en_US.UTF-8

export ALTERNATE_EDITOR=
(( $+commands[emacsclient] )) && export EDITOR='emacsclient -t'

export HISTSIZE=50000
export SAVEHIST=2000

export TZ=America/New_York

[[ -e $HOME/.zprofile.local ]] && source $HOME/.zprofile.local
