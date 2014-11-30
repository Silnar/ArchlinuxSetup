#!/bin/bash

set -ex
set -o pipefail

source ./setup-config.sh

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

# Install misc tools {{{
pacman_install_packages  \
  samba \
  clamav

yaourt_install_packages \
  attic-git \
  ranger-git
# }}}

# Install printing tools {{{
pacman_install_packages \
  cups \
  hplip

yaourt_install_packages \
  hplip-plugin
# }}}

# Install programming tools {{{
pacman_install_packages \
  gvim \
  git \
  mercurial \
  subversion \
  the_silver_searcher \
  ruby \
  go

yaourt_install_packages \
  jdk
# }}}

# Install office suite {{{
pacman_install_packages \
  libreoffice-still-calc \
  libreoffice-still-draw \
  libreoffice-still-impress \
  libreoffice-still-kde4 \
  libreoffice-still-writer
# }}}

# Install music apps {{{
pacman_install_packages \
  ario \
  asunder \
  exfalso \
  gstreamer0.10-bad-plugins \
  gstreamer0.10-ffmpeg \
  gstreamer0.10-ugly-plugins \
  mpc \
  mpd
# }}}

# Install graphic apps {{{
pacman_install_packages \
  blender \
  darktable \
  filezilla \
  geeqie \
  gimp \
  hugin \
  imagemagick \
  inkscape \
  mypaint
# }}}

# Install video apps {{{
pacman_install_packages \
  mplayer \
  smplayer \
  smplayer-themes \
  smtube \
  vlc
# }}}

# Install other apps {{{
pacman_install_packages \
  dvd+rw-tools \
  k3b \
  kdegraphics-okular \
  kdeutils-filelight \
  kdiff3 \
  ktorrent \
  mobac \
  qcad \
  skype \
  steam \
  stellarium \
  unison \
  virtualbox
# }}}

# vim: fdm=marker
