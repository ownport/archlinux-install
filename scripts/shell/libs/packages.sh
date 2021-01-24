#!/bin/bash

set -eu

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

    arch-chroot /mnt pacman -S --noconfirm $@
}

# ==========================================================
# Pacman Configuration
#
function packages_pacman_config() {

    PACMAN_CONFIG=${1:-/etc/pacman.conf}
    info "Configuring pacman: ${PACMAN_CONFIG}" && \
        sed -i 's/#Color/Color/' ${PACMAN_CONFIG}
        sed -i 's/#TotalDownload/TotalDownload/' ${PACMAN_CONFIG}
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

    info "Installing Linux Core Packages" && \
        packages_archroot_install \
            linux # && \
    # info "Installing Linux Firmware Packages" && \
    #     packages_archroot_install \
    #         linux-firmware && \
    info "Installing inter-ucode package" && \
        packages_archroot_install \
            intel-ucode
}

# ==========================================================
# Install boot system
#
function packages_install_boot_packages() {
    
    info "Intalling Boot Packages" && \
        packages_archroot_install \
            efibootmgr 
}

# ==========================================================
# Install Console Tools
#
function packages_install_console_tools() {

    info "Installing Console Packages" && \
        packages_archroot_install \
            zsh \
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

    echo "Configuring network services" && \
        achroot_exec "systemctl enable dhcpcd.service" && \
        achroot_exec "systemctl enable systemd-networkd.service" && \
        achroot_exec "systemctl enable systemd-resolved.service"
}

# ==========================================================
# Install Wireless Networking
#
function packages_install_wireless_networking() {

    SYSTEMD_NETWORK_WIRELESS_CONF="/mnt/etc/systemd/network/25-wireless.network"

    info "Installing Wireless Networking" && \
        packages_archroot_install \
            iwd

    info "Configuring wireless services" && \
        achroot_exec "systemctl enable iwd.service"

    echo "[Match]" > $SYSTEMD_NETWORK_WIRELESS_CONF
    echo "Name=wlan0" >> $SYSTEMD_NETWORK_WIRELESS_CONF
    echo "" >> $SYSTEMD_NETWORK_WIRELESS_CONF
    echo "[Network]" >> $SYSTEMD_NETWORK_WIRELESS_CONF
    echo "DHCP=ipv4" >> $SYSTEMD_NETWORK_WIRELESS_CONF
}
