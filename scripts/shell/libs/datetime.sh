#!/bin/bash

set -e

# ==========================================================
# Sync date and time
# 
function datetime_sync() {

    info "Verify that the system clock is up to date" && \
        timedatectl set-ntp true
}

