#!/bin/bash

set -e

# ==========================================================
# Unmount partitions (if applicable)
# 
function disk_unmount_partitions() {

    info "Unmount partition for /dev/sda1"
    if grep -qs '/dev/sda1' /proc/mounts; then
        umount --quiet /dev/sda1
    fi

    info "Unmount partition for /dev/sda3"
    if grep -qs '/dev/sda3' /proc/mounts; then
        umount --quiet /dev/sda3
    fi

    info "Unmount partition for /dev/sda4"
    if grep -qs '/dev/sda4' /proc/mounts; then
        umount --quiet /dev/sda4
    fi

    info "Unmount partition for /dev/sda2"
    if grep -qs '/dev/sda2' /proc/mounts; then
        umount --quiet /dev/sda2
    fi
}

# ==========================================================
# Wiping old partitions (if applicable)
# 
function disk_wipe_partitions() {

    warning "Destroy the GPT and MBR data structures on /dev/sda"

    info "Waiting for 10 secs" && \
        sleep 10 && \
        sgdisk --zap-all /dev/sda && 
    info "Wiping existing partitions on /dev/sda" && \
        wipefs --all --force /dev/sda
}

# ==========================================================
# Create partitions
# 
function disk_create_partitions() {

    # info "Create partition for EFI" && \
    #     parted -s /dev/sda mklabel gpt && \
    #     parted -s /dev/sda mkpart "efi" fat32 2048s 513MiB && \
    #     parted -s /dev/sda set 1 boot on && \
    #     parted -s /dev/sda set 1 esp on

    info "Create partition for boot" && \
        parted -s /dev/sda mklabel gpt && \
        parted -s /dev/sda mkpart "boot" fat32 0% 201MiB && \
        parted -s /dev/sda set 1 boot on && \
        parted -s /dev/sda set 1 esp on

    info "Create partition for root" && \
        parted -s /dev/sda mkpart "root" 201MiB 30Gib

    info "Create partition for home" && \
        parted -s /dev/sda mkpart "home" 30GiB 40Gib

    info "Create partition for data" && \
        parted -s /dev/sda mkpart "data" 40GiB 100%
}

# ==========================================================
# Format partitions
# 
function disk_format_partitions() {

    info "Format the root partition" && \
        yes | mkfs.ext4 -q /dev/sda2 && \
    info "Format the home partition" && \
        yes | mkfs.ext4 -q /dev/sda3 && \
    info "Format the data partition" && \
        yes | mkfs.ext4 -q /dev/sda4 && \
    info "Format the boot partition" && \
        yes | mkfs.fat -F32 /dev/sda1
}

# ==========================================================
# Mount partitions
# 
function disk_mount_partitions() {

    info "Mount the root partition" && \
        mount /dev/sda2 /mnt && \
    info "Mount the boot partition" && \
        mkdir -p /mnt/boot/ && \
        mount /dev/sda1 /mnt/boot && \
    info "Mount the home partition" && \
        mkdir -p /mnt/home && \
        mount /dev/sda3 /mnt/home && \
    info "Mount the data partition" && \
        mkdir -p /mnt/data && \
        mount /dev/sda4 /mnt/data
}

# ==========================================================
# Generate fstab
# 
function disk_generate_fstab() {

    info "Generate fstab and store it in /mnt/etc/fstab" && \
        genfstab -U -p /mnt >> /mnt/etc/fstab
}
