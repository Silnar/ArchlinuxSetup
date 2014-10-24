#!/bin/bash

HOSTNAME="archlinux"
ROOT_PASSWD="root"
USER="silnar"
USER_PASSWD="silnar"
PARTITION_BOOT=/dev/sda1
PARTITION_ROOT=/dev/sda2

SETUP_PARTITIONS=true
MOUNT_PARTITIONS=true
INSTALL_BASE=true
CONFIGURE_SYSTEM=true

INSTALL_VIRTUALBOX_MODULES=true
INSTALL_YAOURT=true

INSTALL_I3_WM=true
INSTALL_BASIC_APPS=true

# Print each command
set -x

# Check internet
wget -q --tries=10 --timeout=20 --spider http://google.com
if [[ ! $? -eq 0 ]]; then
  echo "Internet unavailable. Aborting..."
  exit 1
fi

if $SETUP_PARTITIONS # {{{
then
# Create partitions
parted -s /dev/sda mktable msdos
parted -s /dev/sda mkpart primary 0% 100m
parted -s /dev/sda mkpart primary 100m 100%

# Create filesystems
mkfs.ext2 $PARTITION_BOOT
mkfs.ext4 $PARTITION_ROOT
fi
# }}}

if $MOUNT_PARTITIONS # {{{
then
# Set up /mnt
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
fi
# }}}

if $INSTALL_BASE # {{{
then
# Rankmirrors to make this faster (though it takes a while)
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
rankmirrors -n 6 /etc/pacman.d/mirrorlist.orig > /etc/pacman.d/mirrorlist
pacman -Syy

# Install base packages (take a coffee break if you have slow internet)
pacstrap /mnt base base-devel

# Generate fstab
genfstab -p /mnt >> /mnt/etc/fstab

# Copy ranked mirrorlist over
cp /etc/pacman.d/mirrorlist* /mnt/etc/pacman.d
fi
# }}}

if $CONFIGURE_SYSTEM # {{{
then
# System configuration
arch-chroot /mnt /bin/bash <<EOF
# Set initial hostname
echo "$HOSTNAME" > /etc/hostname

# Set initial timezone
ln -s /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

# Set initial locale
echo LANG=pl_PL.UTF-8 > /etc/locale.conf
sed -i '/^#en_GB.UTF-8 UTF-8/s/^#//' /etc/locale.gen
sed -i '/^#en_GB ISO-8859-1/s/^#//' /etc/locale.gen
sed -i '/^#en_US.UTF-8 UTF-8/s/^#//' /etc/locale.gen
sed -i '/^#en_US ISO-8859-1/s/^#//' /etc/locale.gen
sed -i '/^#pl_PL.UTF-8 UTF-8/s/^#//' /etc/locale.gen
sed -i '/^#pl_PL ISO-8859-2/s/^#//' /etc/locale.gen
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
echo root:$ROOT_PASSWD | chpasswd

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
       APPEND root=$PARTITION_ROOT rw
       INITRD ../initramfs-linux.img


LABEL archfallback
       MENU LABEL Arch Linux Fallback
       LINUX ../vmlinuz-linux
       APPEND root=$PARTITION_ROOT rw
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


# Create user
useradd -m -G wheel -s /bin/bash $USER
echo $USER:$USER_PASSWD | chpasswd

# Install sudo
pacman -S --noconfirm sudo
sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers

# Install network manager
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# end section sent to chroot
EOF
fi
# }}}

if $INSTALL_VIRTUALBOX_MODULES # {{{
then
arch-chroot /mnt /bin/bash <<EOF
# Install vbox extensions and kernel modules
pacman --noconfirm -S virtualbox-guest-utils virtualbox-guest-modules

# Load vbox modules at boot
cat > /etc/modules-load.d/virtualbox.conf << EOL
vboxguest
vboxsf
vboxvideo
EOL

# Force load vbox modules now
while read module
  do modprobe "$module"
done < /etc/modules-load.d/virtualbox.conf

# Start vboxservice
systemctl enable vboxservice
systemctl start vboxservice
echo "VBoxClient-all &" >> /etc/xprofile
EOF
fi
# }}}

if $INSTALL_YAOURT # {{{
then
arch-chroot /mnt /bin/bash <<EOF
# Install yaourt
pushd /tmp
cat <<END | sudo -u $USER bash
set -x
curl -O https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
tar xzvf package-query.tar.gz
cd package-query
makepkg -s --noconfirm
END
pacman -U --noconfirm package-query/package-query*.tar.xz
popd

pushd /tmp
cat <<END | sudo -u $USER bash
set -x
curl -O https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
tar xzvf yaourt.tar.gz
cd yaourt
makepkg -s --noconfirm
END
pacman -U --noconfirm yaourt/yaourt*.tar.xz
popd
EOF
fi
# }}}

if $INSTALL_I3_WM # {{{
then
arch-chroot /mnt /bin/bash <<EOF
# Install xorg-server
pacman -S --noconfirm - <<END
xorg-server
xorg-server-utils
xf86-video-vesa
END

# Install lxdm
pacman -S --noconfirm lxdm

pacman -S --noconfirm --asdeps perl-error
pacman -S --noconfirm git
pushd /tmp
cat <<END | sudo -u $USER bash
set -x
curl -O https://aur.archlinux.org/packages/in/industrial-arch-lxdm/industrial-arch-lxdm.tar.gz
tar xzvf industrial-arch-lxdm.tar.gz
cd industrial-arch-lxdm
makepkg -s --noconfirm
END
pacman -U --noconfirm industrial-arch-lxdm/industrial-arch-lxdm*.tar.xz
popd

sed -i 's/^theme=.*$/theme=industrial-arch-lxdm/' /etc/lxdm/lxdm.conf
systemctl enable lxdm

# Install i3
pacman -S --noconfirm - <<END
i3-wm
dmenu
i3status
i3lock
END

EOF
fi
# }}}

if $INSTALL_BASIC_APPS # {{{
then
arch-chroot /mnt /bin/bash <<EOF
# Install basic apps
pacman -S --noconfirm - <<END
network-manager-applet
gvim
lxappearance
kdebase-konsole
kdebase-dolphin
kde-l10-pl
firefox
firefox-i18n-pl
gst-plugins-good
gst-libav
END

# TODO
#ttf-win7-fonts
#ttf-ms-fonts
EOF

if $INSTALL_I3_WM
then
arch-chroot /mnt /bin/bash <<EOF
# Set konsole as the default terminal
echo "export TERMINAL=konsole" > /etc/profile.d/i3-terminal.sh
EOF
fi
fi
# }}}

if $MOUNT_PARTITIONS # {{{
then
# Unmount
umount -R /mnt
fi
# }}}

echo "Done! Unmount the CD, then type 'reboot'."

# vim: fdm=marker
