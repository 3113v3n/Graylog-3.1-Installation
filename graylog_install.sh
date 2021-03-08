#!/bin/bash
######################################################################################################
### Author: Sidney Omondi
### Version: v1.1.0
### Date: 2021-1-2
### Description: It automates the installation and Uninstall process of graylog version 3.1 and 3.3
### use debian version 9 for graylog 3.1 and version 10 for graylog 3.3
###
### Usage: ./graylog_install.sh -i <Debian_Version>
######################################################################################################

graylog_port="9000"
graylog_ip="127.0.0.1"
config_file_path="/etc/graylog/server/server.conf"


function main(){

if [[ $EUID -eq 0 ]]
then
 u=false
 update=false
 animate_banner
 check $@
else
echo -e "${R}[!] You need to run script with ROOT privilages${RESET}"
fi
}

function check(){
 local OPTIND opt i
 while getopts ":u:r:i:" opt; do #colon after i indicates an argument
   case $opt in

     i)
      echo "[-] You chose to do a fresh installation "; deb_version="$OPTARG"
       if [ -z "${deb_version}" ]
	  then
	   echo "${R}[!] No Debian Version selected${RESET}"
	   usage
	  else
      echo -e "${G}[+] *_____________________________Starting your installation___________________________________*${RESET}"
        checkTerminalArg $deb_version  startInstall

	  fi
     ;;
     u)
     u=true
     deb_version="$OPTARG"
     #check if Argument passed is a number
     checkTerminalArg $deb_version unInstall
     ;;
     r)
     reinstall=true
     echo "[-] You chose to reinstall Graylog "; deb_version="$OPTARG"
     checkTerminalArg $deb_version unInstall && startInstall
     ;;
       # commented out to allow configuration of ssl_certificate
        #c)
      # update=true
      # echo -e "${G}[+] Updating Graylog Config File${RESET}";
      # changePublic_Ip;;
     *) usage; exit 1
     ;;
     esac
  done
  shift $(( OPTIND -1 ))
  #check if user has passed necessary arguments
testArguments
}
testArguments(){
  if [[ -z "${deb_version}" &&  "$u" == false && "$update" == false ]]
   then
    usage
  #elif [[ "$graylog_ip" == "127.0.0.1" && "$graylog_port" == "9000" && "$u" == false && "$update" == false ]]
  #then
  #instructions
 fi
}

checkTerminalArg(){
  if [[ ! "$1" =~ ^[[:digit:]]+$ ]]; then #checks if value starts and ends with a digit and also works for double digits
    #statements
    echo -e "                   ${R}[!] VALUE of ${1},PASSED IS NOT A NUMBER${RESET}"
    usage
    exit 1
  else
    if [[ "$1" -lt 9 || "$1" -gt 10 ]]
    then
    echo -e "                 ${R} [!] INVALID DEBIAN VERSION of ${1}, SUPPLIED ${RESET}"
    usage
    exit 1
   fi
   $2
  fi
}
  #REPO=4.0
 if [[ "$deb_version" -eq 9 ]]
 then
  REPO=3.1
 else
  REPO=3.3
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
    -c    Configure public IP and Port of  Existing Installation

EXAMPLE:
=========

${O}[+] Installation :${RESET}${G}sudo ./$(basename $0) -i [ 10 | 9 ]${RESET}

${O}[+] Uninstall :${RESET}${G}sudo ./$(basename $0) -u [ 10 | 9 ]${RESET}

${O}[+] Re-Installation: ${RESET}${G}sudo ./$(basename $0)  -r [ 10 | 9 ]${RESET}


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
 if [[ $response -eq 0 ]]
 then
     echo
     sudo systemctl --type=service --state=active | grep mongod
     echo
     echo -e "${G}MongDB installed and Started successfully${RESET}"
 else
     echo -e "${R}An error occured while installing Mongo DB

     Script is EXITING NOW !!!
     ${RESET}"
     #uninstall installed packages
     unInstall
     exit 1

 fi



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
 if [[ $response -eq 0 ]]
 then
    echo
    sudo systemctl --type=service --state=active | grep elasticsearch
    echo
    echo -e "${G}[+] ElasticSearch installed and Started successfully${RESET}"
 else
 echo -e "${R}[!] An error occured while installing elasticsearch

 Script is EXITING NOW !!!
 ${RESET}"
 #uninstall installed packages
 unInstall
 exit 1
 fi

 }

  ##### GRAYLOG #######
 ##################
 function installGraylog(){



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

function graylogConfig(){
  #generates 64 character password
 PASSWORD=$( pwgen -N 1 -s 96 )

 #path to graylog config file

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


 #read -p "[-] Enter your ${read_green_color}Public Ip Address${read_normal_color} [Default: 127.0.0.1] " PUB_IP
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
 function verifyGraylog(){
 ### verify its running
	 sudo systemctl daemon-reload
	 sudo systemctl enable graylog-server.service
	 sudo systemctl start graylog-server.service
	  local response="$?"
 	 if [[ $response -eq 0 ]]
	   then
	   echo
           sudo systemctl --type=service --state=active | grep graylog
           sleep 0.4
           echo -e "${G}Graylog-server installed and Started successfully${RESET}"
           echo -e "You can access the page from the link below"
	   echo -e "${blue_color}http://${graylog_ip}:${graylog_port}/${RESET}"
 	else
          echo -e "${R}An error occured while installing Graylog Server

          Script is EXITING NOW !!!
          ${RESET}"
          #uninstall installed packages
          unInstall
          exit 1
 	fi
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
function instructions(){
#Instruct user what to update in case address and port not provided

#cat << EOF

echo -e "
                      ${R}_______________________________________${RESET}${BYellow}NOTE${RESET}${R}__________________________________________________ ${RESET}
                     ${R}|${RESET}                                                                                            ${R}|${RESET}
                     ${R}|${RESET}                ${blue_color}INCASE YOU NEED TO CHANGE PUBLIC IP AND PORT${normal_color}                                ${R}|${RESET}
                     ${R}|${RESET}                                                                                            ${R}|${RESET}
                     ${R}|${RESET}                 RUN:                                                                       ${R}|${RESET}
                     ${R}|${RESET}                                                                                            ${R}|${RESET}
                     ${R}|${RESET}                     ${O}[+] ./$(basename $0) -c${RESET}                                         ${R}|${RESET}
                     ${R}|${RESET}                                                                                            ${R}|${RESET}
                     ${R}|${RESET}                     to reconfigure your IP and P                                           ${R}|${RESET}
                     ${R}|${RESET}                                                                                            ${R}|${RESET}
                     ${R}|____________________________________________________________________________________________|${RESET}
                     "
#EOF

}
# function not called , script implemented on graylog_nginx_install.sh
function changePublic_Ip(){
# change the public IP
local config_file_path="/etc/graylog/server/server.conf"
while true; do
   read -p "Did you provide an IP Address during initial Installation? [ Y / N ] " choice
    case $choice in
        [Nn]* )
        read -p "Enter your Public IP address:  " IP_ADDRESS
      	read -p "Enter your preferred  Port : " PORT
	sleep 0.4
	echo -e "Your new address and port are : ===>${Y}$IP_ADDRESS:$PORT${RESET}"
sed -i "/^http_bind_address = 127.0.0.1:9000/ s/http_bind_address = 127.0.0.1:9000/http_bind_address = ${IP_ADDRESS}:${PORT}/ ; /^http_publish_uri = http:\/\/127.0.0.1:9000\// s/http_publish_uri = http:\/\/127.0.0.1:9000\/http_publish_uri = http:\/\/${IP_ADDRESS}:${POR}T\// " "$config_file_path"
echo
updateConfirmation
break
;;
        [Yy]* )
        read -p "Enter your previous Public IP: " ORIGINAL_IP
	      read -p "Enter your previous Port: " ORIGINAL_PORT
  sleep 0.4
	echo -e "Your initial address and port are : ===>${Y}$ORIGINAL_IP:$ORIGINAL_PORT${RESET}"
	echo
	read -p "Enter your NEW Public IP address:  " NEW_IP_ADDRESS
	read -p "Enter your preferred connection port : " NEW_PORT
  sleep 0.4
	echo -e "Your new address and port are : ===> ${Y}$ORIGINAL_IP:$ORIGINAL_PORT${RESET}"

sed -i "/^http_bind_address = ${ORIGINAL_IP}:${ORIGINAL_PORT}/ s/http_bind_address = ${ORIGINAL_IP}:${ORIGINAL_PORT}/http_bind_address = ${NEW_IP_ADDRESS}:${NEW_PORT}/ ; /^http_publish_uri = http:\/\/${ORIGINAL_IP}:${ORIGINAL_PORT}\// s/http_publish_uri = http:\/\/${ORIGINAL_IP}:${ORIGINAL_PORT}\//http_publish_uri = http:\/\/${NEW_IP_ADDRESS}:${NEW_PORT}\// " "$config_file_path"
echo
updateConfirmation
break
;;
        * ) echo -e "Please answer ${BGreen}YES${normal_color} or ${BGreen}NO${normal_color}.";;
    esac
done


}
updateConfirmation(){
sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
sudo systemctl start graylog-server.service
sudo systemctl --type=service --state=active | grep graylog
sleep 0.4
echo -e "${green_color}Graylog Configurations Successfully Updates${RESET}"
echo
}


function initialize_colors() {
	normal_color="\e[1;0m"
	green_color="\033[1;32m"
	blue_color="\033[1;34m"
	cyan_color="\033[1;36m"
	brown_color="\033[0;33m"
	yellow_color="\033[1;33m"
	pink_color="\033[1;35m"
	white_color="\e[1;97m"
	clear_screen="\033c"
  ### Regular Colors

  G='\033[0;32m' #Green Color Title
  R='\033[1;31m' #Red Color
  W='\033[0;37m' # White Color
  B='\033[0;34m' # Blue Color
  C='\033[0;36m' # Cyan Color
  M='\033[0;35m' # Purple
  LG='\033[0;37m'
  O='\033[0;33m'
  Y='\033[1;33m'  # Yellow
  RESET='\033[0m'

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# colors to use with read cmd
read_normal_color=$'\e[1;0m'
read_green_color=$'\033[1;32m'
read_blue_color=$'\033[1;34m'
read_cyan_color=$'\033[1;36m'
read_brown_color=$'\033[0;33m'

}

function hearts_pirates(){
	case $1 in
		1)banner_color=${R}

		 ;;
		2) banner_color=${G}

		;;
		3) banner_color=${BBlue}

		;;
		4) banner_color=${brown_color}

		;;
		5) banner_color=${W}

		;;

	esac
	banner

sleep 0.4
}
banner(){
	echo -e ${banner_color}"                                 ;okO0KKKKKK0Oko;   "${RESET}
	echo -e ${banner_color}"                                .oolc;,dMMd,;cloo.  "${RESET}
	echo -e ${banner_color}"                         .lx.      .:lxXMMXxl:.      .oc.   "${RESET}
	echo -e ${banner_color}"                        oWWo   .l0WMWK0OkkO0KWMW0l.   dWWo   "${RESET}
	echo -e ${banner_color}"                      ,XMk. .oXMXd:.          .,oKMXo. .xMK.  "${RESET}
	echo -e ${banner_color}"                     lWMX''dWWk,...            ...'kWWk:;XMW:  "${RESET}
	echo -e ${banner_color}"                    dMWONMMMK,lKMMMW0:      ,0WMMMKo;KMMMNOWMc  "${RESET}
	echo -e ${banner_color}"                   :MW, :MM0.KMMMMMMMMO    oMMMMMMMMN,0MM: :MW'  "${RESET}
	echo -e ${banner_color}"                   XMl  OMX.;MMMMMMMMMW.   WMMMMMMMMM: KMK  xMx   "${RESET}
	echo -e ${banner_color}"                   ll  .MMl  OMMMMMMMWc    lWMMMMMMMO  ;MM'  l;  "${RESET}
	echo -e ${banner_color}"                      :MM,   ,kXNNKd.  ,,  .dKNNXk,    XM:    "${RESET}
	echo -e ${banner_color}"                       :MMc            .00.             KM:   "${RESET}
	echo -e ${banner_color}"                   dk. .MMMWXK000OOOOOOOO00000KKKKXXXNWMMM' .Oo   "${RESET}
	echo -e ${banner_color}"                  OMO  OMN'.xMk,,lM0,,;NN;,,0M0,,kMx..XM0  KMd    "${RESET}
	echo -e ${banner_color}"                   .WMo oMM0.lMl  .Mx   XX   kMx  lMl OMMl xMX. "${RESET}
	echo -e ${banner_color}"                    ,WMWMMMMKOMl  .Mx   XX   OMk  lMOKMMMMWMN.  "${RESET}
	echo -e ${banner_color}"                     .XMN'.lNMMO  'Mk   XX   0MO  kMMNl.'WMK.  "${RESET}
	echo -e ${banner_color}"                       dMX:  lKMNxOM0   XX   KMXdXMKc  cNWd   "${RESET}
	echo -e ${banner_color}"                        '0M0.  .ckNMMK00WW0KKWMNOc.  .0M0'    "${RESET}
	echo -e ${banner_color}"                          .,       .,coKMMKoc,.       ,.    "${RESET}
	echo -e ${banner_color}"                                .OOkdocxMMxcodxkx.    "${RESET}
	echo -e ${banner_color}"                                 .;ldkO000OOkdl;.  "${RESET}
}
animate_banner(){

	#echo -e "\033[6B"

	for i in $(seq 1 3); do
		echo -e ${clear_screen}

		if [ "$i" -le 3 ]; then
			color_index=${i}
		else
			color_index=$(( i-4 ))
		fi
		hearts_pirates "$color_index"
	done

}


function startInstall(){
 prerequisite
 installMongo
 installElasticSearch
 installGraylog
}
initialize_colors
main $@
