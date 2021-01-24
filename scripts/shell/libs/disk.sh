#!/bin/bash

set -eu


# ==========================================================
# Detect disk type
# 
function disk_detect_type() {

    if [ -n "$(echo $DEVICE | grep "^/dev/[a-z]d[a-z]")" ]; then
        return "SATA"
    elif [ -n "$(echo $DEVICE | grep "^/dev/nvme")" ]; then
        return "NVME"
    elif [ -n "$(echo $DEVICE | grep "^/dev/mmc")" ]; then
        return "MMC"
    fi
    return "UNKNOWN"
}

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

    # https://wiki.archlinux.org/index.php/Solid_state_drive
    #
    # Set DEVICE_TRIM = "true" if your device supports TRIM
    #
    # if [ "$DEVICE_TRIM" == "true" ]; then
    #     sed -i 's/relatime/noatime/' /mnt/etc/fstab
    #     arch-chroot /mnt systemctl enable fstrim.timer
    # fi
}

# ==========================================================
# Configure GRUB
# 
function disk_config_grub() {

    info "Setting GRUB" && \
        achroot_exec "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ArchLinux --recheck" && \
        achroot_exec "grub-mkconfig -o /boot/grub/grub.cfg" && \
        achroot_exec "chmod -R g-rwx,o-rwx /boot"
}

# ==========================================================
# Configure systemd-boot
# 
function disk_config_systemd_boot() {

    LOADER_CONF="/mnt/boot/loader/loader.conf"
    ARCH_LOADER_CONF="/mnt/boot/loader/entries/archlinux.conf"
    SYSTEMD_BOOT_HOOK="/mnt/etc/pacman.d/hooks/systemd-boot.hook"
    ROOT_UUID="$(blkid -s UUID -o value /dev/sda2)"

    info "Setting systemd-boot" && \
        achroot_exec "systemd-machine-id-setup"

    info "Installing Systemd-Boot to /boot" && \
        achroot_exec "bootctl --path=/boot install"

    info "Configuring pacman hooks for systemd-boot" && \
        mkdir -p /mnt/etc/pacman.d/hooks/ && \
        echo "[Trigger]" > $SYSTEMD_BOOT_HOOK
        echo "Type = Package" >> $SYSTEMD_BOOT_HOOK
        echo "Operation = Upgrade" >> $SYSTEMD_BOOT_HOOK
        echo "Target = systemd" >> $SYSTEMD_BOOT_HOOK
        echo "" >> $SYSTEMD_BOOT_HOOK
        echo "[Action]" >> $SYSTEMD_BOOT_HOOK
        echo "Description = Updating systemd-boot" >> $SYSTEMD_BOOT_HOOK
        echo "When = PostTransaction" >> $SYSTEMD_BOOT_HOOK
        echo "Exec = /usr/bin/bootctl update" >> $SYSTEMD_BOOT_HOOK
        echo "" >> $SYSTEMD_BOOT_HOOK

    info "Updating loader configuration: ${LOADER_CONF}" && \
        echo 'default       archlinux.conf' > $LOADER_CONF && \
        echo 'timeout       3' >> $LOADER_CONF && \
        echo 'editor        no' >> $LOADER_CONF && \
        echo 'console-mode  max' >> $LOADER_CONF

    info "Adding loader: ${ARCH_LOADER_CONF}" && \
        echo "title    Arch Linux" > $ARCH_LOADER_CONF && \
        echo "linux    /vmlinuz-linux" >> $ARCH_LOADER_CONF && \
        echo "initrd   /intel-ucode.img" >> $ARCH_LOADER_CONF && \
        echo "initrd   /initramfs-linux.img" >> $ARCH_LOADER_CONF && \
        echo "options  root='UUID=${ROOT_UUID}' rw" >> $ARCH_LOADER_CONF

    info "Updating systemd-boot " && \
        achroot_exec "bootctl update"
}
