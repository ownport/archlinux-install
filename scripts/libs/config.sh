#!/bin/bash

set -eu

function achroot_exec() {

    arch-chroot /mnt /bin/bash -c "$@"
}

function config_lang() {

    info "Setting locale"

    local LANG="en_US.UTF-8"
    achroot_exec "sed -i '/^#$LANG/s/^#//' /etc/locale.gen"
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

function config_user_services() {

    echo "Configuring user services" && \
        achroot_exec "systemctl set-default multi-user.target"
}
