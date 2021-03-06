#!/bin/bash

set -ex
set -o pipefail

source ./setup-config.sh

readonly install_i3_wm=true
readonly install_basic_apps=true

# Helper functions {{{
pacman_install_packages() {
  pacman --noconfirm -S $@
}

yaourt_install_packages() {
  # Grant user permission to install pacman packages
  echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/pacman

  # Execute yaourt as user
  su - ${user} -c "yaourt --noconfirm -S $*"

  # Revoke user permission to install pacman packages
  rm /etc/sudoers.d/pacman
}
# }}}

# Install i3 WM {{{
if $install_i3_wm
then
  # Install packages
  pacman_install_packages \
    xorg-server \
    xorg-server-utils \
    xf86-video-vesa \
    xorg-fonts-type1 \
    xorg-xdpyinfo \
    xorg-xev \
    xorg-xwininfo \
    xsel \
    lxdm \
    i3-wm \
    dmenu \
    i3status \
    i3lock \
    conky \
    lxappearance

  yaourt_install_packages \
    industrial-arch-lxdm \
    clearlooks-phenix-gtk-theme-git

  # Set industrial-arch theme for lxdm
  sed -i 's/^theme=.*$/theme=industrial-arch-lxdm/' /etc/lxdm/lxdm.conf
  systemctl enable lxdm

  # Set konsole as the default terminal
  echo "export TERMINAL=konsole" > /etc/profile.d/i3-terminal.sh
fi
# }}}

# Install basic apps {{{
if $install_basic_apps
then
  pacman_install_packages \
    terminus-font \
    ttf-bitstream-vera \
    ttf-droid \
    ttf-inconsolata \
    network-manager-applet \
    gvim \
    lxappearance \
    kdebase-konsole \
    kdebase-dolphin \
    kde-l10n-pl \
    firefox \
    firefox-i18n-pl \
    firefox-adblock-plus \
    firefox-firebug \
    flashplugin \
    gst-plugins-good \
    gst-libav

  yaourt_install_packages \
    ttf-ms-fonts
fi
# }}}

# vim: fdm=marker
