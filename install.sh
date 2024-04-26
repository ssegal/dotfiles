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

dotfiles_absolute=$(dirname "$(realpath "$0")")
dotfiles=$(relative_path "$HOME" "$dotfiles_absolute")

rm -rf \
    "$HOME/.antigenrc" \
    "$HOME/.zprofile" \
    "$HOME/.zshrc" \
    "$HOME/.emacs.d" \
    "$HOME/.tmux.conf" \
    "$HOME/.zimrc"

if ! command -v starship; then
    mkdir -p "$HOME/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi

ln -fs "$dotfiles/zprofile" "$HOME/.zprofile"
ln -fs "$dotfiles/zshrc" "$HOME/.zshrc"
ln -fs "$dotfiles/emacs.d" "$HOME/.emacs.d"
ln -fs "$dotfiles/tmux.conf" "$HOME/.tmux.conf"
ln -fs "$dotfiles/zimrc" "$HOME/.zimrc"

