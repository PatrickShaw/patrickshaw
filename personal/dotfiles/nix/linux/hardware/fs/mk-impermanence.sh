#!/usr/bin/env bash

# TODO: Quite dangerous - Maybe confirm it's the correct device by showing name
set -x
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

DEVICE="${1}"
# Find all mountpoints and unmount them
mountpoints=$(lsblk $DEVICE --output MOUNTPOINT --noheadings --raw)

for mountpoint in $mountpoints
do
    if [[ ! -z "$mountpoint" && "$mountpoint" != " " ]]; then
        echo "Unmounting $mountpoint"
        umount $mountpoint
    fi
done

echo -e "\n\nAll directories for $DEVICE have been unmounted."\n\n

echo -e "\n\nCreating new disk table\n\n"

echo -e "o\ny\nn\n1\n\n+512M\nef00\nn\n2\n\n\n8300\nw\ny\n" | gdisk ${DEVICE}
# Wait for the kernel to catch up with us
partprobe $DEVICE
sleep 1

BOOT_PART="${DEVICE}1"
LINUX_PART="${DEVICE}2"

echo -e "\n\nFormatting partitions\n\n"

# https://wiki.archlinux.org/title/EFI_system_partition#Format_the_partition
mkfs.fat -F 32 -n boot $BOOT_PART -f
mkfs.btrfs -L system $LINUX_PART -f

echo -e "\n\nCreating BTRFS subvolumes\n\n"

TEMP_DIR=$(mktemp -d)
mount $LINUX_PART $TEMP_DIR

# Mount the new BTRFS partition and create the subvolumes
TEMP_ROOT_MOUNT="${TEMP_DIR}/persist-root"
btrfs subvolume create $TEMP_ROOT_MOUNT
btrfs filesystem defrag -czstd -r -v $TEMP_ROOT_MOUNT
btrfs property set $TEMP_ROOT_MOUNT compression zstd:1
umount $TEMP_ROOT_MOUNT

TEMP_STORE_MOUNT="${TEMP_DIR}/nix-store"
btrfs subvolume create $TEMP_STORE_MOUNT
btrfs filesystem defrag -czstd -r -v $TEMP_STORE_MOUNT
btrfs property set $TEMP_STORE_MOUNT compression zstd:6
umount $TEMP_STORE_MOUNT

umount $LINUX_PART

echo -e "\n\nCreating final mount structure\n\n"

# Now mount in the correct spots
ROOT_VOL=$(mktemp -d)
PERSIST_VOL=$ROOT_VOL/persist
STORE_VOL="$PERSIST_VOL/nix/store"
BOOT_VOL="$ROOT_VOL/boot"

mkdir -p $ROOT_VOL $PERSIST_VOL $BOOT_VOL

mount -o subvol=persist-root $LINUX_PART $PERSIST_VOL

mount $BOOT_PART $BOOT_VOL

mkdir -p $STORE_VOL
mount -o subvol=nix-store $LINUX_PART $STORE_VOL

persist_dirs='/nix /nix/store /root /home /var /etc'
for persist_dir in $persist_dirs
do
  echo Persisting: $persist_dir
  mkdir -p $PERSIST_VOL$persist_dir
  mkdir -p $ROOT_VOL$persist_dir
  mount --bind $PERSIST_VOL$persist_dir $ROOT_VOL$persist_dir
done

echo -e "\n\nPrinting final UUIDs\n\n"

echo Boot: $(lsblk -no UUID $BOOT_PART)
echo Root: $(lsblk -no UUID $LINUX_PART)
echo Store: $(lsblk -no UUID $LINUX_PART)

echo Root dir: $ROOT_VOL
chmod o+rx $ROOT_VOL

nixos-generate-config --root $ROOT_VOL
