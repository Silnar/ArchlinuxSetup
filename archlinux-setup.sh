#!/bin/bash

set -ex
set -o pipefail

readonly user="silnar"
readonly user_password="silnar"

readonly add_user=true
readonly install_sudo=true
readonly install_yaourt=true
readonly install_virtualbox_modules=true
readonly install_i3_wm=true
readonly install_basic_apps=true

aur_install_package() {
  local pkg=${1}
  su - ${user} -c "
    cd /tmp
    curl -o $pkg.tar.gz https://aur.archlinux.org/packages/${pkg:0:2}/$pkg/$pkg.tar.gz
    tar xzvf $pkg.tar.gz
    cd $pkg
    makepkg -csi --noconfirm
  "
}

pacman_install_packages() {
  pacman --noconfirm -S $@
}

yaourt_install_packages() {
  su - ${user} -c "yaourt --noconfirm -S $*"
}

# Create user {{{
if $add_user
then
  useradd -m -G wheel -s /bin/bash $user
  echo $user:$user_password | chpasswd
fi
# }}}

# Install sudo {{{
if $install_sudo
then
  pacman -S --noconfirm sudo
  sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers
fi
# }}}

# Grant user permission to install pacman packages
echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/pacman

# Install Yaourt {{{
if $install_yaourt
then
  aur_install_package "package-query"
  aur_install_package "yaourt"
fi
# }}}

# Gather packages to install
arch_packages=()
aur_packages=()

# Network Manager
arch_packages+=(networkmanager)

# VirtualBox modules {{{
if $install_virtualbox_modules
then
  arch_packages+=(virtualbox-guest-utils)
fi
# }}}

# i3 WM {{{
if $install_i3_wm
then
  arch_packages+=(
    xorg-server
    xorg-server-utils
    xf86-video-vesa
    lxdm
    i3-wm
    dmenu
    i3status
    i3lock
    conky
    lxappearance
  )
  aur_packages+=(industrial-arch-lxdm)
fi
# }}}

# Basic apps {{{
if $install_basic_apps
then
  arch_packages+=(
    terminus-font
    ttf-bitstream-vera
    ttf-droid
    ttf-inconsolata
    network-manager-applet
    gvim
    lxappearance
    kdebase-konsole
    kdebase-dolphin
    kde-l10n-pl
    firefox
    firefox-i18n-pl
    gst-plugins-good
    gst-libav
  )
  aur_packages+=(
    ttf-ms-fonts
  )
fi
# }}}

# Install packages
pacman_install_packages ${arch_packages[@]}
yaourt_install_packages ${aur_packages[@]}

# Configure packages
systemctl enable NetworkManager

# Configure VirtualBox {{{
if $install_virtualbox_modules
then
  # Load vbox modules at boot
  cat > /etc/modules-load.d/virtualbox.conf << EOL
  vboxguest
  vboxsf
  vboxvideo
EOL

  # Start vboxservice
  systemctl enable vboxservice
  echo "VBoxClient-all &" >> /etc/xprofile
fi
# }}}

# Configure i3 WM {{{
if $install_i3_wm
then
  # Set industrial-arch theme for lxdm
  sed -i 's/^theme=.*$/theme=industrial-arch-lxdm/' /etc/lxdm/lxdm.conf
  systemctl enable lxdm

  # Set konsole as the default terminal
  echo "export TERMINAL=konsole" > /etc/profile.d/i3-terminal.sh
fi
# }}}

# Revoke user permission to install pacman packages
rm /etc/sudoers.d/pacman

# vim: fdm=marker
