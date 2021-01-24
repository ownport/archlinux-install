#!/bin/bash

set -eu

source libs/console.sh
source libs/network.sh
source libs/disk.sh
source libs/datetime.sh
source libs/packages.sh
source libs/config.sh
source libs/tests.sh


warning "The automated installation will be started in 10 secs" && \
    sleep 10

info "ArchLinux Installation"

info "Updating local packages" && \
    network_check_ip_connectivity && \
    packages_pacman_config && \
    packages_update_mirrors

datetime_sync

info "Preparing disk before installation" && 
    disk_unmount_partitions && \
    disk_wipe_partitions && \
    disk_create_partitions && \
    disk_format_partitions && \
    disk_mount_partitions

info "Installing Core System Components" && \
    packages_install_base_system && \
    packages_pacman_config /mnt/etc/pacman.conf && \
    disk_generate_fstab && \
    packages_install_linux_core && \
    packages_install_boot_packages && \
    packages_install_console_tools

info "Base system configuration" && \
    config_lang && \
    config_timezone && \
    config_hostname && \
    config_passwd && \
    disk_config_systemd_boot && \

info "Networking install and configuration" && \
    packages_install_base_networking && \
    packages_install_wireless_networking

info "Configuring services" && \
    config_user_services

info "ArchLinux Installation Completed"

info "Runnig tests"
test_efi_settings
test_boot_configuration

