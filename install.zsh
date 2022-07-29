#!/bin/zsh

set -euo pipefail

dotfiles_absolute=${0:A:h}
dotfiles=$(realpath --relative-to="$HOME" "$dotfiles_absolute")

mkdir -p "$HOME/.local/share"
ln -Tfs $(realpath --relative-to="$HOME/.local/share" "$dotfiles_absolute/antigen") $HOME/.local/share/zsh-antigen

rm -rf \
    $HOME/.antigenrc \
    $HOME/.zprofile \
    $HOME/.zshrc \
    $HOME/.emacs.d \
    $HOME/.tmux.conf

ln -fs "$(realpath --relative-to=\"$HOME/.local/share\" \"$dotfiles_absolute/zinit\")" "$HOME/.local/share/zinit"
ln -fs "$dotfiles/antigenrc" "$HOME/.antigenrc"
ln -fs "$dotfiles/zprofile" "$HOME/.zprofile"
ln -fs "$dotfiles/zshrc" "$HOME/.zshrc"
ln -fs "$dotfiles/emacs.d" "$HOME/.emacs.d"
ln -fs "$dotfiles/tmux.conf" "$HOME/.tmux.conf"
