#!/bin/bash

set -eu

function test_efi_settings() {

    info "Test: EFI Settings"
}

function test_boot_configuration() {

    info "Test: Boot Configuration"
    
    if [ ! -f "/mnt/boot/initramfs-linux.img" ]; then
        warning "Missed /boot/initramfs-linux.img"
    fi
    if [ ! -f "/mnt/boot/intel-ucode.img" ]; then
        warning "Missed /boot/intel-ucode.img"
    fi
    if [ ! -f "/mnt/boot/vmlinuz-linux" ]; then
        warning "Missed /boot/vmlinuz-linux"
    fi
}