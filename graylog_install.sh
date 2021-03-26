#!/bin/bash -e
######################################################################################################
### Author: Sidney Omondi
### Version: v2.1.0
### Date: 2021-03-08
### Description:- It automates the installation and Uninstall process of graylog version 3.1 and 3.3
###               use debian version 9 for graylog 3.1 and version 10 for graylog 3.3
###             - It has been implemented using function library for easier read of code
###
### Usage: ./graylog_install.sh -i <Debian_Version>
######################################################################################################
source $(dirname $0)/lib/function-library.sh
graylog_port="9000"
graylog_ip="127.0.0.1"
config_file_path="/etc/graylog/server/server.conf"
working_directory=$( dirname "$0" )

function main(){
initialize_colors
if [[ $EUID -eq 0 ]]
then
 check $@
else
echo -e "${R}[!] You need to run script with ROOT privilages${RESET}"
fi
}

function check(){
 local OPTIND opt i
 while getopts ":u:r:i:hCR" opt; do #colon after i indicates an argument
   case $opt in

     i)
        deb_version="$OPTARG"
         if [ -z "${deb_version}" ]
      	  then
      	   echo "${R}[!] No Debian Version selected${RESET}"
      	   usage
      	  else
             animate_banner
            echo -e "${G}[+] *_____________________________Starting your installation___________________________________*${RESET}"
            checkTerminalArg $deb_version  startInstall usage


      	 fi
     ;;
     u)
     #boolean_to_check for unistall
     deb_version="$OPTARG"
     #check if Argument passed is a number
     checkTerminalArg $deb_version unInstall usage

     ;;
     r)
     deb_version="$OPTARG"
     checkTerminalArg $deb_version unInstall usage && startInstall

     ;;
     h) usage; exit 0
     ;;
     C) PerformCleanUp $working_directory; exit 0
     ;;
     R) resetPassword; exit 0
     ;;
     ?) usage; exit 1
     ;;
     :) usage; exit 1
     ;;
     esac
  done
  shift $(( OPTIND -1 ))
  #check if user has passed necessary arguments

}
if [[ -n "$deb_version" ]];then
determine_graylog_version $deb_version
fi


function usage(){

echo -e "
Usage: ${O}./$(basename $0) [-i <PARAMETER> ] | [ -r <PARAMETER> ] | [ -u <PARAMETER> ] ${RESET}
PARAMETRES:
===========
    PARAMETER    _DEBIAN_VERSION_: [ 9 | 10 ]

OPTIONS:
========

    -i    New Installation of GRAYLOG
    -r    Perform fresh Installation incase of a PreExisting INSTALLATION
    -u    To uninstall the program from your system
    -h    help
    -C    Perform Cleanup and remove all Graylog installation files from host machine
    -R    Incase of resetting Graylog Password

EXAMPLE:
=========

${O}[+] Installation :${RESET}
${G}sudo ./$(basename $0) -i [ 10 | 9 ]${RESET}

${O}[+] Uninstall :${RESET}
${G}sudo ./$(basename $0) -u [ 10 | 9 ]${RESET}

${O}[+] Re-Installation: ${RESET}
${G}sudo ./$(basename $0)  -r [ 10 | 9 ]${RESET}

${O}CleanUp or Resetting Password${RESET}
${G}sudo ./$(basename $0) - [ C | R ]${RESET}
"
}

 function prerequisite(){
 sudo apt update   ## && sudo apt upgrade -y
 #sudo apt upgrade -y
 sudo apt install apt-transport-https  uuid-runtime pwgen dirmngr gnupg wget ufw bash-completion -y
 sudo apt autoremove -y

	if [[ "$deb_version" -eq 9 ]]
	then
	 sudo apt install openjdk-8-jre-headless
	 sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
	 echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
	else
	 sudo apt install openjdk-11-jre-headless
	 wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
	 echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
	fi
 }

 ##### MONGO #######
 ##################

function installMongo(){
 sudo apt-get update
 sudo apt-get install -y mongodb-org

#Enable MongoDB

 sudo systemctl daemon-reload
 sudo systemctl enable mongod.service
 sudo systemctl restart mongod.service

 local response="$?"
 check_for_errors $response mongod "Mongo DB" unInstall

 }

  ##### ELASTICSEARCH #######
 ##################
function installElasticSearch(){

  version=6
 if [[ "$deb_version" -eq 10  ]]
 then
  version=7
 fi
 wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
 echo "deb https://artifacts.elastic.co/packages/oss-${version}.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-${version}.x.list
 sudo apt update
 sudo apt install elasticsearch-oss
 echo -e "${W}______________________________________________________________________________________________________${RESET}"

## modify elastic search config file

sudo tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null <<EOT
cluster.name: graylog
action.auto_create_index: false
EOT

## start elasticsearch
 sudo systemctl daemon-reload
 sudo systemctl enable elasticsearch.service
 sudo systemctl restart elasticsearch.service

 local response="$?"
  check_for_errors $response elasticsearch "ElasticSearch" unInstall

 }

  ##### GRAYLOG #######
 ##################
 function installGraylog(){
 REPO=$(determine_graylog_version $deb_version)


  wget https://packages.graylog2.org/repo/packages/graylog-${REPO}-repository_latest.deb ;
  sudo apt install ./graylog-${REPO}-repository_latest.deb || sudo dpkg -i graylog-${REPO}-repository_latest.deb
  echo
  echo
  sudo apt update
  sudo apt install graylog-server graylog-enterprise-plugins graylog-integrations-plugins graylog-enterprise-integrations-plugins
  graylogConfig
  verifyGraylog
 }

 ## EDIT CONF FILE #######
 ########################

#Update GrayLog Configs
 setGraylogConfig(){

  #generates 64 character password
 local PASSWORD=$( pwgen -N 1 -s 96 )


 echo
#Ensure username and Password are provided
 while true; do
   read -p "[-] Enter Username for graylog WebGUI login?: " USERNAME

   stty -echo #turns off echo on screen so that password is hidden
   read -p "[-] What will be ${USERNAME}'s password?  ==> " PASS
   echo
   stty echo
   if [[ -z "$USERNAME" && -z "$PASS" ]]
   then
     echo
     echo
     echo -e "${BRed}USERNAME${RESET} or ${BRed}Password${RESET} cant be blank "
     echo
   elif [[ -z "$USERNAME" ]]
   then
     echo
     echo
     echo -e "${BRed}USERNAME${RESET}  cant be blank "
     echo
   elif [[ -z "$PASS" ]]
   then
     echo
     echo
     echo -e " ${BRed}Password${RESET} cant be blank "
     echo
   else
     break

   fi
 done

# Convert password provided into hash password

hash_pass=$(echo -n ${PASS} | sha256sum  | awk -F' ' '{print $1}') || $(echo -n ${PASS} | shasum -a 256 | awk -F' ' '{print $1}')


 read -p "[-] Enter your ${read_green_color}Machines Ip Address${read_normal_color} [Default: 127.0.0.1] " PRIVATE_IP
 read -p "[-] Enter your preferred ${read_green_color}PORT${read_normal_color} to run Graylog [Default: 9000 ] " DEF_PORT

  if [[ -n "$DEF_PORT" ]]
  then
    graylog_port=$DEF_PORT
  fi

 sleep 0.2
 echo
 echo -e " Your username is ${Y}$USERNAME${RESET} and hash is ==> ${Y}${hash_pass}${RESET}"
 echo -e "Your Ip and Port is ${Y}${graylog_ip}:${graylog_port}${RESET}"
##EDITING THE CONFIGURATION FILE
sed -i "/^password_secret =/ s/password_secret =/password_secret =$PASSWORD/ ; /^#root_username =/ s/#root_username = admin/root_username =$USERNAME/ ; /^root_password_sha2 =/ s/root_password_sha2 =/root_password_sha2 =$hash_pass/ ; /^#http_bind_address = 127.0.0.1:9000/ s/#http_bind_address = 127.0.0.1:9000/http_bind_address = ${graylog_ip}:${graylog_port}/" "$config_file_path"

 }
 ## Reset Admin Password
 resetPassword(){
   local PASSWORD=$( pwgen -N 1 -s 96 )

   #path to graylog config file
   echo
  #Ensure username and Password are provided
   while true; do


     stty -echo #turns off echo on screen so that password is hidden
     read -p "[-] Enter your New password?  ==> " NEW_PASS
     echo
     echo
     read -p "[-] Confirm your New password?  ==> " CONFIRM_PASS
     stty echo
     if [[ -z "$NEW_PASS" && -z "$CONFIRM_PASS" ]]
     then
       echo
       echo -e "${BRed}Password${RESET} cant be blank "
       echo
     elif [[  "$NEW_PASS" !=  "$CONFIRM_PASS" ]]
     then
       echo
       echo -e "Passwords Dont Match "
       echo
     else
       break

     fi
   done

  # Convert password provided into hash password

  hash_pass=$(echo -n ${NEW_PASS} | sha256sum  | awk -F' ' '{print $1}') || $(echo -n ${NEW_PASS} | shasum -a 256 | awk -F' ' '{print $1}')


   sleep 0.2
   echo
  ##EDITING THE CONFIGURATION FILE
sed -i "/^password_secret =/ s/password_secret =.*/password_secret =$PASSWORD/ ;  /^root_password_sha2 =/ s/root_password_sha2 =.*/root_password_sha2 =$hash_pass/" "$config_file_path"
sudo systemctl restart graylog-server.service
 }
 function verifyGraylog(){
 ### verify its running
	 sudo systemctl daemon-reload
	 sudo systemctl enable graylog-server.service
	 sudo systemctl start graylog-server.service
	  local response="$?"

    check_for_errors $response graylog "Graylog Server" unInstall

	 rm graylog-${REPO}-repository_latest.deb
 }
unInstall(){
#services
	echo -e "${R}Stopping Graylog related Services...${RESET}"
	echo
  function stopServices() {
    #statements
    sudo service mongod stop
    sudo systemctl stop elasticsearch.service
    sudo service graylog-server stop
  }
  #Redirect errors to stderr
  #--quiet tag

  stopServices 2>/dev/null
	#uninstall mongodb
	removeMongo 2>/dev/null

	#uninstall graylog
	removeGraylog 2>/dev/null
	#uninstall elasticsearch
	removeElastic 2>/dev/null
  sleep 1
	sudo apt purge apt-transport-https  uuid-runtime pwgen dirmngr gnupg -y

}
##
removeMongo(){
echo -e "${Y}______________________REMOVING MONGO DB___________________ ${RESET}"
sudo rm /etc/apt/sources.list.d/mongodb-org-4.2.list || sudo rm /etc/apt/sources.list.d/mongodb-org-4.0.list
local remove_status="$?"

if [[ "$remove_status" -eq 0 ]]
then
	sudo apt purge mongodb-org* -y
	sudo rm -r /var/log/mongodb
	sudo rm -r /var/lib/mongodb
fi

}
removeElastic(){
echo -e "${Y}______________________REMOVING ELASTIC SEARCH___________________________ ${RESET}"
sudo rm /etc/apt/sources.list.d/elastic-6.x.list || sudo rm /etc/apt/sources.list.d/elastic-7.x.list
local remove_status="$?"

if [[ "$remove_status" -eq 0 ]]
then

	 sudo apt remove elasticsearch-oss --auto-remove elasticsearch-oss -y
	 sudo apt-get --purge autoremove elasticsearch* -y
	 sudo rm -rf /usr/share/elasticsearch
	 sudo rm -rf /var/lib/elasticsearch
	 sudo rm -rf /var/log/elasticsearch
	 sudo rm -rf /etc/elasticsearch
	 sudo rm  /etc/init.d/elasticsearch
fi
}

removeGraylog(){
echo -e "${Y}____________________________REMOVING GRAYLOG SERVER_____________________________ ${RESET}"
 sudo rm /etc/apt/sources.list.d/graylog.list
 local remove_status="$?"

 if [[ "$remove_status" -eq 0 ]]
  then
	 sudo apt purge graylog-* -y
	 sudo apt purge graylog-server graylog-enterprise-plugins graylog-integrations-plugins graylog-enterprise-integrations-plugins -y
	 sudo rm -rf /etc/graylog
	 sudo rm -rf /usr/share/graylog-server
	 sudo rm -rf /var/log/graylog-server
	 sudo rm -rf /var/lib/graylog-server
	 find *.deb
	 dir_search="$?"
	 if [[ "$dir_search" -eq 0 ]]
	 then
	 	rm *.deb
	 fi
	 sudo dpkg -P graylog-${REPO}-repository #purge the repo from system to avoid conflicts
  fi
}

function startInstall(){
 prerequisite
 installMongo
 installElasticSearch
 installGraylog
}

main $@
