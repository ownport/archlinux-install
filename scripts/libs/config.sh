#!/bin/bash

set -e

function achroot_exec() {

    arch-chroot /mnt /bin/bash -c "$@"
}

function config_lang() {

    info "Setting locale"

    local LANG="en_US.UTF-8"
    achroot_exec "export LANG=$LANG; sed -i '/^#$LANG/s/^#//' /etc/locale.gen"
    achroot_exec "locale-gen"
    achroot_exec "echo LANG=$LANG > /etc/locale.conf"
}

function config_timezone() {

    info "Setting timezone"

    achroot_exec "ln -fs /usr/share/zoneinfo/UTC /etc/localtime"
    achroot_exec "hwclock --systohc --utc"
}

function config_passwd() {

    info "Setting ${USER} password" && \
        achroot_exec "passwd"
}

function config_hostname() {

    HOSTNAME=${1:-archbox}
    info "Setting hostname: ${HOSTNAME}"

    achroot_exec "echo $HOSTNAME" > /etc/hostname
}

function config_grub() {

    info "Setting GRUB" && \
        achroot_exec "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ArchLinux --recheck" && \
        achroot_exec "grub-mkconfig -o /boot/grub/grub.cfg" && \
        achroot_exec "chmod -R g-rwx,o-rwx /boot"
}

function config_systemd_boot() {

    LOADER_CONF="/boot/loader/loader.conf"
    ARCH_LOADER_CONF="/boot/loader/entries/archlinux.conf"

    info "Setting systemd-boot" && \
    info "Installing Systemd-Boot to /boot" && \
        achroot_exec "bootctl --path=/boot install"

    info "Updating loader configuration: ${LOADER_CONF}" && \
        achroot_exec "echo 'default       archlinux.conf'> $LOADER_CONF" && \
        achroot_exec "echo 'timeout       3' >> $LOADER_CONF" && \
        achroot_exec "echo 'editor        no' >> $LOADER_CONF" && \
        achroot_exec "echo 'console-mode  max' >> $LOADER_CONF"

    info "Adding loader: ${ARCH_LOADER_CONF}" && \
        achroot_exec "echo 'title    Arch Linux' > $ARCH_LOADER_CONF" && \
        achroot_exec "echo 'linux    /vmlinuz-linux' >> $ARCH_LOADER_CONF" && \
        achroot_exec "echo 'initrd   /intel-ucode.img' >> $ARCH_LOADER_CONF" && \
        achroot_exec "echo 'initrd   /initramfs-linux.img' >> $ARCH_LOADER_CONF" && \
        achroot_exec "echo 'options  root=/dev/sda2 rw' >> $ARCH_LOADER_CONF"

    info "Updating systemd-boot " && \
        achroot_exec "bootctl update"
}
