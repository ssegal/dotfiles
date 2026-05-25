#!/bin/sh
#
# This script is intended to operate on any POSIX-compliant shell.

set -eu

command_exists() {
    # Since we've turned on errexit, test result with || to avoid triggering it.
    command -v "$1" >/dev/null 2>&1 || return 1
    return 0
}

cleanup() {
    [ -n "${TMPDIR}" ] && rm -rf "${TMPDIR}"
}
trap cleanup EXIT

TMPDIR=$(mktemp -d)

echo "*** Removing old links"
rm -rf \
    "$HOME/.zprofile" \
    "$HOME/.zshrc" \
    "$HOME/.emacs.d" \
    "$HOME/.tmux.conf" \
    "$HOME/.zimrc"

HOME_BIN_DIR="$HOME/.local/bin"
mkdir -p "$HOME_BIN_DIR"

if command_exists brew; then
    echo "*** Existing homebrew found!"
    BREW="brew"
else
    # install homebrew
    echo "*** Installing homebrew"
    export NONINTERACTIVE=1
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x "/usr/local/bin/brew" ]; then
        BREW="/usr/local/bin/brew"
    elif [ -x "/opt/homebrew/bin/brew" ]; then
        BREW="/opt/homebrew/bin/brew"
    elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
        BREW="/home/linuxbrew/.linuxbrew/bin/brew"
    fi
fi

HOMEBREW_PREFIX="$(${BREW} --prefix)"
REALPATH="realpath"
GREP="grep"
LN="ln"
BASH="bash"
[ -z "${LANG:-}" ] && export LANG=en_US.UTF-8
[ -z "${USER:-}" ] && export USER="$(id -un)"

export PATH="$HOMEBREW_PREFIX/bin":"$PATH"

echo "*** Installing extra tools via Homebrew"
brew install -q rg eza bat bat-extras fzf lazygit fd starship
if [ "$(uname -s)" = "Darwin" ]; then
    echo "*** MacOS-specific install"
    brew install -q coreutils grep bash bash-completion@2 findutils gnu-sed gnu-tar gawk git
    REALPATH="grealpath"
    GREP="ggrep"
    LN="gln"
    BASH="$HOMEBREW_PREFIX/bin/bash"
    if ! ${GREP} -Fq "${BASH} /etc/shells"; then
        echo "${BASH}" | sudo tee -a /etc/shells > /dev/null
    fi
    sudo chsh "$(whoami)" -s "$BASH"
fi
command_exists xz || brew install xz

DOTFILES=$(dirname "$(${REALPATH} "$0")")

echo "*** Creating links"
$LN -rfs "$DOTFILES/emacs.d" "$HOME/.emacs.d"
$LN -rfs "$DOTFILES/tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.config"
$LN -rfs "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"
$LN -rfs "$DOTFILES/config/bat" "$HOME/.config/bat"

$LN -rfs "$DOTFILES/bin/edit" "$HOME_BIN_DIR/edit"

echo "*** Installing SSH keys"
# Install SSH keys
if command_exists ssh-import-id; then
    ssh-import-id gh:ssegal
elif [ ! -e "$HOME/.ssh/authorized_keys" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    curl -sLS "https://github.com/ssegal.keys" > "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
fi

echo "*** Installing ble.sh"
curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf - -C "$TMPDIR"
$BASH "$TMPDIR"/ble-nightly/ble.sh --install ~/.local/share

#echo "*** Installing bash-it"
#git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
#~/.bash_it/install.sh --silent --no-modify-config

echo "*** Wiring up bash config scripts"
DOTFILES_REL=$(${REALPATH} --relative-to="$HOME" "$DOTFILES")
if [ -f "${HOME}/.bash_profile" ]; then
    if ! ${GREP} -Fq ". \"\${HOME}/${DOTFILES_REL}/bash/bash_profile\" ~/.bash_profile"; then
        echo ". \"\${HOME}/${DOTFILES_REL}/bash/bash_profile\"" >> ~/.bash_profile;
    fi
else
    echo ". \"\${HOME}/${DOTFILES_REL}"/bash/bash_profile\" > ~/.bash_profile
    echo "[[ -f \${HOME}/.bashrc ]] && . \"\${HOME}/.bashrc\"" >> ~/.bash_profile
fi

if [ -f "${HOME}/.bashrc" ]; then
    if ! ${GREP} -Fq ". \"\${HOME}/${DOTFILES_REL}/bash/bashrc\"" ~/.bashrc; then
        echo ". \"\${HOME}/${DOTFILES_REL}/bash/bashrc\"" >> ~/.bashrc;
    fi
else
    echo ". \"\${HOME}/${DOTFILES_REL}/bash/bashrc\"" > ~/.bashrc;
fi

echo "*** DONE!"

