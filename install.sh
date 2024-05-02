#!/bin/bash
#
# This script is intended to operate on bash >= 3.2 (the version present in
# MacOS).

set -euo pipefail

# Function to compute relative path from first path to second path
# Based on a response to a ChatGPT prompt.
relative_path() {
    # Check for the correct number of arguments
    if [ "$#" -ne 2 ]; then
        echo "Usage: relative_path <base> <target>"
        return 1
    fi

    # Detect whether realpath supports --relative-to
    if realpath --relative-to=/ / &> /dev/null; then
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
        while [[ $target != $common* && $common != "/" ]]; do
            common=$(dirname "$common")
        done

        # Calculate the relative path
        if [[ $common == "/" ]]; then
            echo "$target"
        else
            # Prepare the return path
            local result=""
            while [[ $base != "$common" ]]; do
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
    command -v "$1" &> /dev/null || return 1
    return 0
}

get_latest_release_tag() {
    curl -sLS https://api.github.com/repos/$1/releases/latest | \
        grep "tag_name" | \
        cut -d : -f 2,3 | \
        tr -d '", '
}


dotfiles_absolute=$(dirname "$(realpath "$0")")
dotfiles=$(relative_path "$HOME" "$dotfiles_absolute")

rm -rf \
    "$HOME/.zprofile" \
    "$HOME/.zshrc" \
    "$HOME/.emacs.d" \
    "$HOME/.tmux.conf" \
    "$HOME/.zimrc"

HOME_BIN_DIR="$HOME/.local/bin"
mkdir -p "$HOME_BIN_DIR"

# install some necessary tools if they're not present
if command_in_path brew; then
    brew install -q rg eza
else
    # No homebrew, and we don't want to try to install it here because it'll
    # sudo (also it isn't supported on Linux AArch64).  So instead let's just
    # download what we need manually.
    TEMPDIR=$(mktemp -d)
    trap 'rm -rf ${TEMPDIR}' EXIT

    case "$(uname -sm)" in
        "Linux aarch64")
            ripgrep_triple=aarch64-unknown-linux-gnu
            eza_triple=aarch64-unknown-linux-gnu
            ;;
        "Linux x86_64")
            ripgrep_triple=x86_64-unknown-linux-musl
            eza_triple=x86_64-unknown-linux-gnu
            ;;
        "Darwin arm64")
            ripgrep_triple=aarch64-apple-darwin
            # There's no precompiled eza binary available for MacOS.
            ;;
        *)
            echo "Unsupported machine type"
            exit 1
            ;;
    esac

    if ! command_in_path rg; then
        ripgrep_tag=$(get_latest_release_tag BurntSushi/ripgrep)
        curl -sLS "https://github.com/BurntSushi/ripgrep/releases/download/${ripgrep_tag}/ripgrep-${ripgrep_tag}-${ripgrep_triple}.tar.gz" | \
            tar xz -C "$TEMPDIR"
        cp -f "$TEMPDIR/ripgrep-${ripgrep_tag}-${ripgrep_triple}/rg" "$HOME_BIN_DIR"
        chmod +x $HOME_BIN_DIR/rg
        mkdir -p $HOME/.local/share/zsh/completions
        cp -f "$TEMPDIR/ripgrep-${ripgrep_tag}-${ripgrep_triple}/complete/_rg" "$HOME/.local/share/zsh/completions"
    fi
    if ! command_in_path eza && [[ -n ${eza_triple} ]]; then
        eza_tag=$(get_latest_release_tag eza-community/eza)
        eza_version=${eza_tag:1}
        curl -sLS "https://github.com/eza-community/eza/releases/download/${eza_tag}/eza_${eza_triple}.tar.gz" | \
            tar xz -C "$HOME_BIN_DIR" ./eza
        chmod +x $HOME_BIN_DIR/eza
        curl -sLS "https://github.com/eza-community/eza/releases/download/${eza_tag}/completions-${eza_version}.tar.gz" | \
            tar xz -C "$TEMPDIR"
        mkdir -p $HOME/.local/share/zsh/completions
        cp -f "$TEMPDIR/target/completions-${eza_version}/_eza" "$HOME/.local/share/zsh/completions"
    fi
fi

ln -fs "$dotfiles/zprofile" "$HOME/.zprofile"
ln -fs "$dotfiles/zshrc" "$HOME/.zshrc"
ln -fs "$dotfiles/emacs.d" "$HOME/.emacs.d"
ln -fs "$dotfiles/tmux.conf" "$HOME/.tmux.conf"
ln -fs "$dotfiles/zimrc" "$HOME/.zimrc"
ln -fs $(relative_path "$HOME_BIN_DIR" "$dotfiles_absolute/bin/edit") "$HOME_BIN_DIR/edit"

# Install SSH keys
if [[ ! -e "$HOME/.ssh/authorized_keys" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    curl -sLS "https://github.com/ssegal.keys" > "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
fi

if command_in_path zsh; then
    export ZIM_HOME="${HOME}/.zim"
    # Download zimfw plugin manager if missing.
    if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
        mkdir -p "${ZIM_HOME}" && curl -sSL -o "${ZIM_HOME}/zimfw.zsh" \
            https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
        zsh "${ZIM_HOME}"/zimfw.zsh install -q
    fi
fi
