if [[ $OSTYPE == linux* ]] && [[ $(lsb_release -is) == "Ubuntu" ]]; then
    emulate sh -c ". /etc/profile"
fi

typeset -U path
[[ -d /opt/homebrew/bin ]] && path=("/opt/homebrew/bin" "$path[@]")
[[ -d $HOME/.local/bin ]] && path=("$HOME/.local/bin" "$path[@]")
[[ -d $HOME/.cargo/bin ]] && path+=("$HOME/.cargo/bin")
(( $+commands[python3] )) && path+=("$(python3 -m site --user-base)/bin")
(( $+commands[go] )) && path+="$(go env GOPATH)/bin"

export PATH

manpaths=(
    "$HOME/.local/share/man" \
    "/opt/homebrew/share/man" \
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
    "/opt/homebrew/lib/pkgconfig" \
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
