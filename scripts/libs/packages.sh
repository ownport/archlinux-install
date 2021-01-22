#!/bin/bash

set -e

# ==========================================================
# Install package
#
function packages_install() {

    pacman -S --noconfirm $@
}

# ==========================================================
# Install package via archroot
#
function packages_archroot_install() {

    arch-chroot /mnt /bin/bash -c "pacman -S --noconfirm $@"
}

# ==========================================================
# Update package mirrors
#
function packages_update_mirrors() {

    info "Updating packages list" && \
        pacman -Sy && \
    info "Installing reflector" && \
        packages_install reflector && \
    info "Updating package mirrors" && \
        reflector --latest 5 --age 24 --sort rate --save /etc/pacman.d/mirrorlist && \
    info "Updating packages list" && \
        pacman -Sy
}

# ==========================================================
# Install Base System
#
function packages_install_base_system() {

    info "Installing Base System" && \
        yes | pacstrap -i /mnt \
            base
}

# ==========================================================
# Install Linux Core
#
function packages_install_linux_core() {

    info "Installing Linux Core" && \
        packages_archroot_install \
            linux && \
    info "Installing inter-ucode" && \
        packages_archroot_install \
            intel-ucode
            # linux-firmware
}

# ==========================================================
# Install boot system
#
function packages_install_boot_system() {
    
    info "Intalling Boot System" && \
        packages_archroot_install \
            efibootmgr \
            systemd-boot
}

# ==========================================================
# Install Console Tools
#
function packages_install_console_tools() {

    info "Installing console tools" && \
        packages_archroot_install \
            neovim
}

# git \
# base-devel \
# lvm2 \
# net-tools \
# dialog \
# wpa_supplicant \

# ==========================================================
# Install Base Networking
#
function packages_install_base_networking() {

    info "Installing Base Networking" && \
        packages_archroot_install \
            dhcpcd \
            net-tools \
            openssh

    info "Activating DHCP client service" && \
        achroot_exec "systemctl enable dhcpcd.service"
}

# ==========================================================
# Install Wireless Networking
#
function packages_install_wireless_networking() {

    info "Installing Wireless Networking" && \
        packages_archroot_install \
            iw \
            openresolv \
            netctl \
            wireless_tools \
            wpa_supplicant
}
