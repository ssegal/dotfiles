#!/bin/bash

set -euo pipefail

echo "Adding additional repositories..."
add-apt-repository -y ppa:kelleyk/emacs
add-apt-repository -y ppa:git-core/ppa

echo "Performing package upgrade..."
apt-get update -yq
apt-get upgrade -yq

echo "Setting timezone..."
timedatectl --no-ask-password set-timezone "America/New_York"

echo "Adding new packages..."
apt-get install -yq zsh build-essential git emacs27-nox tmux colorize ripgrep

echo "Configuring ssegal user..."
useradd \
    --comment "Stephen Segal" \
    --user-group \
    --create-home \
    --groups sudo,dialout,cdrom,floppy,audio,video,plugdev,users \
    --shell /bin/zsh \
    ssegal

echo "ssegal ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/80-ssegal
sudo --set-home --non-interactive --user=ssegal ssh-import-id gh:ssegal
curl -L https://raw.githubusercontent.com/ssegal/dotfiles/stuff/cloud-init/home-provision.sh | sudo --set-home --non-interactive --user=ssegal /bin/bash

echo "Disabling root login..."
echo "PermitRootLogin no" > /etc/ssh/sshd_config.d/80-disable-root

if [[ -f /var/run/reboot-required ]]; then
    echo "Reboot required!  Rebooting!"
    reboot
else
    echo "No reboot required.  All done!"
fi
