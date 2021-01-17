#!/bin/bash

set -e

echo "[INFO] ArchLinux Installation"

echo "[INFO] Checking Internet connectivity"
ping -c 5 archlinux.org || {
    echo "[ERROR] No Internet Connection"
    exit 1
}


