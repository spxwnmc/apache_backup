#!/usr/bin/env bash

backup_path="/tmp/backups_httpd/backup$(date +%F-%H-%M)"
src_apache="/etc/apache2/"
src_www="/var/www/"
dest_apache="/apache2/"
dest_www="/www/"

function error_msg () {
    echo -e "\e[0;31m\033[1m[!]\033[0m\e[0m ${1}"
}

function process_msg () {
    echo -e "\e[0;34m\033[1m[+]\033[0m\e[0m ${1}"
}

function success_msg () {
    echo -e "\e[0;32m\033[1m[+]\033[0m\e[0m ${1}"
}

function is_root() {
    if ((${EUID:-0} || "$(id -u)")); then
        error_msg "This script must be run as root"; exit 1;
    fi
}

function create_folders () {
    mkdir -p ${backup_path}/{${dest_apache},${dest_www}} &&\
        success_msg "Folders created successfully"
}
