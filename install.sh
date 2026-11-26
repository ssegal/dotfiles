#!/bin/bash
#
# Assume that Linux systems have GNU coreutils or compatible
# (busybox is not supported)

set -euo pipefail

abort() {
    echo "$*" >&2
    exit 1
}

[ -n "${BASH_VERSION:-}" ] || abort "Must be run with bash"

command_exists() {
    # Since we've turned on errexit, test result with || to avoid triggering it.
    command -v "$1" >/dev/null 2>&1 || return 1
    return 0
}

# Check for supported systems
case "$(uname -sm)" in
    "Linux x86_64"|"Linux aarch64")
        export BREW="/home/linuxbrew/.linuxbrew/bin/brew"
        ;;
    "Darwin arm64")
        export BREW="/opt/homebrew/bin/brew"
        ;;
    *)
        abort "$0: Unsupported OS/Arch combo detected"
        ;;
esac


command_exists curl || abort "$0: curl missing"
command_exists xz || abort "$0: xz missing"

if [[ -x $BREW ]]; then
    echo "*** Existing homebrew found!"
    eval "$($BREW shellenv)"
elif [[ ${1:-} == "--brew" ]]; then
    # install homebrew
    echo "*** Installing homebrew"
    export NONINTERACTIVE=1
    ${BASH} -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$($BREW shellenv)"
elif [[ $(uname -s) == "Darwin" ]]; then
    abort "!!! MacOS requires homebrew.  Use \"--brew\"."
else
    echo "*** No homebrew installation found."
fi

echo "*** Removing old links"
rm -rf \
    "$HOME/.zprofile" \
    "$HOME/.zshrc" \
    "$HOME/.emacs.d" \
    "$HOME/.tmux.conf" \
    "$HOME/.zimrc" \
    "$HOME/.config/nano" \
    "$HOME/.eget.toml" \

HOME_BIN_DIR="$HOME/.local/bin"
mkdir -p "$HOME_BIN_DIR"
HOME_MAN_DIR="$HOME/.local/share/man"
mkdir -p "$HOME_MAN_DIR"

LN="ln"
DOTFILES=$(dirname "$(realpath "$0")")
[[ -z "${LANG:-}" ]] && export LANG=en_US.UTF-8
# shellcheck disable=SC2155
[[ -z "${USER:-}" ]] && export USER="$(id -un)"

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
    echo "*** Installing extra tools via Homebrew"
    brew install -yq rg eza bat lesspipe fzf lazygit fd starship micro zsh-patina
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "*** MacOS-specific install"
        brew install -yq coreutils grep findutils gnu-sed gnu-tar gawk git nano
        LN="gln"
    fi
else
    echo "*** Installing extra tools with eget"
    if ! command_exists eget; then
        echo "*** Installing eget"
        (cd "${HOME_BIN_DIR}" && curl https://zyedidia.github.io/eget.sh | sh)
    fi

    $LN -fs "${DOTFILES}/eget.toml" "${HOME}/.eget.toml"

    "${HOME_BIN_DIR}/eget" -D
fi

echo "*** Creating links"
$LN -rfs "$DOTFILES/emacs.d" "$HOME/.emacs.d"
mkdir -p "$HOME/.config"
$LN -rfs --target-directory="$HOME/.config" "$DOTFILES/config/*"
$LN -rfs "$DOTFILES/bin/edit" "$HOME_BIN_DIR/edit"

echo "*** Installing zsh dotfiles"
mkdir -p "$HOME/.config/zsh"
[[ -e "$HOME/.config/zsh/.zshrc" ]] || echo "source \${HOME}/.dotfiles/zsh/zshrc" > "$HOME/.config/zsh/.zshrc"
$LN -rfs "$DOTFILES/zsh/zsh_plugins.txt" "$HOME/.config/zsh/.zsh_plugins.txt"
[[ -e "$HOME/.config/zsh/.zstyles" ]] || echo "source \${HOME}/.dotfiles/zsh/zstyles" > "$HOME/.config/zsh/.zstyles"
[[ -e "$HOME/.zshenv" ]] || echo "source \${HOME}/.dotfiles/zsh/zshenv" > "$HOME/.zshenv"

echo "*** Installing SSH keys"
# Install SSH keys
if command_exists ssh-import-id; then
    ssh-import-id gh:ssegal
elif [[ ! -e "$HOME/.ssh/authorized_keys" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    curl -sLS "https://github.com/ssegal.keys" > "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
fi

echo "*** Compiling bat cache"
if [[ -x "$HOME_BIN_DIR/bat" ]]; then
    "${HOME_BIN_DIR}/bat" cache --build
elif command_exists bat; then
    bat cache --build
fi

echo "*** DONE!"
