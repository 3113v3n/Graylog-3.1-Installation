#!/bin/bash
#####################################################
# Author: Sidney Omondi
# Version: v1.0.0
# Date: 2020-01-28
# Description: bash function library
# Usage: source $(dirname $0)/lib/function-library.sh
#########################################################


#Test for the arguments supplied to the terminal
testArguments(){
  deb_version="$4"
  check_bool="$1"
  update_bool="$2"
  local script_usage="$3"
echo $@
  if [[ $# -lt 4 && $check_bool = false && $update_bool = false ]]; then
    #statements
    $script_usage
  fi

}


#Test that values supplied to tags on terminal [ -u -r -i ] are digits
checkTerminalArg(){
  local deb_version=$1
  local _function=$2
  local script_usage=$3
  if [[ ! "$1" =~ ^[[:digit:]]+$ ]]; then
  #checks if value starts and ends with a digit and also works for double digits
    #statements
    echo -e "                   ${R}[!] VALUE of ${1},PASSED IS NOT A NUMBER${RESET}"
    $script_usage #Output usage of script
    exit 1
  else
    if [[ "$1" -lt 9 || "$1" -gt 10 ]]
    then
    echo -e "                 ${R} [!] INVALID DEBIAN VERSION of ${1}, SUPPLIED ${RESET}"
    $script_usage
    exit 1
   fi
   $_function
  fi
}


#determine which graylog version to install
determine_graylog_version(){
  if [[ $# -lt 1 ]];then
    exit 1
  fi

  if [[ "$1" -eq 9 ]]
  then
   echo 3.1
  else
   echo 3.3
  fi
}
#Successfull update of configs
updateConfirmation(){
sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
sudo systemctl start graylog-server.service
sudo systemctl --type=service --state=active | grep graylog
sleep 0.4
echo -e "${green_color}Graylog Configurations Successfully Updates${RESET}"
echo
}


#check for Installation Errors
check_for_errors(){
  if [[ "$#" -ne 3 ]]
  then
    echo "Invalid Number of arguments"
    exit 1
  fi

  local response="$1"
  grep_string="$2" #mongod
  service_string=$3 #MongoDB
  unInstall=$4
  if [[ "$response" -eq 0 ]]
  then
      echo
      sudo systemctl --type=service --state=active | grep $grep_string
      echo
      echo -e "${G}${service_string} installed and Started successfully${RESET}"
      if [[ $grep_string == "graylog" ]]
      then
        echo -e "You can access the page from the link below"
        echo -e "${blue_color}http://${graylog_ip}:${graylog_port}/${RESET}"
      fi
  else
      echo -e "${R}An error occured while installing ${service_string}

      Script is EXITING NOW !!!
      ${RESET}"
      #uninstall installed packages
      $unInstall
      exit 1

  fi
}

#Terminal Colors
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

#Pass colors to our terminal banner
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


#Provide Animation for the banner
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


#Perform Changes on Graylog Config Files to update Public IP and Port
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
check_yes_no(){
  # Input validation.
if [[ $# -ne 1 ]]; then
echo "Need exactly one argument, exiting."
exit 1 # No validation done, exit script.
fi
  local question=$1
  while true; do
  read -p "$question " answer #Pass the Question To ask the user
  case ${answer,,} in
    n | no )
    return 1
    break
    ;;
    y | yes )
    return 0
    break
    ;;
    *) echo "Please Answer Yes or No"
      echo
    ;;
  esac
done
}



#Update GrayLog Configs
 setGraylogConfig(){
   local graylog_port="$1"
   local graylog_ip="$2"
   local config_file_path="$3"
  #generates 64 character password
 PASSWORD=$( pwgen -N 1 -s 96 )


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

 ###################################################
 ################# NGINX ############################
 ##################################################
 test_nginx_Arguments(){
   local domain=$1
   local account_mail=$2
   local installation_function=$3
   local usage=$4
   
   if [[ -z "$domain" && -z "$account_mail"  ]] # ||  ||
   then
   echo -e "${R} [!] Error: Missing arguments: < Domain > < Email >${RESET}"
   echo
   $usage; exit 1
  elif [[ -z "$domain" ]]
  then
    echo -e "${R} [!] Error: Missing arguments: < Domain >${RESET}"
    echo
    $usage; exit 1
  elif [[ -z "$account_mail" ]]
  then
    echo -e "${R} [!] Error: Missing arguments: < Email >${RESET}"
    echo
    $usage; exit 1
   else
    #do fullInstallation
    $installation_function
   fi
 }
