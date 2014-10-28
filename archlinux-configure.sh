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
cat <<END > /boot/syslinux/syslinux.cfg
UI vesamenu.c32
DEFAULT arch
PROMPT 0
MENU TITLE Boot Menu
MENU BACKGROUND splash.png
TIMEOUT 50

MENU WIDTH 78
MENU MARGIN 4
MENU ROWS 5
MENU VSHIFT 10
MENU TIMEOUTROW 13
MENU TABMSGROW 11
MENU CMDLINEROW 11
MENU HELPMSGROW 16
MENU HELPMSGENDROW 29

# Refer to http://www.syslinux.org/wiki/index.php/Comboot/menu.c32

MENU COLOR border       30;44   #40ffffff #a0000000 std
MENU COLOR title        1;36;44 #9033ccff #a0000000 std
MENU COLOR sel          7;37;40 #e0ffffff #20ffffff all
MENU COLOR unsel        37;44   #50ffffff #a0000000 std
MENU COLOR help         37;40   #c0ffffff #a0000000 std
MENU COLOR timeout_msg  37;40   #80ffffff #00000000 std
MENU COLOR timeout      1;37;40 #c0ffffff #00000000 std
MENU COLOR msg07        37;40   #90ffffff #a0000000 std
MENU COLOR tabmsg       31;40   #30ffffff #00000000 std


LABEL arch
       MENU LABEL Arch Linux
       LINUX ../vmlinuz-linux
       APPEND root=$partition_root rw
       INITRD ../initramfs-linux.img


LABEL archfallback
       MENU LABEL Arch Linux Fallback
       LINUX ../vmlinuz-linux
       APPEND root=$partition_root rw
       INITRD ../initramfs-linux-fallback.img

LABEL hdt
       MENU LABEL HDT (Hardware Detection Tool)
       COM32 hdt.c32

LABEL reboot
       MENU LABEL Reboot
       COM32 reboot.c32

LABEL shutdown
       MENU LABEL Power Off
       COMBOOT poweroff.com
END

