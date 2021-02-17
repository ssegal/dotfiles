#!/bin/zsh

dotfiles=$(realpath --relative-to="$HOME" "${0:A:h}")

rm -rf $HOME/.antigenrc $HOME/.zprofile $HOME/.zshrc $HOME/.emacs.d
ln -s $dotfiles/antigenrc $HOME/.antigenrc
ln -s $dotfiles/zprofile $HOME/.zprofile
ln -s $dotfiles/zshrc $HOME/.zshrc
ln -s $dotfiles/emacs.d $HOME/.emacs.d
