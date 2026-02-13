#!/bin/sh
#
# This script is intended to operate on any POSIX-compliant shell.

set -eu

# Function to compute relative path from first path to second path.  This is
# necessary because we want to be able to run on systems without GNU coreutils.
# Based on a response to a ChatGPT prompt.
relative_path() {
    # Check for the correct number of arguments
    if [ "$#" -ne 2 ]; then
        echo "Usage: relative_path <base> <target>"
        return 1
    fi

    # Detect whether realpath supports --relative-to
    if realpath --relative-to=/ / >/dev/null 2>&1; then
        # Use realpath with --relative-to if supported
        realpath --relative-to="$1" "$2"
        return $?
    else
        # Fallback to manual method if --relative-to is not supported
        local base
        base=$(realpath "$1")
        local target
        target=$(realpath "$2")

        # Check if realpath returned an error (nonexistent paths)
        if [ -z "$base" ] || [ -z "$target" ]; then
            echo "Error: one or more paths do not exist."
            return 1
        fi

        # Ensure no trailing slashes, important for path comparison
        base="${base%/}"
        target="${target%/}"

        # Find the common part
        local common=$base
        while [ "$target" != "$common*" ] && [ "$common" != "/" ]; do
            common=$(dirname "$common")
        done

        # Calculate the relative path
        if [ "$common" == "/" ]; then
            echo "$target"
        else
            # Prepare the return path
            local result=""
            while [ "$base" != "$common" ]; do
                base=$(dirname "$base")
                result="../$result"
            done
            result="${result}${target#"$common"/}"
            result="${result%/}"  # Optional: remove trailing slash if it exists
            echo "$result"
        fi
    fi
}

command_in_path() {
    # Since we've turned on errexit, test result with || to avoid triggering it.
    command -v "$1" >/dev/null 2>&1 || return 1
    return 0
}

get_latest_release_tag() {
    curl -sLS https://api.github.com/repos/$1/releases/latest | \
        grep "tag_name" | \
        cut -d ':' -f "2,3" | \
        tr -d '", :'
}


dotfiles_absolute=$(dirname "$(realpath "$0")")
dotfiles=$(relative_path "$HOME" "$dotfiles_absolute")

echo "*** Removing old links"
rm -rf \
    "$HOME/.zprofile" \
    "$HOME/.zshrc" \
    "$HOME/.emacs.d" \
    "$HOME/.tmux.conf" \
    "$HOME/.zimrc"

HOME_BIN_DIR="$HOME/.local/bin"
mkdir -p "$HOME_BIN_DIR"

if command_in_path brew; then
    echo "*** Existing homebrew found!"
    HOMEBREW_PREFIX="$(brew --prefix)"
else
    # install homebrew
    echo "*** Installing homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x "/usr/local/bin/brew" ]; then
        HOMEBREW_PREFIX="$(/usr/local/bin/brew --prefix)"
    elif [ -x "/opt/homebrew/bin/brew" ]; then
        HOMEBREW_PREFIX="$(/opt/homebrew/bin/brew --prefix)"
    elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
        HOMEBREW_PREFIX="$(/home/linuxbrew/.linuxbrew/bin/brew --prefix)"
    fi
fi

echo "*** Installing extra tools via Homebrew"
"$HOMEBREW_PREFIX"/bin/brew install -q rg eza bat bat-extras mcfly fzf lazygit fd

# zsh is the default shell in MacOS, so no need to install.  For Linux, on the
# other hand, we want to use the system's zsh install so we can make it the
# default shell.
if [ ! -x /bin/zsh ]; then
    if command_in_path apt-get; then
        sudo apt-get install -y zsh
    elif command_in_path dnf; then
        sudo dnf install -y zsh
    else
        echo "zsh unavailable!"
        exit 1
    fi
fi

echo "*** Creating links"
ln -fs "$dotfiles/zprofile" "$HOME/.zprofile"
ln -fs "$dotfiles/zshrc" "$HOME/.zshrc"
ln -fs "$dotfiles/emacs.d" "$HOME/.emacs.d"
ln -fs "$dotfiles/tmux.conf" "$HOME/.tmux.conf"
ln -fs "$dotfiles/zimrc" "$HOME/.zimrc"

ln -fs $(relative_path "$HOME_BIN_DIR" "$dotfiles_absolute/bin/edit") "$HOME_BIN_DIR/edit"

echo "*** Installing SSH keys"
# Install SSH keys
if command_in_path ssh-import-id; then
    ssh-import-id gh:ssegal
elif [ ! -e "$HOME/.ssh/authorized_keys" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    curl -sLS "https://github.com/ssegal.keys" > "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
fi

echo "*** Installing Zim"
export ZIM_HOME="${HOME}/.zim"
# Download zimfw plugin manager if missing.
if [ ! -e "${ZIM_HOME}/zimfw.zsh" ]; then
    mkdir -p "${ZIM_HOME}" && curl -sSL -o "${ZIM_HOME}/zimfw.zsh" \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
    zsh "${ZIM_HOME}"/zimfw.zsh install -q
fi

echo "*** Setting login shell to zsh"
sudo chsh $(whoami) -s /bin/zsh

echo "*** DONE!"

