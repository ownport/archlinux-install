#!/bin/bash

set -eu

# ==========================================================
# Check IP Connectivity
# 
function network_check_ip_connectivity() {

    info "Checking Internet connectivity"

    ping -c 1 -i 3 -W 5 -w 30 archlinux.org || {
        error "No Internet Connection"
    }
}



