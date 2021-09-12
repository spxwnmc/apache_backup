#!/usr/bin/env bash

backup_path="/tmp/backups_httpd/backup$(date +%F-%H-%M)"
src_apache="/etc/apache2/"
src_www="/var/www/"
dest_apache="/apache2/"
dest_www="/www/"

