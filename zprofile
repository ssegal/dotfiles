if [[ $OSTYPE == linux* ]] && [[ $(lsb_release -is) == "Ubuntu" ]]; then
    emulate sh
    . /etc/profile
    emulate zsh
fi

[[ -d $HOME/.local/bin ]] && export PATH="$PATH:$HOME/.local/bin"

export PATH=$PATH:$HOME/go/bin

export MANPATH="~/.local/share/man:/usr/share/man:/usr/local/share/man"
export EMAIL=ssegal127@gmail.com

pkg_config_paths=(
    "~/.local/lib/pkgconfig" \
    "/usr/local/lib/pkgconfig" \
    "/lib/pkgconfig" \
    "/lib/x86_64-linux-gnu/pkgconfig" \
    "/usr/lib/pkgconfig" \
    "/usr/lib/x86_64-linux-gnu/pkgconfig")

pkg_config_paths_str=""
for i in $pkg_config_paths; do
    if [[ -d $i ]]; then
        pkg_config_paths_str+="$i:"
    fi
done
export PKG_CONFIG_PATH="$pkg_config_paths_str$PKG_CONFIG_PATH"

#export PKG_CONFIG_PATH="~/.local/lib/pkgconfig:/usr/local/lib/pkgconfig:/lib/pkgconfig:/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig"

export LANG=en_US.UTF-8

(( $+commands[emacsclient] )) && export EDITOR='emacsclient -t'

export PATH="$HOME/.cargo/bin:$PATH"

(( $+commands[go] )) && export PATH="$PATH:$(go env GOPATH)"
if [[ -d "$HOME/Library/Python/3.7/bin" ]]; then
    export PATH="$PATH:$HOME/Library/Python/3.7/bin"
fi

export HISTSIZE=50000
export SAVEHIST=2000

[[ -e $HOME/.zprofile.local ]] && source $HOME/.zprofile.local
