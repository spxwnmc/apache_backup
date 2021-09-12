#!/usr/bin/env bash

backup_path="/tmp/backups_httpd/backup$(date +%F-%H-%M)"
src_apache="/etc/apache2/"
src_www="/var/www/"
compress_path="${backup_path}.tar.gz"
days_to_keep=2
username_remote_host="spawn"
ip_remote_host="192.168.100.65"
date_proccess="$(date +%F-%H-%M-%S)"

green="\e[0;32m\033[1m"
resetc="\033[0m\e[0m"
red="\e[0;31m\033[1m"
blue="\e[0;34m\033[1m"
yellow="\e[0;33m\033[1m"
purple="\e[0;35m\033[1m"
turquoise="\e[0;36m\033[1m"
gray="\e[0;37m\033[1m"

function error_msg () {
    echo -e "${red}[!] ${yellow}${date_proccess}${resetc} ${1}"
}

function process_msg () {
    echo -e "${blue}[-] ${yellow}${date_proccess}${resetc} ${1}"
}

function success_msg () {
    echo -e "${green}[+] ${yellow}${date_proccess}${resetc} ${1}"
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

function send_to_server () {
    ssh ${username_remote_host}@${ip_remote_host} "mkdir -p /home/spawn/backups_httpd"
    rsync -avzhe ssh ${compress_path} ${username_remote_host}@${ip_remote_host}:/home/spawn/backups_httpd &>/dev/null
}

function send_telegram_alert () {
    local userid="-1001360923905"
    local key="1627634127:AAEFVFK6cLfMqKHZFuoiUTTF4-3aVNOingg"
    local timeout="10"
    local url="https://api.telegram.org/bot${key}/sendMessage"
    local log="envio_telegram_${DATE}.log"
    local sonido=0
    local exec_date="$(date "+%d %b %H:%M:%S")"
    [[ ${3} -eq 1 ]] && sonido=1
    process_msg "Sending a menssage to Telegram"
    local texto="<b>${exec_date}:</b>\n<pre>${1}</pre>\n${2}"
    curl -s --max-time ${timeout} -d "parse_mode=HTML&disable_notification=\
        ${sonido}&chat_id=${userid}&disable_web_page_preview=1&text=\
        $(echo -e "${texto}")" ${url} &>/dev/null &&\
        success_msg "Message to Telegram sent successfully"
}
