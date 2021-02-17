#!/bin/zsh

dotfiles_absolute=${0:A:h}
dotfiles=$(realpath --relative-to="$HOME" "$dotfiles_absolute")

mkdir -p $HOME/.local/share
ln -s $(realpath --relative-to="$HOME/.local/share" "$dotfiles_absolute/antigen") $HOME/.local/share/zsh-antigen

rm -rf $HOME/.antigenrc $HOME/.zprofile $HOME/.zshrc $HOME/.emacs.d
ln -s $dotfiles/antigenrc $HOME/.antigenrc
ln -s $dotfiles/zprofile $HOME/.zprofile
ln -s $dotfiles/zshrc $HOME/.zshrc
ln -s $dotfiles/emacs.d $HOME/.emacs.d
