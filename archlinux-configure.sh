#!/bin/bash

set -ex
set -o pipefail

readonly hostname="archlinux"
readonly root_password="root"
readonly partition_root="${1}"

# Set initial hostname
echo "$hostname" > /etc/hostname

# Set initial timezone
ln -s /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

# Set initial locale
echo LANG=pl_PL.UTF-8 > /etc/locale.conf
sed -i '
/^#pl_PL.UTF-8 UTF-8/s/^#//
/^#pl_PL ISO-8859-2/s/^#//
/^#en_GB.UTF-8 UTF-8/s/^#//
/^#en_GB ISO-8859-1/s/^#//
/^#en_US.UTF-8 UTF-8/s/^#//
/^#en_US ISO-8859-1/s/^#//
' /etc/locale.conf
locale-gen

# Set locale
echo LANG=pl_PL.UTF-8 > /etc/locale.conf

# Configure vconsole
cat <<END > /etc/vconsole.conf
KEYMAP=pl
FONT=lat2-16
FONT_MAP=8859-2
END

# Create a new initial RAM disk
mkinitcpio -p linux

# Set root password to "root"
echo root:$root_password | chpasswd

# Install syslinux bootloader
pacman -S syslinux --noconfirm
syslinux-install_update -i -a -m

# Update syslinux config with correct root disk
curl -o /boot/syslinux/splash.png https://projects.archlinux.org/archiso.git/plain/configs/releng/syslinux/splash.png
sed -i -e "
  /UI menu.c32/s/^/# /
  /UI vesamenu.c32/s/^#//
  /MENU BACKGROUND/s/^#//
  /UI vesamenu.c32/a\
\\
\\
MENU WIDTH 78\\
MENU MARGIN 4\\
MENU ROWS 5\\
MENU VSHIFT 10\\
MENU TIMEOUTROW 13\\
MENU TABMSGROW 11\\
MENU CMDLINEROW 11\\
MENU HELPMSGROW 16\\
MENU HELPMSGENDROW 29
  s/APPEND root=.*rw/APPEND root=${partition_root//\//\\/} rw/
" /boot/syslinux/syslinux.cfg

