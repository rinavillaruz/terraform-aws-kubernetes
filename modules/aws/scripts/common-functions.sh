#!/bin/bash

log_step() {
    local step="$1"
    local message="$2"
    echo "[$step] $message" | sudo tee -a /var/log/k8s-install-success.txt > /dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$step] $message"
}

log_error() {
    local step="$1"
    local message="$2"
    echo "ERROR [$step] $message" | sudo tee -a /var/log/k8s-install-error.txt > /dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR [$step] $message" >&2
}

check_command() {
    if [ $? -ne 0 ]; then
        log_error "$1" "$2"
        exit 1
    fi
}

# New log_file function for detailed debug logging
log_file() {
    local message="$1"
    local log_file="$2"
    
    if [ -z "$log_file" ] || [ "$log_file" = "" ]; then
        # Console only - no file logging
        echo "$message"
    else
        # Log to file and console
        echo "$message" | tee -a "$log_file"
    fi
}