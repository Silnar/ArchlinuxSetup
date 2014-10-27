#!/bin/bash

user=silnar

pacman_grant_permissions() {
  sed -i -e '/^#includedir \/etc\/sudoers.d/s/#//' /etc/sudoers
  echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/pacman
}

pacman_revoke_permissions() {
  sed -i -e '/^includedir \/etc\/sudoers.d/s/^/#/' /etc/sudoers
  rm /etc/sudoers.d/pacman
}

pacman_install_packages() {
  pacman --noconfirm -S $@
}

aur_make_packages() {
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
}

aur_install() {
  su - ${user} -c "yaourt --noconfirm -S $@"
}


# vim: fdm=marker
