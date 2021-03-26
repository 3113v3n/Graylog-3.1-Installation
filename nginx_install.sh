#!/bin/bash

#####################################################
# Author: Sidney Omondi
# Version: v1.0.5
# Date: 2020-01-28
# Description: install NGINX for GRAYLOG!
# Usage: ./install_nginx.sh -d < domain > -e < mail >
#########################################################

source $(dirname $0)/lib/function-library.sh
graylog_config_file="/etc/graylog/server/server.conf"
nginx_conf_file="/etc/nginx/nginx.conf"
Public_IP=""
Public_Port=""
working_directory=$( dirname "$0" )
main(){
initialize_colors
#we need to switch to root user
if [[ $EUID -ne 0 ]]
then
  nonRootUser
fi
#Check for File Sourcing
#  if [[ -z "$PS1" ]]; then
#    echo -e "Script needs to be sourced"
#    echo " Example:
#         source $(basename $0) -d <domain> -e <email>
#    "
#    exit 1
#  fi

checkTags "$@"
}

function nonRootUser(){
  echo -e " ${R}[!] SCRIPT NEEDS TO RUN AS ${RESET}${BRed}ROOT${RESET}"
  echo -e "Moving Script to Your Root directory. Swith to ${BYellow}ROOT USER [/root/GrayLog_3.1]${normal_color} and execute script from there"

  sleep 1
  if [[ -d "/root/GrayLog_3.1" ]]
   then sudo rm -rf "/root/GrayLog_3.1"
  fi
   sudo  mkdir /root/GrayLog_3.1
  #$(dirname $0)/$(basename $0)
  sudo cp -r * /root/GrayLog_3.1/ && echo -e "${green_color}Copying Done !!! ${RESET}"
  cd /root/GrayLog_3.1

  sudo su
  #echo -e "You need to run the script again"
  #
  exit 1
}
function checkTags(){
 local OPTIND opt i
 while getopts "d:e:huC" opt; do
 case "$opt" in
 d)  domain="$OPTARG" ;;

 e)  account_mail="$OPTARG";;

 u) remove_nginX
   ;;
C) PerformCleanUp $working_directory
  ;;
:) usage
  exit 1
  ;;
 h) usage
    exit 0 ;;

 ?) usage;exit 1 ;;
 esac
 done
   shift $(( OPTIND -1 ))
test_nginx_Arguments $domain $account_mail fullInstallation usage
}

usage(){
echo -e "
Usage: ${O}[-]  ./$(basename $0).sh -d  <YOUR_DOMAIN> -e <ACME_ACCOUNT_MAIL>${RESET}
PARAMETRES:
===========
    YOUR_DOMAIN           testdomain.co.ke
    ACME_ACCOUNT_MAIL    info@testmail.com

OPTIONS:
========

    -h              help
    -d [Required]   Pass in the Domain of your organization
    -e [Required]   Pass in email that will be used to setup your graylog account
    -C              Perform Cleanup and remove all Graylog installation files from host machine
    -u              Removes Nginx Installation

EXAMPLE:
=========

${O}[-] source ./$(basename $0).sh -d testdomain.co.ke -e info@testmail.com${RESET}

${O}[-] source ./$(basename $0).sh -[ u | h | C ] ${RESET}
"
}
installNginX(){
  #Ensure user inputs Public IP and PORT
  while true; do

  read -p "Enter the port you entered during ${read_blue_color}INSTALLATION OF GRAYLOG${read_normal_color} using script [ Default: 9000 ]: " DEFAULT_PORT
  echo
  read -p "Enter your ${read_green_color}Graylog Public Ip${read_normal_color}: " GRAYLOG_IP
  read -p "Enter your ${read_green_color}Graylog Public Port ${read_normal_color}: " GRAYLOG_PORT
  if [[ -z "$GRAYLOG_IP" || -z "$GRAYLOG_PORT" ]]
  then
  echo
  echo -e "${R}[*] Please Provide values for Your Graylog IP and Port !!!!! ${normal_color}"
  echo
  else
    break
  fi
 done

  if [[ -z "$DEFAULT_PORT" ]]
  then
    default_graylog_port="9000"
  else
    default_graylog_port=$DEFAULT_PORT
  fi

  Public_IP=$GRAYLOG_IP
  Public_Port=$GRAYLOG_PORT
  sleep 0.2
  sudo apt install bash-completion
  if [[ ! -d "acme.sh" ]]
  then
  cd /
  git clone https://github.com/acmesh-official/acme.sh.git
  fi
	cd acme.sh
  #sleep 0.1
./acme.sh --install --accountemail "$account_mail"

source ~/.bashrc
sudo ufw enable
sudo ufw allow 80,22,${Public_Port}/tcp

sudo apt install -y nginx
#stop NGINX
sudo systemctl stop nginx.service
./acme.sh --issue --standalone -d "$domain" --keylength 2048 #|| acme.sh --issue --standalone -d "$domain" --keylength ec-256

#make Directory for certs
sudo mkdir -p /etc/letsencrypt/$domain #&& sudo mkdir -p /etc/letsencrypt/${domain}_ecc
directory="/etc/letsencrypt/$domain"

#restart NGINX
sudo systemctl restart nginx.service
#install CERTS to our folder
./acme.sh --install-cert -d "$domain" --cert-file $directory/cert.pem --key-file $directory/private.key --fullchain-file $directory/fullchain.pem --reloadcmd "sudo systemctl restart nginx.service"
echo
#acme.sh --install-cert -d "$domain" --ecc --cert-file ${directory}_ecc/cert.pem --key-file ${directory}_ecc/private.key --fullchain-file ${directory}_ecc/fullchain.pem --reloadcmd "sudo systemctl restart nginx.service"
}

configureGraylogEmails(){
	#switch to normal username
	su $USERNAME
#read -p "Enter Your email Authentication Username for Graylog:" EMAIL
 stty -echo
read -p "[+] Enter the Password for the Email you provided ${read_brown_color}[$account_mail]${read_normal_color}: " PASS
 stty echo
 read -p "[+] Enter Your Mail Subject Prefix: [default: graylog ] " subject


if [[ -z $subject ]]
then
		mail_subject="graylog"
else
	mail_subject=$sublect
fi

sed -i "/^#transport_email_enabled = false/ s/#transport_email_enabled = false/transport_email_enabled = true/ ;/^#transport_email_hostname = mail.example.com/ s/#transport_email_hostname = mail.example.com/transport_email_hostname = smtp.gmail.com/ ; /^#transport_email_port = 587/ s/#transport_email_port = 587/transport_email_port = 465/; /^#transport_email_use_auth = true/ s/#transport_email_use_auth = true/transport_email_use_auth = true/; /^#transport_email_auth_username = you@example.com/ s/#transport_email_auth_username = you@example.com/transport_email_auth_username = $account_mail/; /^#transport_email_auth_password = secret/ s/#transport_email_auth_password = secret/transport_email_auth_password = $PASS/; /^#transport_email_subject_prefix = [graylog]/ s/#transport_email_subject_prefix = [graylog]/transport_email_subject_prefix = [$mail_subject]/; /^#transport_email_from_email = graylog@example.com/ s/#transport_email_from_email = graylog@example.com/transport_email_from_email = $account_mail/" "${graylog_config_file}"
}

nginxConfiguration(){
#create a .conf file to setup configurations

directory="/etc/letsencrypt/$domain"
sudo touch /etc/nginx/sites-available/app.conf

sudo tee -a /etc/nginx/sites-available/app.conf > /dev/null <<EOT
server {
  listen 	*:${Public_Port} ssl http2;
  server_name   ${domain}:${Public_Port}  ${Public_IP}:${Public_Port} ;

  # SSL settings here
  ssl_certificate       ${directory}/fullchain.pem;
  ssl_certificate_key   ${directory}/private.key;
  ssl_protocols         TLSv1.2;
  ssl_prefer_server_ciphers on;

  access_log /var/log/nginx/graylog.access.log;
  error_log /var/log/nginx/graylog.error.log;

  location / {
    proxy_pass http://127.0.0.1:${default_graylog_port};
    proxy_read_timeout 90;
    proxy_connect_timeout 90;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Server $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Graylog-Server-URL https://$server_name/;
  }

}
EOT
#link conf file to sites enabled directory
sudo ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/

#search for Virtual Host Configs

sed -i "/^        #include /etc/nginx/conf.d/*.conf;/ s/        #include /etc/nginx/conf.d/*.conf;/        include /etc/nginx/sites-enabled/*.conf;/" "$nginx_conf_file"
sudo nginx -t
sudo systemctl reload nginx.service

}
remove_nginX(){
  sudo systemctl stop nginx.service 2>/dev/null
  sudo apt purge nginx bash-completion -y
  sudo rm -rf /etc/nginx
  sudo rm -rf /root/.acme.sh
  sudo rm -rf /etc/letsencrypt
  sudo ufw disable
}


fullInstallation(){
animate_banner
installNginX
configureGraylogEmails
nginxConfiguration
}

main $@
