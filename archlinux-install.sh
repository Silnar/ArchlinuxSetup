#!/bin/bash

set -ex
set -o pipefail

readonly setup_partitions=true
readonly mount_partitions=true
readonly install_base=true
readonly configure_system=true
readonly setup_system=true

readonly partition_boot=/dev/sda1
readonly partition_root=/dev/sda2

# Check internet
wget -q --tries=10 --timeout=20 --spider http://google.com
if [[ ! $? -eq 0 ]]; then
  echo "Internet unavailable. Aborting..."
  exit 1
fi

# Setup partitions {{{
if $setup_partitions
then
  # Create partitions
  parted -s /dev/sda mktable msdos
  parted -s /dev/sda mkpart primary 0% 100m
  parted -s /dev/sda mkpart primary 100m 100%

  # Create filesystems
  mkfs.ext2 $partition_boot
  mkfs.ext4 $partition_root
fi
# }}}

# Mount partitions {{{
if $mount_partitions
then
  # Set up /mnt
  mount /dev/sda2 /mnt
  mkdir -p /mnt/boot
  mount /dev/sda1 /mnt/boot
fi
# }}}

# Install base {{{
if $install_base
then
  # Download selected mirrors urls
  url="https://www.archlinux.org/mirrorlist/?country=PL&country=DE&country=CZ&use_mirror_status=on"
  tmpfile=$(mktemp --suffix=-mirrorlist)
  curl -so ${tmpfile} ${url}
  sed -i 's/^#Server/Server/g' ${tmpfile}

  mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
  mv ${tmpfile} /etc/pacman.d/mirrorlist

  # Rankmirrors to make this faster (though it takes a while)
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
  rankmirrors -n 3 /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
  rm /etc/pacman.d/mirrorlist.tmp
  chmod +r /etc/pacman.d/mirrorlist

  # Update pacman db
  pacman -Syy

  # Install base packages (take a coffee break if you have slow internet)
  pacstrap /mnt base base-devel

  # Generate fstab
  genfstab -p /mnt >> /mnt/etc/fstab

  # Copy ranked mirrorlist over
  cp /etc/pacman.d/mirrorlist* /mnt/etc/pacman.d
fi
# }}}

# Configure system {{{
if $configure_system
then
  arch-chroot /mnt /bin/bash -s - "$partition_root" < archlinux-configure.sh
fi
# }}}

# Setup system {{{
if $setup_system
then
  arch-chroot /mnt /bin/bash < archlinux-setup.sh
fi
# }}}

# Unmount partitions {{{
if $mount_partitions
then
  # Unmount
  umount -R /mnt
fi
# }}}

echo "Done! Unmount the CD, then type 'reboot'."

# vim: fdm=marker
