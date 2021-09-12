#!/usr/bin/env bash

backup_path="/tmp/backups_httpd/backup$(date +%F-%H-%M)"
src_apache="/etc/apache2/"
src_www="/var/www"
compress_path="${backup_path}.tar.gz"
days_to_keep=2

function error_msg () {
    echo -e "\e[0;31m\033[1m[!]\033[0m\e[0m ${1}"
}

function process_msg () {
    echo -e "\e[0;34m\033[1m[+]\033[0m\e[0m ${1}"
}

function success_msg () {
    echo -e "\e[0;32m\033[1m[+]\033[0m\e[0m ${1}"
}

function help () {
    echo -e "\nUsage: $(basename ${backup_path})"
}

function is_root() {
    if ((${EUID:-0} || "$(id -u)")); then
        error_msg "This script must be run as root"; exit 1;
    fi
}

function create_folders () {
    mkdir -p ${backup_path} &&\
        success_msg "Folders created successfully"
}

function delete_old_backups () {
    if [ ${days_to_keep} -gt 0 ]; then
        process_msg "Deleting backups older then ${days_to_keep} days"
        find ${backup_path}/* -mtime +${days_to_keep} -exec rm {} \;
        success_msg "Folders deleted successfully"
    fi
}

function compress_file () {
    tar -cpzf "${compress_path}"\
        ${src_apache}\
        ${src_www} &>/dev/null
}
