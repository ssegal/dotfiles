#!/bin/zsh

set -euo pipefail

dotfiles_absolute=${0:A:h}

realpath=realpath
if [[ $OSTYPE == darwin* ]]; then
    # MacOS realpath doesn't support --relative-to option
    if (( $+commands[grealpath] )); then
        realpath=grealpath
    else
        echo "GNU coreutils not found"
        exit 1
    fi
fi

dotfiles=$(${realpath} --relative-to="$HOME" "$dotfiles_absolute")

rm -rf \
    $HOME/.antigenrc \
    $HOME/.zprofile \
    $HOME/.zshrc \
    $HOME/.emacs.d \
    $HOME/.tmux.conf \
    $HOME/.zimrc

ln -fs "$dotfiles/zprofile" "$HOME/.zprofile"
ln -fs "$dotfiles/zshrc" "$HOME/.zshrc"
ln -fs "$dotfiles/emacs.d" "$HOME/.emacs.d"
ln -fs "$dotfiles/tmux.conf" "$HOME/.tmux.conf"
ln -fs "$dotfiles/zimrc" "$HOME/.zimrc"
