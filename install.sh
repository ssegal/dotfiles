#!/bin/bash
#
# Assume that Linux systems have GNU coreutils or compatible.

set -eu

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

get_latest_release_tag() {
    curl -sLS https://api.github.com/repos/$1/releases/latest | \
        grep "tag_name" | \
        cut -d ':' -f "2,3" | \
        tr -d '", :'
}

cleanup() {
    [ -n "${TEMPDIR}" ] && rm -rf "${TEMPDIR}"
}
trap cleanup EXIT

TEMPDIR=$(mktemp -d)

command_exists curl || abort "$0: curl missing"
command_exists xz || abort "$0: xz missing"

if command_exists brew; then
    echo "*** Existing homebrew found!"
    eval "$(brew shellenv)"
elif [ "${2:-}" = "--brew" ]; then
    # install homebrew
    echo "*** Installing homebrew"
    export NONINTERACTIVE=1
    ${BASH} -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    elif [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
elif [ "$(uname -s)" = "Darwin" ]; then
    abort "$0: MacOS requires homebrew.  Use \"--brew\"."
else
    echo "*** No homebrew installation"
fi

echo "*** Removing old links"
rm -rf \
    "$HOME/.zprofile" \
    "$HOME/.zshrc" \
    "$HOME/.emacs.d" \
    "$HOME/.tmux.conf" \
    "$HOME/.zimrc"

HOME_BIN_DIR="$HOME/.local/bin"
mkdir -p "$HOME_BIN_DIR"
HOME_MAN_DIR="$HOME/.local/share/man"
mkdir -p "$HOME_MAN_DIR"

REALPATH="realpath"
GREP="grep"
LN="ln"
[ -z "${LANG:-}" ] && export LANG=en_US.UTF-8
# shellcheck disable=SC2155
[ -z "${USER:-}" ] && export USER="$(id -un)"

if [ -n "${HOMEBREW_PREFIX:-}" ]; then
    echo "*** Installing extra tools via Homebrew"
    brew install -q rg eza bat bat-extras fzf lazygit fd starship
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "*** MacOS-specific install"
        brew install -q coreutils grep bash bash-completion@2 findutils gnu-sed gnu-tar gawk git
        REALPATH="grealpath"
        GREP="ggrep"
        LN="gln"
        LOGIN_BASH="$HOMEBREW_PREFIX/bin/bash"
        if ! ${GREP} -Fq "${LOGIN_BASH}" "/etc/shells"; then
            echo "${LOGIN_BASH}" | sudo tee -a /etc/shells > /dev/null
        fi
        sudo chsh "$(whoami)" -s "$BASH"
    fi
else
    echo "*** Installing extra tools"

    # use statically-linked musl variants when available.
    case "$(uname -sm)" in
        "Linux aarch64")
            ripgrep_triple=aarch64-unknown-linux-gnu
            eza_triple=aarch64-unknown-linux-gnu
            bat_triple=aarch64-unknown-linux-musl
            fd_triple=aarch64-unknown-linux-musl
            fzf_triple=linux_arm64
            ;;
        "Linux x86_64")
            ripgrep_triple=x86_64-unknown-linux-musl
            eza_triple=x86_64-unknown-linux-musl
            bat_triple=x86_64-unknown-linux-musl
            fd_triple=x86_64-unknown-linux-musl
            fzf_triple=linux_amd64
            ;;
        *)
            abort "$0: Unsupported machine type"
            ;;
    esac

    if ! command_exists starship; then
        echo "*** Installing starship"
        curl -sS https://starship.rs/install.sh | sh -s -- -f -b "${HOME_BIN_DIR}"
    fi
    if ! command_exists rg && [ -n "${ripgrep_triple:-}" ]; then
        echo "*** Downloading rg"
        ripgrep_tag=$(get_latest_release_tag BurntSushi/ripgrep)
        curl -sLS "https://github.com/BurntSushi/ripgrep/releases/download/${ripgrep_tag}/ripgrep-${ripgrep_tag}-${ripgrep_triple}.tar.gz" | \
            tar xz -C "$TEMPDIR"
        cp -f "$TEMPDIR/ripgrep-${ripgrep_tag}-${ripgrep_triple}/rg" "$HOME_BIN_DIR"
        chmod +x "$HOME_BIN_DIR/rg"
        mkdir -p "${HOME_MAN_DIR}/man1"
        cp -f "$TEMPDIR/ripgrep-${ripgrep_tag}-${ripgrep_triple}/doc/rg.1" "$HOME_MAN_DIR/man1"
        mkdir -p "$HOME/.local/share/bash-completions/completions"
        cp -f "$TEMPDIR/ripgrep-${ripgrep_tag}-${ripgrep_triple}/complete/rg.bash" "$HOME/.local/share/bash-completions/completions/rg"
    fi
    if ! command_exists eza && [ -n "${eza_triple:-}" ]; then
        echo "*** Downloading eza"
        eza_tag=$(get_latest_release_tag eza-community/eza)
        eza_version=${eza_tag#?}
        curl -sLS "https://github.com/eza-community/eza/releases/download/${eza_tag}/eza_${eza_triple}.tar.gz" | \
            tar xz -C "$HOME_BIN_DIR" ./eza
        chmod +x "$HOME_BIN_DIR/eza"
        curl -sLS "https://github.com/eza-community/eza/releases/download/${eza_tag}/completions-${eza_version}.tar.gz" | \
            tar xz -C "$TEMPDIR"
        mkdir -p "$HOME/.local/share/bash-completions/completions"
        cp -f "$TEMPDIR/target/completions-${eza_version}/eza" "$HOME/.local/share/bash-completions/completions"
        curl -sLS "https://github.com/eza-community/eza/releases/download/${eza_tag}/man-${eza_version}.tar.gz" | \
            tar xz -C "$TEMPDIR"
        mkdir -p "$HOME_MAN_DIR/man1" "$HOME_MAN_DIR/man5"
        cp -f "$TEMPDIR/target/man-${eza_version}/eza.1" "$HOME_MAN_DIR/man1"
        cp -f "$TEMPDIR/target/man-${eza_version}/eza_colors.5" "$HOME_MAN_DIR/man5"
        cp -f "$TEMPDIR/target/man-${eza_version}/eza_colors-explanation.5" "$HOME_MAN_DIR/man5"
    fi
    if ! command_exists bat && [ -n "${bat_triple:-}" ]; then
        echo "*** Downloading bat"
        bat_tag=$(get_latest_release_tag sharkdp/bat)
        curl -sLS "https://github.com/sharkdp/bat/releases/download/${bat_tag}/bat-${bat_tag}-${bat_triple}.tar.gz" | \
            tar xz -C "$TEMPDIR"
        cp -f "$TEMPDIR/bat-${bat_tag}-${bat_triple}/bat" "$HOME_BIN_DIR"
        chmod +x "$HOME_BIN_DIR/bat"
        mkdir -p "${HOME_MAN_DIR}/man1"
        cp -f "$TEMPDIR/bat-${bat_tag}-${bat_triple}/bat.1" "${HOME_MAN_DIR}/man1/bat.1"
        mkdir -p "$HOME/.local/share/bash-completions/completions"
        cp -f "$TEMPDIR/bat-${bat_tag}-${bat_triple}/autocomplete/bat.bash" "$HOME/.local/share/bash-completions/completions/bat"
    fi
    if ! command_exists fd && [ -n "${fd_triple:-}" ]; then
        echo "*** Downloading fd"
        fd_tag=$(get_latest_release_tag sharkdp/fd)
        curl -sLS "https://github.com/sharkdp/fd/releases/download/${fd_tag}/fd-${fd_tag}-${fd_triple}.tar.gz" | \
            tar xz -C "$TEMPDIR"
        cp -f "$TEMPDIR/fd-${fd_tag}-${fd_triple}/fd" "$HOME_BIN_DIR"
        mkdir -p "${HOME_MAN_DIR}/man1"
        cp -f "$TEMPDIR/fd-${fd_tag}-${fd_triple}/fd.1" "${HOME_MAN_DIR}/man1/fd.1"
        chmod +x "$HOME_BIN_DIR/fd"
        mkdir -p "$HOME/.local/share/bash-completions/completions"
        cp -f "$TEMPDIR/fd-${fd_tag}-${fd_triple}/autocomplete/fd.bash" "$HOME/.local/share/bash-completions/completions/fd"
    fi
    if ! command_exists fzf && [ -n "${fzf_triple:-}" ]; then
        echo "*** Downloading fzf"
        fzf_tag=$(get_latest_release_tag junegunn/fzf)
        fzf_version=${fzf_tag#?}
        echo "downloading https://github.com/junegunn/fzf/releases/download/${fzf_tag}/fzf-${fzf_version}-${fzf_triple}.tar.gz"
        curl -sLS "https://github.com/junegunn/fzf/releases/download/${fzf_tag}/fzf-${fzf_version}-${fzf_triple}.tar.gz" | \
            tar xz -C "$HOME_BIN_DIR" fzf
        chmod +x "$HOME_BIN_DIR/fzf"
    fi
fi

DOTFILES=$(dirname "$(${REALPATH} "$0")")

echo "*** Creating links"
$LN -rfs "$DOTFILES/emacs.d" "$HOME/.emacs.d"
$LN -rfs "$DOTFILES/tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.config"
$LN -rfs "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"
$LN -rfs --target-directory="$HOME/.config" "$DOTFILES/config/bat"

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
curl -sLS https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf - -C "$TEMPDIR"
$BASH "$TEMPDIR"/ble-nightly/ble.sh --install ~/.local/share

echo "*** Wiring up bash config scripts"
DOTFILES_REL=$(${REALPATH} --relative-to="$HOME" "$DOTFILES")
if [ -f "${HOME}/.bash_profile" ]; then
    if ! ${GREP} -Fq ". \"\${HOME}/${DOTFILES_REL}/bash/bash_profile\"" ~/.bash_profile; then
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

