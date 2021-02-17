#!/bin/sh

set -eu

if [ -d "$HOME/.dotfiles" ]; then
    git -C "$HOME/.dotfiles" pull --recurse-submodules --ff-only
    if [ ! -x "$HOME/.dotfiles/install.zsh" ]; then
        echo "$0: Unknown .dotfiles directory already exists."
        exit 1
    fi
else
    git clone --recurse-submodules https://github.com/ssegal/dotfiles $HOME/.dotfiles
fi

exec $HOME/.dotfiles/install.zsh
