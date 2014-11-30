#!/bin/bash

set -ex
set -o pipefail

source ./setup-config.sh

readonly add_user=true
readonly install_sudo=true
readonly install_yaourt=true
readonly install_virtualbox_modules=true
readonly install_system_utils=true

# Check internet connection {{{
wget -q --tries=10 --timeout=20 --spider http://google.com
if [[ ! $? -eq 0 ]]; then
  echo "Internet unavailable. Aborting..."
  echo "Try running: systemctl start dhcpcd"
  exit 1
fi
# }}}

# Helper functions {{{
aur_install_packages() {
  # Grant user permission to install pacman packages
  echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/pacman

  # Instal package
  for pkg in $@
  do
    su - ${user} -c "
      cd /tmp
      curl -o $pkg.tar.gz https://aur.archlinux.org/packages/${pkg:0:2}/$pkg/$pkg.tar.gz
      tar xzvf $pkg.tar.gz
      cd $pkg
      makepkg -csi --noconfirm
    "
  done

  # Revoke user permission to install pacman packages
  rm /etc/sudoers.d/pacman
}

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

# Install yaourt {{{
if $install_yaourt
then
  aur_install_packages package-query yaourt
fi
# }}}

# Setup NTP {{{
sed -i -e 's/^#NTP.*/NTP=0.pl.pool.ntp.org 1.pl.pool.ntp.org 2.pl.pool.ntp.org 3.pl.pool.ntp.org/' /etc/systemd/timesyncd.conf
sed -i -e 's/^#FallbackNTP.*/FallbackNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org/' /etc/systemd/timesyncd.conf
timedatectl set-ntp true
# }}}

# Install NetworkManager {{{
pacman_install_packages networkmanager
systemctl enable NetworkManager
# }}}

# Install VirtualBox modules {{{
if $install_virtualbox_modules
then
  pacman_install_packages virtualbox-guest-utils

  cat > /etc/modules-load.d/virtualbox.conf << EOL
vboxguest
vboxsf
vboxvideo
EOL

  systemctl enable vboxservice
  echo "VBoxClient-all &" >> /etc/xprofile
fi
# }}}

# Install system utils {{{
if $install_system_utils
then
  pacman_install_packages \
    alsa-utils \
    btrfs-progs \
    elinks \
    htop \
    ntfs-3g \
    pwgen \
    rfkill \
    rsync \
    smartmontools \
    traceroute \
    unrar \
    zsh \
    zsh-completions
fi
# }}}

# vim: fdm=marker
