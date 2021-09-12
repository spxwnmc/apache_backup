#!/usr/bin/env bash

# Luis Gerardo

backup_path="/tmp/backups_httpd/"
src_apache="/etc/apache2/"
src_www="/var/www/"
today="$(date +%F-%H-%M)"
compress_path="${backup_path}/backup${today}.tar.gz"
days_to_keep=2
username_remote_host="spawn"
ip_remote_host="192.168.100.65"
date_proccess=""

green="\e[0;32m\033[1m"
resetc="\033[0m\e[0m"
red="\e[0;31m\033[1m"
blue="\e[0;34m\033[1m"
yellow="\e[0;33m\033[1m"
purple="\e[0;35m\033[1m"
turquoise="\e[0;36m\033[1m"
gray="\e[0;37m\033[1m"

function error_msg () {
    echo -e "${red}[!] ${yellow}$(date +%F-%H-%M-%S)${resetc} ${1}"
}

function process_msg () {
    echo -e "${blue}[-] ${yellow}$(date +%F-%H-%M-%S)${resetc} ${1}"
}

function success_msg () {
    echo -e "${green}[+] ${yellow}$(date +%F-%H-%M-%S)${resetc} ${1}"
}

function help () {
    echo -e "\nUsage: 
    # $(basename ${0})
            or
    sudo|doas $(basename ${0})"
}

function is_root() {
    if ((${EUID:-0} || "$(id -u)")); then
        error_msg "This script must be run as root"; help; exit 1;
    fi
}

function create_folders () {
    process_msg "Creating folders"
    mkdir -p ${backup_path} &&\
        success_msg "Folders created successfully"
}

function delete_old_backups () {
    if [ ${days_to_keep} -gt 0 ]; then
        process_msg "Deleting backups older then ${days_to_keep} days"
        find ${backup_path}/* -mtime +${days_to_keep} -delete 2>/dev/null
        success_msg "Folders deleted successfully"
    fi
}

function compress_file () {
    process_msg "Compressing backup"
    tar -cpzf "${compress_path}"\
        ${src_apache}\
        ${src_www} &>/dev/null &&\
        success_msg "Backup has been compressed successfully" ||\
        error_msg "The backup could not be compressed"
}

function send_to_server () {
    process_msg "Creating remote folder"
    ssh ${username_remote_host}@${ip_remote_host} "mkdir -p /home/spawn/backups_httpd" &&\
        success_msg "Remote folder created successfully" ||\
        error_msg "Could not create remote folder"
    process_msg "Transferring backup to remote host"
    rsync -avzhe ssh ${compress_path} ${username_remote_host}@${ip_remote_host}:/home/spawn/backups_httpd &>/dev/null &&\
        success_msg "Backup transferred successfully" ||\
        error_msg "The backup could not be transferred"
}

function send_telegram_alert () {
    local userid="-1001360923905"
    local key="1627634127:AAEFVFK6cLfMqKHZFuoiUTTF4-3aVNOingg"
    local timeout="10"
    local url="https://api.telegram.org/bot${key}/sendMessage"
    local sonido=0
    local exec_date="$(date "+%d %b %H:%M:%S")"
    [[ ${3} -eq 1 ]] && sonido=1
    process_msg "Sending menssage to Telegram"
    local texto="<b>${exec_date}:</b>\n<pre>${1}</pre>\n${2}"
    curl -s --max-time ${timeout} -d "parse_mode=HTML&disable_notification=\
        ${sonido}&chat_id=${userid}&disable_web_page_preview=1&text=\
        $(echo -e "${texto}")" ${url} &>/dev/null &&\
        success_msg "Message to Telegram sent successfully"
}

function main () {
    is_root
    create_folders
    delete_old_backups
    compress_file
    send_to_server
    send_telegram_alert "The backup has been saved successfully"\
    "\nThe backup has been saved to the host ${ip_remote_host},
    <i>For more information check the path where the backups are saved withing the remote host:</i>
        \n<pre>/home/spawn/backups_httpd</pre>" 1
}

main
