#!/bin/bash
##**********************************************************************************
## Project       : RMA_NVIDIA
## Filename      : SJ_autotest.sh
## Description   : NVIDIA test automatic
## Usage         : n/a
##
##
## Version History
##-------------------------------
## Version       : 1.0.1
## Release date  : 2025-07-07
## Revised by    : Winter Liu
## Description   : Initial release
##-------------------------------
## Version       : 1.0.2
## Release date  : 2025-08-05
## Revised by    : Winter Liu
## Description   : For rebuild add scan pruduct serial number fuction
##**********************************************************************************
[ -d "/home/com/logs/" ] || mkdir /home/com/logs
[ -d "/home/com/server_diag/" ] || mkdir /home/com/server_diag
[ -d "/home/com/server_logs/" ] || mkdir /home/com/server_logs


export Diag_Path="/home/com/server_diag"
export Logs_Path="/home/com/server_logs"
export Local_Logs="/home/com/logs"
export NC_logserver_IP="192.168.102.20"
export NC_diagserver_IP="192.168.102.21"
export NC_API_IP="192.168.102.20"
export OPID="$Diag_Path/OPID/OPID.ini"  ###add check operator ID 4/4/2024####
export INI_folder="$Diag_Path/INI/"
export Script_File="SJ_autotest.sh"
export site="NC"
export logserver_IP=""
export diagserver_IP=""
export API_IP=""
export ID=""
export SECRET=""
export NID="client_id=vE7BhzDJhqO"
export NSECRET="client_secret=0f40daa800fd87e20e0c6a8230c6e28593f1904c7edfaa18cbbca2f5bc9272b5"
export TYPE="grant_type=client_credentials"
export NC_pw_diag="TJ77921~"
export NC_pw_log="TJ77921~"
export pw_diag=""
export pw_log=""
export BMC_SSH_USERNAME="root"
export BMC_SSH_PASSWORD="0penBmc"
export SCANFILE="uutself.cfg.env"
export PDU_control_file="ac_control.py"
declare -u station



Script_VER="1.0.2"  
CFG_VERSION="1.0.2"
PROJECT="SJ"
Input_Upper_SN=""
Input_Upper_PN=""
current_stc_name=""
diag_name=""
MACHINE=""
diag_VER=""
Input_Upper_Station=""
Final_status=""
LogName=""
FactoryErrorCode=""
FactoryErrorMsg=""
mods=""
CFGFILE=""
LOGFILE=""
Input_Upper_BPN=""
Input_Upper_BPR=""
Input_Upper_BSN=""
Run_Mode=0

#BMC_IP=192.168.10.10
Path_Initial_Parameter_Setting="$INI_folder/Initial_Parameter_Setting.csv"
nvme_fw="GDC7402Q"
device_fw="28.36.2020"
check_status=0
RACK=$(uname -n | awk -F "-" '{print $1}')
#work_path=$(pwd)



#####################################################################
#                                                                   #
# Pause                                                             #
#                                                                   #
#####################################################################

pause( )
{
echo "press any key to continue......"
local DUMMY
read -n 1 DUMMY
echo
}

#####################################################################
#                                                                   #
# Get Config From .ini                                              #
#                                                                   #
#####################################################################
get_config()
{
    echo $(cat ${CFGFILE} | grep "^${1}" | awk -F '=' '{print$2}')
    if [ 0 -ne $? ]; then
        echo "${1} config not found.(${CFGFILE})" | tee -a $LOGFILE/log.txt
        show_fail_message "Config Not Found" && exit 1
    fi
}

######################################################################
#                                                                    #
# Show Pass message (color: green)                                   #
#                                                                    #
######################################################################
show_pass_msg()
{
    _TEXT=$@
    len=${#_TEXT}

    while [ $len -lt 60 ]
    do
    _TEXT=$_TEXT"-"
    len=${#_TEXT}
    done

    _TEXT=$_TEXT"[ PASS ]"

    echo -ne "\033[32m"
    echo -ne "\t"$_TEXT
    echo -e "\033[0m"
}

######################################################################
#                                                                    #
# Show Fail message (color: red)                                     #
#                                                                    #
######################################################################
show_fail_msg()
{
    _TEXT=$@
    len=${#_TEXT}

    while [ $len -lt 60 ]
    do
    _TEXT=$_TEXT"-"
    len=${#_TEXT}
    done

    _TEXT=$_TEXT"[ FAIL ]"

    echo -ne "\033[31m"
    echo -ne "\t"$_TEXT
    echo -e "\033[0m"

#    convert_err "$1"
}

######################################################################
#                                                                    #
# Show Pass message (color: green)                                   #
#                                                                    #
######################################################################
show_pass_message()
{       
    tput bold   
    TEXT=$1
    echo -ne "\033[32m$TEXT\033[0m"
    echo
}

######################################################################
#                                                                    #
# Show Fail message (color: red)                                     #
#                                                                    #
######################################################################
show_fail_message()
{ 
     tput bold
     TEXT=$1
     echo -ne "\033[31m$TEXT\033[0m"
     echo
}

######################################################################
#                                                                    #
# Show Warning message (color: yellow)                                     #
#                                                                    #
######################################################################
show_warning_message()
{ 
     tput bold
     TEXT=$1
     echo -ne "\033[33m$TEXT \033[0m"
	 echo 
}


echo_alert()
{
    message=$1
    echo " "
    echo -e "\e[31m		>> "${message}" <<\e[0m"
	echo " "
	exit 3
	check_status=1
}

echo_green()
{
    message=$1
    echo " "
    echo -e "\e[32m		>> "${message}" <<\e[0m"
	echo " "
}

echo_message()
{
	message=$1
    echo " "
    echo -e "\e[33m		"${message}"			\e[0m"
	echo " "
}

PASSED()
{
	echo -e "\e[32m                                                                                                                                                                                                                                                                                    
██████╗  ██████╗  ██████╗  ██████╗ 
██╔══██╗██╔═══██╗██╔════╝ ██╔════╝ 
██████╔╝████████║ ██████╗  ██████╗ 
██╔═══╝ ██╔═══██║      ██╗      ██╗
██║     ██║   ██║ ██████╔╝ ██████╔╝
╚═╝     ╚═╝   ╚═╝  ╚════╝   ╚════╝  \e[0m"
	echo -e "\e[32m  \e[0m"
	echo -e "\e[32m  \e[0m"
}

FAILED()
{
	echo -e "\e[31m                                                                                                                                                                                                                                                                                    
███████╗ ██████╗  ██████╗ ██╗
██╔════╝██╔═══██╗   ██╔═╝ ██║
█████╗  ████████║   ██║   ██║
██╔══╝  ██╔═══██║   ██║   ██║
██║     ██║   ██║ ██████╗ ███████╗
╚═╝     ╚═╝   ╚═╝ ╚═════╝ ╚══════╝\e[0m"
	echo -e "\e[31m  \e[0m"
	echo -e "\e[31m  \e[0m"
}

AC_POWER_CYCLE()
{
	echo "                                                                                                                                                                                                                                                                                    
 █████╗  ██████╗    ██████╗  ██████╗ ██╗    ██╗███████╗██████╗      ██████╗██╗   ██╗ ██████╗██╗     ███████╗
██╔══██╗██╔════╝    ██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔══██╗    ██╔════╝╚██╗ ██╔╝██╔════╝██║     ██╔════╝
███████║██║         ██████╔╝██║   ██║██║ █╗ ██║█████╗  ██████╔╝    ██║      ╚████╔╝ ██║     ██║     █████╗  
██╔══██║██║         ██╔═══╝ ██║   ██║██║███╗██║██╔══╝  ██╔══██╗    ██║       ╚██╔╝  ██║     ██║     ██╔══╝  
██║  ██║╚██████╗    ██║     ╚██████╔╝╚███╔███╔╝███████╗██║  ██║    ╚██████╗   ██║   ╚██████╗███████╗███████╗
╚═╝  ╚═╝ ╚═════╝    ╚═╝      ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝     ╚═════╝   ╚═╝    ╚═════╝╚══════╝╚══════╝"
}

PING_TH500()
{
    echo_message "Ping TH500 IP ${TH500_IP}"
    cnt=0
    while [ $cnt -lt 601 ];
    do
	    let cnt=$cnt+1
	    ping -q -c 1 -W 1 ${TH500_IP}
	    rc=$?
	    if [ $rc -eq 0 ];then
            break
        fi
        if [ $rc -ne 0 -a $cnt = 300 ];then
            EC_PING_TH500=1
			exit 3
        fi
        sleep 1
    done
	echo_message "Sleep 30"
	sleep 30
}

PING_BMC()
{
    echo_message "Ping BMC IP ${BMC_IP}"
    cnt=0
    while [ $cnt -lt 601 ];
    do
	    let cnt=$cnt+1
	    ping -q -c 1 -W 1 ${BMC_IP}
	    rc=$?
	    if [ $rc -eq 0 ];then
            break
        fi
        if [ $rc -ne 0 -a $cnt = 300 ];then
            EC_PING_TH500=1
			exit 3
        fi
        sleep 1
    done
	echo_message "Sleep 30"
	sleep 30
}

CHECK_NVME_FW()
{
	echo_message "nvme_fw_chechk"
	nvme0_fw_detect=$(sshpass -p 'nvidia' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nvidia@${TH500_IP} "echo 'nvidia' | sudo -S nvme list" | grep "nvme0" | awk -F" " '{printf $16}'| awk '{gsub(" ","");gsub(",","");print}')
	nvme1_fw_detect=$(sshpass -p 'nvidia' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nvidia@${TH500_IP} "echo 'nvidia' | sudo -S nvme list" | grep "nvme1" | awk -F" " '{printf $16}'| awk '{gsub(" ","");gsub(",","");print}')
	if ([ "${nvme0_fw_detect}" = "${nvme_fw}" ] && [ "${nvme1_fw_detect}" = "${nvme_fw}" ]);then
		echo_green "NVME check pass"
	else
		echo_alert "NVME check fail"
	fi
}

CHECK_MST_STATUS()
{
	echo_message "mst_status_check"
	sshpass -p 'nvidia' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nvidia@${TH500_IP} "echo 'nvidia' | sudo -S mst start"
	mst_status_detect=$(sshpass -p 'nvidia' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nvidia@${TH500_IP} "echo 'nvidia' | sudo -S mst status -v" | grep "rev:0" | wc -l)
	if [ ${mst_status_detect} -ne 12 ];then
		echo_alert "device not find"
	fi
	
	echo_green "device cnt check pass"
	cnt=0
	for (( i=0;i<=11;i++ ));
	do
		device_fw_detect=$(sshpass -p 'nvidia' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nvidia@${TH500_IP} "echo 'nvidia' | sudo -S flint -d /dev/mst/mt4129_pciconf${i} q " | grep "FW Version")
		device_fw_detect=$(echo ${device_fw_detect} | awk -F":" '{printf $2}' | awk '{gsub(" ","");gsub(",","");print}') 
		echo "mt4129_pciconf${i}:${device_fw_detect}"
		sleep 1
		if [ "${device_fw_detect}" = "${device_fw}" ];then
			echo_green "device${i} fw check pass"
			cnt=$(($cnt+1))
		else
			echo_alert "device${i} fw check fail"
			#${work_path}/sshpass -p 'nvidia' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nvidia@${TH500_IP} "echo 'nvidia' | sudo -S mcra /dev/mst/mt4129_pciconf${i} 0x3ffffffc 0x80000000"
			#${work_path}/sshpass -p 'nvidia' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nvidia@${TH500_IP} "echo 'nvidia' | sudo -S flint -ocr -d  /dev/mst/mt4129_pciconf${i} -y -i fw-ConnectX7-rel-28_36_2020-MCX750500B-0D00_DK_Ax_SJ_SD_Enforce-UEFI-14.29.14-FlexBoot-3.6.901.bin b"
		fi
	done
}

CHECK_PCIE_SPEED()
{
	[ -f ${work_path}/test.txt ]&& rm -f ${work_path}/test.txt
	cnt=0
	sshpass -p 'nvidia' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nvidia@${TH500_IP} "echo 'nvidia' | sudo -S lspci" | grep Infiniband | awk '{print $1}' > ${work_path}/test.txt	
	while read line ;
	do
		array[$cnt]=$line
		((cnt++))
	done < ${work_path}/test.txt
	
	for ((i=0;i<${#array[@]};i++));
	do
		temp=$(sshpass -p 'nvidia' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nvidia@${TH500_IP} "echo 'nvidia' | sudo -S lspci -vvs ${array[$i]}" | grep LnkSta: | awk -F"," '{printf $1}')
		if [[ ${temp} == *"32GT"* ]];then
			echo_green ${temp}
		else
			echo_alert ${temp}
		fi
	done
	
}

####get information from wareconn####################################
Input_Wareconn_Serial_Number_RestAPI_Mode()

{
###API

now_stn=""
Input_RestAPI_Message=""
##get_token#############################

echo "get token from wareconn API"
Input_RestAPI_Message=$(curl -k "https://$API_IP:4443/api/v1/Oauth/token?${ID}&${SECRET}&${TYPE}")
if [ -n "$Input_RestAPI_Message" ] && echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
	token=$(echo "$Input_RestAPI_Message" | awk -F '"' '{print $10 }')
	show_pass_message "get_token successful:$token"	
else
	show_fail_message "$Input_RestAPI_Message"
	show_fail_message "get token Fail Please check net cable or call TE"
	exit 1
fi


##get_information from wareconn#########
echo "get test information from wareconn API "
	if [ $Run_Mode = 0 ];then
		Input_RestAPI_Message=$(curl -k "$surl?serial_number=$1&type=war,sta" -H "content-type: application/json" -H "Authorization: Bearer "$token"") ####add parameters type 2024-05-07
	else
		Input_RestAPI_Message=$(curl -k "$surl?serial_number=$1&type=stc&stc_name=$2" -H "content-type: application/json" -H "Authorization: Bearer "$token"")
	fi
if [ -n "$Input_RestAPI_Message" ] && echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
	if [ -f $mods/cfg/$1.RSP ] && [ "$Run_Mode" = "0" ];then
		Fstation=$(echo $(cat $mods/cfg/$1.RSP | grep "^current_stc_name" | awk -F '=' '{print$2}'))
		findlog=$(find $Local_Logs/ -name "$1_${Fstation}_`date +"%Y%m%d"`*PASS.log" 2>/dev/null)
			
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/"code":0,"data"://g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/{{//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/}}//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/\[//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/\]//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/:/=/g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/"//g')
		echo "$Input_RestAPI_Message" | awk -F ',' '{ for (i=1; i<=NF; i++) print $i }' > $mods/cfg/$1.RSP
		Sstation=$(echo $(cat $mods/cfg/$1.RSP | grep "^current_stc_name" | awk -F '=' '{print$2}'))
		if [ -n "$findlog" ] && [ "$Fstation" = "$Sstation" ];then
			show_fail_message "$1 have pass $Fstation station but wareconn not please wait a minute and retest"
			show_fail_message "if still not pass next station please call TE or wareconn team!!!"
			exit 1
		else
			show_pass_msg "$1 Get test information from wareconn!!!"
		fi
	else
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/"code":0,"data"://g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/{{//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/}}//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/\[//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/\]//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/:/=/g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/"//g')
		echo "$Input_RestAPI_Message" | awk -F ',' '{ for (i=1; i<=NF; i++) print $i }' > $mods/cfg/$1.RSP
		show_pass_msg "$1 Get test information from wareconn!!!"
	fi
else
	show_fail_message "$Input_RestAPI_Message"
	show_fail_message "$1 Get test information from Wareconn Fail Please call TE"
	exit 1

fi
	
}

##mount server folder#################################################
Input_Server_Connection()
{
echo -e "\033[33m	Network Contacting : $Diag_Path	, Wait .....	\033[0m"
while true
	do
		echo 'computenode' | sudo -S umount $Diag_Path >/dev/null 2>&1
		echo 'computenode' | sudo -S mount -t cifs -o username=administrator,password=$pw_diag //$diagserver_IP/e/current $Diag_Path
		if [ $? -eq 0 ];then
			break
		fi	
	done	
echo -e ""
sleep 5
echo -e "\033[33m	Network Contacting : $Logs_Path	, Wait .....	\033[0m"

while true
	do
		echo 'computenode' | sudo -S umount $Logs_Path >/dev/null 2>&1
		echo 'computenode' | sudo -S mount -t cifs -o username=administrator,password=$pw_log //$logserver_IP/d $Logs_Path
		if [ $? -eq 0 ];then
			break
		fi	
	done	
echo -e ""
sleep 5

}

Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo()
{

station_name=""
Input_RestAPI_Message=""
part_number=""
Input_Upper_BSN=""
Input_Upper_BPN=""
###API

##get_token#############################

echo "get token from wareconn API"
Input_RestAPI_Message=$(curl -k "https://$API_IP:4443/api/v1/Oauth/token?${ID}&${SECRET}&${TYPE}")
if [ -n "$Input_RestAPI_Message" ] && echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
	token=$(echo "$Input_RestAPI_Message" | awk -F '"' '{print $10 }')
	show_pass_message "get_token successful:$token"	
else
	show_fail_message "$Input_RestAPI_Message"
	show_fail_message "get token Fail Please check net cable or call TE"
	exit 1
fi

##get_information from wareconn#########
echo "get data information from wareconn"
Input_RestAPI_Message=$(curl -k "$iurl?serial_number=$1" -H "content-type: application/json" -H "Authorization: Bearer "$token"") ####add parameters type 2024-05-07 
# echo $Input_RestAPI_Message
# pause
if [ -n "$Input_RestAPI_Message" ] && echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
	station_name=$(echo "$Input_RestAPI_Message" | jq -r '.list.now_stn')
	pn_and_sn=$(echo "$Input_RestAPI_Message" | jq -r 'last(.list.split_pcn[] | select(.part_number | startswith("699-24496-0002"))) | "\(.part_number) \(.serial_number)"')
	if [[ -n "$pn_and_sn" ]]; then
		Input_Upper_BPN=$(echo "$pn_and_sn" | awk '{print $1}')
		Input_Upper_BSN=$(echo "$pn_and_sn" | awk '{print $2}')
	else
		show_fail_message "$1 Get basebaord information from Wareconn Fail please Bingding basebaord"
		exit 1
	fi	
	#Input_Upper_BPN=$(echo "$Input_RestAPI_Message" | jq -r '.list.equipment_fixture[-1].equipment_name')
	# HS_QR_CODE=$(echo "$Input_RestAPI_Message" | jq -r '.list.assy_records[-1].serial_number')
	part_number=$(echo "$Input_RestAPI_Message" | jq -r '.list.part_number')
	# service_status=$(echo "$Input_RestAPI_Message" | jq -r '.list.is_serving')
	# board_699pn=$(echo "$Input_RestAPI_Message" | jq -r '.list."699pn"')
	show_pass_msg "$1 Get data information from wareconn!!!"
else	
	show_fail_message "$Input_RestAPI_Message"
	show_fail_message "$1 Get Data information from Wareconn Fail Please call TE"
	exit 1
fi	


}

#########################################################################################################
Output_Wareconn_Serial_Number_RestAPI_Mode_Start()
{

start_time=$(date '+%F %T')
if [ $site = "HOU" ];then
	echo ""
elif [ $site = "NC" ];then
	#####North America has time zone shifts to be judged
	tz_abbrev=$(date +"%Z")
	if [ "$tz_abbrev" = "EDT" ]; then
		stime=$(date '+%FT%T'-04:00)
	elif [ "$tz_abbrev" = "EST" ]; then
		stime=$(date '+%FT%T'-05:00)
	else
		show_warning_message "Please call TE change Time Zone America/New_York"
		exit 1
	fi
	
else
	show_warning_message "Please check the site"
	exit 1	
fi

Input_RestAPI_Message=""

###API

##get_token#############################

#if [ "$2" = "false" ];then

	echo "get token from wareconn API"
	Input_RestAPI_Message=$(curl -k "https://$API_IP:4443/api/v1/Oauth/token?${ID}&${SECRET}&${TYPE}")
	if [ -n "$Input_RestAPI_Message" ] && echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
		token=$(echo "$Input_RestAPI_Message" | awk -F '"' '{print $10 }')
		show_pass_message "get_token successful:$token"	
	else
		show_fail_message "$Input_RestAPI_Message"
		show_fail_message "get token Fail Please check net cable or call TE"
		exit 1
	fi

	## result start to api/vi/Station/start
	echo "upload start info to API "

	Input_RestAPI_Message=$(curl -k -X GET "$turl" -H "content-type: application/json" -H "Authorization: Bearer "$token"" -d '{"serial_number":"'"$1"'","station_name":"'"$current_stc_name"'","start_time":"'"${stime}"'","operator_id":"'"$Operator_ID"'","test_machine_number":"'"$RACK_ID"'","test_program_name":"'"$diag_name"'","test_program_version":"'"$CFG_VERSION"'","pn":"'"$Input_Upper_PN"'","model":"'"$PROJECT"'"}')
	if [ -n "$Input_RestAPI_Message" ] && echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
		show_pass_msg "$1 upload start information"	

	else	
		show_fail_message "$Input_RestAPI_Message"
		show_fail_message "$1 upload start information Fail Please call TE or wareconn team!!!"

		exit 1
	fi
#fi
	

}

##########################################################################################################
Output_Wareconn_Serial_Number_RestAPI_Mode_End()
{
Input_RestAPI_Message=""

###API

##get_token#############################
log_path="D:\\$PROJECT\\${Input_Upper_PN}\\${filename}"
echo "get token from wareconn API"
Input_RestAPI_Message=$(curl -k "https://$API_IP:4443/api/v1/Oauth/token?${ID}&${SECRET}&${TYPE}")
if [ -n "$Input_RestAPI_Message" ] && echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
	token=$(echo "$Input_RestAPI_Message" | awk -F '"' '{print $10 }')
	show_pass_message "get_token successful:$token"	
else
	show_fail_message "$Input_RestAPI_Message"
	show_fail_message "Get token Fail Please check net cable or call TE"
	exit 1
fi

##Report station result to api/vi/Station/end
echo "report station result to wareconn API "
Input_RestAPI_Message=$(curl -k "$rurl?serial_number=$1&log_path=$log_path" -H "content-type: application/json" -H "Authorization: Bearer "$token"")
if [ -n "$Input_RestAPI_Message" ] && echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
	show_pass_msg "$1 report result pass"	
else	
	show_fail_message "$Input_RestAPI_Message"
	show_fail_message "$1 report result FAIL Please call TE or wareconn Team"
	#exit 1
fi

}

get_information()
{
MACHINE=$(get_config "MACHINE")
current_stc_name=$(get_config "current_stc_name")
Input_Script=$(get_config "SCRIPT_VER")
	
}

#####wareconn control script version##################################################################
script_check()
{
	local_sum=$(md5sum /home/com/$Script_File | awk '{print $1}')
	server_sum=$(md5sum ${Diag_Path}/${Input_Script}_${Script_File} | awk '{print $1}')
	
	if [ "${Script_VER}" = "${Input_Script}" ] && [ "$local_sum" = "$server_sum" ];then
		echo "Script Version is ${Script_VER}"
	else
		echo "Script Version is ${Script_VER}"
		if [ -f ${Diag_Path}/${Input_Script}_${Script_File} ];then
			echo 'computenode' | sudo -S cp -rf ${Diag_Path}/${Input_Script}_${Script_File} /home/com/$Script_File
			sleep 15
			bash /home/com/$Script_File
		else
			Input_Server_Connection
			if [ -f ${Diag_Path}/${Input_Script}_${Script_File} ];then
				echo 'computenode' | sudo -S cp -rf ${Diag_Path}/${Input_Script}_${Script_File} /home/com/$Script_File
				sleep 15
				bash /home/com/$Script_File
			else
				show_fail_msg "not exsit script please check"
				exit 1
			fi
		fi		
	fi	


}


analysis_sta()
{
	cd $mods/cfg/
	echo 'computenode' | sudo -S cp  ${Input_Upper_SN}.RSP cfg.ini
	get_information
	script_check
	diag_name=$(get_config "Diag")
	diag_VER=$diag_name.tar.gz	

}

rwdata()
{
datafile="$mods/datafile"
echo "" > $datafile
echo "SN:$Input_Upper_SN" >> $datafile
echo "PN:$Input_Upper_PN" >> $datafile
echo "BOARD_SN:$Input_Upper_BSN" >> $datafile
echo "BOARD_PN:$Input_Upper_BPN" >> $datafile
echo "PBRNumber:$Input_Upper_BPR" >> $datafile
echo "BMC_IP:$BMC_IP" >> $datafile
echo "DUT_IP:$TH500_IP" >> $datafile
echo "PDU:vertiv" >> $datafile
echo "PDU_IP:"\"192.168.${RACK}.6,192.168.${RACK}.7\""" >> $datafile
echo "PDU_USERNAME:admin" >> $datafile
echo "PDU_PASSWORD:1qaz@WSX" >> $datafile
echo "PDU_PORTS:$PDU_PORTS" >> $datafile

}

Run_Diag()
{
###2024-06-15

	cd $mods
	if [ $Run_Mode = "0" ];then 
		Output_Wareconn_Serial_Number_RestAPI_Mode_Start  ${Input_Upper_SN}
	fi		
	rwdata
	
	if [ ${current_stc_name} = "FLA" ];then
		echo -e "sudo ./run_datacenter.sh --process=FLA --factory=<FACTORY_CODE> --datafile=<full path of datafile>"
		sleep 2
		sudo ./run_datacenter.sh --process=FLA --factory=FXHC --datafile="$datafile"			

	elif [ ${current_stc_name} = "FCT" ];then
		echo -e "sudo ./run_datacenter.sh --process=FCT --factory=<FACTORY_CODE> --datafile=<full path of datafile>"
		sleep 2
		sudo ./run_datacenter.sh --process=FCT --factory=FXHC --datafile="$datafile"
		
	elif [ ${current_stc_name} = "RIN" ];then
		echo -e "sudo ./run_datacenter.sh --process=RIN --factory=<FACTORY_CODE> --datafile=<full path of datafile>"
		sleep 2
		sudo ./run_datacenter.sh --process=RIN --factory=FXHC --datafile="$datafile"
	elif [ ${current_stc_name} = "FLB" ];then
		echo -e "sudo ./run_datacenter.sh --process=FLB --factory=<FACTORY_CODE> --datafile=<full path of datafile>"
		sleep 2
		sudo ./run_datacenter.sh --process=FLB --factory=FXHC --datafile="$datafile"
	elif [ ${current_stc_name} = "DCC" ];then
		echo -e "sudo ./run_datacenter.sh --process=DCC --factory=<FACTORY_CODE> --datafile=<full path of datafile>"
		sleep 2
		sudo ./run_datacenter.sh --process=DCC --factory=FXHC --datafile="$datafile"
	else
		exit 1
	fi

}

Upload_Log()
{

Final_status="Final status"

if [ "$Run_Mode" != "0" ];then
	current_stc_name=$station	
fi	

end_time=`date +"%Y%m%d_%H%M%S"`
EndTesttime=`date +"%Y%m%d%H%M%S"`
filename=$1_"${current_stc_name}"_"$end_time"_$2.log
analysis_log $1 $2

cd $LOGFILE
echo "${PROJECT} L10 Functional Test" >"${filename}"
echo "${diag_name} (config version: ${CFG_VERSION})" >>"${filename}"
echo "============================================================================" >>"${filename}"
echo "Start time              :$start_time" >>"${filename}"
echo "End time                :$(date '+%F %T')" >>"${filename}"
echo "Part number             :${Input_Upper_PN}" >>"${filename}"
echo "Serial number           :${1}" >>"${filename}"
echo "operator_id             :$Operator_ID" >>"${filename}"
echo "fixture_id              :$RACK_ID" >>"${filename}"
echo "FactoryErrorCode        :$FactoryErrorCode" >> "${filename}"
echo "FactoryErrorMsg         :$FactoryErrorMsg" >> "${filename}"
echo " " >>"${filename}"
echo "============================================================================" >>"${filename}"
echo "$Final_status: ${2}" >> "${filename}"
echo "****************************************************************************" >>"${filename}"
echo "FUNCTIONAL TESTING" >>"${filename}"
echo "****************************************************************************" >>"${filename}"

cat $tasfile | tr -d "\000" >>"${filename}"

## upload test log to log server
if [ -d ${Logs_Path}/$PROJECT ]; then
	[ ! -d ${Logs_Path}/$PROJECT/${Input_Upper_PN} ] && echo 'computenode' | sudo -S mkdir ${Logs_Path}/$PROJECT/${Input_Upper_PN}
	echo 'computenode' | sudo -S cp -rf *$1* ${Logs_Path}/$PROJECT/${Input_Upper_PN}
	echo 'computenode' | sudo -S cp -rf *$1* ${Local_Logs}
	echo 'computenode' | sudo -S rm -rf *$1*	
else
	Input_Server_Connection
	if [ -d ${Logs_Path}/$PROJECT ]; then
		[ ! -d ${Logs_Path}/$PROJECT/${Input_Upper_PN} ] && echo 'computenode' | sudo -S  mkdir ${Logs_Path}/$PROJECT/${Input_Upper_PN}
		echo 'computenode' | sudo -S cp -rf *$1* ${Logs_Path}/$PROJECT/${Input_Upper_PN}
		echo 'computenode' | sudo -S cp -rf *$1* ${Local_Logs}
		echo 'computenode' | sudo -S rm -rf *$1*
	else
		show_fail_message "show_fail_message Mounting log server fail."
		exit 1 
	fi	
	
fi	
####report test result to wareconn

if [ "$Run_Mode" = "0" ];then
	Output_Wareconn_Serial_Number_RestAPI_Mode_End $1
fi	

}


analysis_log()
{
FactoryErrorCode=""
FactoryErrorMsg=""

cd $LOGFILE

LogName=$(find $LOGFILE/ -name "*$1_*_${current_stc_name}*.tsg" 2>/dev/null)

if [ -n "$LogName" ];then
	if [ "$2" = "PASS" ];then
		FactoryErrorCode="0"
	else	
		FactoryErrorCode=$(jq -r '.[] | select(.tag == "FactoryErrorCode") | .value' "$LogName")
	fi	
	FactoryErrorMsg=$(jq -r '.[] | select(.tag == "FactoryErrorMsg") | .value' "$LogName")
	name=$(find -name "*$1*" -type d)
	filenames=$(basename $name)
	outputfile=$(find $filenames -name "output.txt" )
	tasfile=$(find $filenames -name "tas.txt")	
	outputpath=$(pwd)/$outputfile
	cat $tasfile > $filenames.log
	echo "" >> $filenames.log
	echo ""  >> $filenames.log
	echo "file:$outputpath" >> $filenames.log
	echo ""  >> $filenames.log
	cat $outputfile >> $filenames.log
	echo ""  >> $filenames.log
	echo ""  >> $filenames.log
else	
	show_fail_message "Can't find the analysis Log"
fi	

}


check_station()
{
echo "checking station please wait a moment..."
sleep 10
Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo $1

if [ $station_name = "$2" ];then
	if [ $3 = "PASS" ];then
		show_warning_message "################################warning#################################" 
		show_warning_message "$1 not pass $2 station please reboot and retest"
		show_warning_message "If $1 still at $2 station please call TE!!!"
	else
		show_warning_message "#################################warning##############################" 
		show_warning_message "Current station is $2! EC$FactoryErrorCode can retest,please change the tester and retest!!!"
	fi	
else
	if [ $3 = "PASS" ];then
		show_warning_message "################################warning####################################"
		show_warning_message "$1 have passed $2 next station is $station_name"
	else
		show_fail $1 $4 $5
		show_warning_message "###############################warning#####################################" 
		show_warning_message "$1 have failed $2 next station is $station_name"
	fi	
fi	

}

#####################################################################
#                                                                   #
# Show FAIL                                                         #
#                                                                   #
#####################################################################
show_fail()
{
 
	echo
	show_fail_message "############################################################################"
	show_fail_message "Start time              :$start_time"
	show_fail_message "End time                :$(date '+%F %T')"
	show_fail_message "Part number             :${Input_Upper_PN}"
	show_fail_message "diag                    :${diag_name}"
	show_fail_message "Serial number           :${1}"
	show_fail_message "operator_id             :$Operator_ID"
	show_fail_message "fixture_id              :$RACK_ID"
	show_fail_message "FactoryErrorCode        :${2}"
	show_fail_message "FactoryErrorMsg         :${3}"
	show_fail_message "Status                  :FAIL"
	show_fail_message "############################################################################"
	echo 

	
}

#####download diag from diagserver#####################################
DownLoad()
{

#####Prepare diag######
cd $mods 
ls | grep -v cfg | xargs rm -fr
if [ -n "${diag_name}" ];then
	if [ -d ${Diag_Path}/${MACHINE}/${diag_name} ]; then
	#if [ -d ${Diag_Path}/${Input_Upper_PN}/${diag_name} ]; then
		show_pass_message "DownLoad Diag From Server Please Waiting ..."
		#echo "${diag_VER}"
		#pause
		#cp -rf ${Diag_Path}/${Input_Upper_PN}/${diag_name}/* $mods
		echo 'computenode' | sudo -S cp -rf ${Diag_Path}/${MACHINE}/${diag_name}/* $mods
		cd $mods
		tar -xf ${diag_VER} 
		if [ $? -ne 0 ];then
			show_fail_message "Please make sure exist diag zip files"
			show_fail_msg "DownLoad Diag FAIL"
			exit 1
		fi	
		#cp  ${Diag_Path}/${MACHINE}/${NVFLAH_VER}/* 
		
	else
		Input_Server_Connection
		if [ -d ${Diag_Path}/${MACHINE}/${diag_name} ]; then
		#if [ -d ${Diag_Path}/${Input_Upper_PN}/${diag_name} ]; then
			show_pass_message "DownLoad Diag From Server Please Waiting ..."
			echo 'computenode' | sudo -S cp -rf ${Diag_Path}/${MACHINE}/${diag_name}/* $mods
			#cp -rf ${Diag_Path}/${Input_Upper_PN}/${diag_name}/* $mods
			cd $mods
			tar -xf ${diag_VER} 
			if [ $? -ne 0 ];then
				show_fail_message "Please make sure exist diag zip files"
				show_fail_msg "DownLoad Diag FAIL"
				exit 1
			fi	
			#cp  ${Diag_Path}/${MACHINE}/${NVFLAH_VER}/* ./
		else
			show_fail_message "Diag isn't exist Please Call TE"
			show_fail_msg "DownLoad Diag FAIL"
			exit 1
		fi	
	fi
else
	show_warning_message "diag_name is null, please call TE to check the wareconn settings"
	exit 1
fi	
}

########################################################
########################MAIN############################
if [ $site = "HOU" ];then
	echo ""
elif [ $site = "NC" ];then
	diagserver_IP=$NC_diagserver_IP
	logserver_IP=$NC_logserver_IP
	API_IP=$NC_API_IP
	ID=$NID
	SECRET=$NSECRET
	pw_diag=$NC_pw_diag
	pw_log=$NC_pw_log

else
	show_warning_message "Please check the site"
	exit 1	
fi

#echo "" > /var/log/message
#sleep 50
if [ ! -f $OPID ] && [ ! -d ${INI_folder} ];then
	Input_Server_Connection		
fi

if [ ! -f /home/com/$PDU_control_file ];then
	echo 'computenode' | sudo -S cp $Diag_Path/$PDU_control_file /home/com/ 
fi

if [ -f "$INI_folder/list_st_all.ini" ] && [ -f "$INI_folder/list_error.ini" ] && [ -f "$INI_folder/Initial_Parameter_Setting.csv" ];then
	mapfile -t list_st_all < "$INI_folder/list_st_all.ini" 2>/dev/null
	mapfile -t list_error < "$INI_folder/list_error.ini" 2>/dev/null
else
	show_warning_message "make sure list_sta.ini,list_error.ini,Initial_Parameter_Setting.csv files are exist please call TE to check diag server"
	exit 1
fi		
	
surl="https://$API_IP:4443/api/v1/test-profile/get"
iurl="https://$API_IP:4443/api/v1/ItemInfo/get"
rurl="https://$API_IP:4443/api/v1/Station/end"
turl="https://$API_IP:4443/api/v1/Station/start"

step=0
status="SCAN"
while [[ $step != 1 ]]
do

	case ${status} in 

		"SCAN")
		
			status=0
			flg=0
			num=0
			let num+=1
			
			while [ $status = 0 ]; do
				if [ $flg = 1 ]; then
					read -p "	Scan Slot ID again: " Slot_ID 
				else
					echo -e "\033[32m	Please Enter ID : Slot_ID \033[0m"
					read -p "	Scan Slot ID : " Slot_ID
				fi
				if [[ ${#Slot_ID} = "1" ]]; then
					status=1
				else
					flg=1
				fi
			done
			
			status=0
			flg=0
			num=0
			let num+=1
			
			while [ $status = 0 ]; do
				if [ $flg = 1 ]; then
					read -p "	Scan Operator ID again: " Operator_ID 
				else
					echo -e "\033[32m	Please Enter ID : Operator ID \033[0m"
					read -p "	Scan Operator ID : " Operator_ID
				fi
				if grep -q "^$Operator_ID$" $OPID ; then
					if [ $(expr length $Operator_ID) -eq 8 ] || [ -n "$Operator_ID" ];then
						status=1
					else
						flg=1
					fi
				else
					flg=1
				fi
			done
			
			if [ "$Operator_ID" = "DEBUG001" ];then
				Run_Mode=1
				PROJECT="DEBUG"
			fi		

			RACK_ID="${RACK}-${Slot_ID}"
			echo $RACK_ID
			echo $Slot_ID
			#pause
			TH500_IP=`cat ${Path_Initial_Parameter_Setting} | grep ${RACK_ID} | awk -F"," '{printf $3}' | sed 's/\n//g' | sed 's/\r//g' | sed 's/$//g'`
			BMC_IP=`cat ${Path_Initial_Parameter_Setting} | grep ${RACK_ID} | awk -F"," '{printf $4}' | sed 's/\n//g' | sed 's/\r//g' | sed 's/$//g'`
			
			PDU_rack=$(echo $RACK_ID | awk -F"-" '{printf $1}')
			PDU=$(echo $RACK_ID | awk -F"-" '{printf $2}')
			case $PDU in
				"1")
					PDU="A"
					PDU_PORTS='"0,3,6"'
					;;
				"2")
					PDU="B"
					PDU_PORTS='"9,12,15"'
					;;
				"3")
					PDU="C"
					PDU_PORTS='"18,21,24"'
					;;
				"4")
					PDU="D"
					PDU_PORTS='"27,30,33"'
			esac
			[ -d "/home/com/DiagTest/$RACK_ID/" ] || mkdir /home/com/DiagTest/$RACK_ID
			[ -d "/home/com/DiagTest/${RACK_ID}/cfg/" ] || mkdir /home/com/DiagTest/${RACK_ID}/cfg
			[ -d "/home/com/DiagTest/${RACK_ID}/logs/" ] || mkdir /home/com/DiagTest/${RACK_ID}/logs
			mods="/home/com/DiagTest/$RACK_ID"
			CFGFILE="$mods/cfg/cfg.ini"
			LOGFILE="$mods/logs"
			work_path=$mods
			echo 'computenode' | sudo -S rm -rf $LOGFILE/*
			
			echo_message "${PDU_rack} ${PDU} power on"
			echo 'computenode' | sudo -S python3 /home/com/$PDU_control_file R${PDU_rack} ${PDU} on
			echo_message "sleep 700"
			sleep 300
			ipmitool -C 17 -I lanplus -H ${BMC_IP} -U ${BMC_SSH_USERNAME} -P ${BMC_SSH_PASSWORD} power on
			if [ $? = 0 ];then
				show_pass_message "Chassis power on successful waiting for login baseOS"
			else
				show_fail_message "Chassis power on fail please check BMC status"
				exit 1
			fi	
			sleep 400
			
			# determine the FRU ID of board with ${FRU_DEVICE_STR} by isolating it from other FRUs and then extracting the ID
			fru_id_cmd="ipmitool -C 17 -I lanplus -H ${BMC_IP} -U ${BMC_SSH_USERNAME} -P ${BMC_SSH_PASSWORD} -N 10 fru print | tac | awk '/${FRU_DEVICE_STR}/,/FRU Device Description/' | grep -oP '\(ID\s+\K\d+'"
			#echo ${fru_id_cmd}

			fru_id=$(eval ${fru_id_cmd})

			# try again if blank
			if [[ "${fru_id}" == "" ]] ;then
				fru_id_cmd="ipmitool -C 17 -I lanplus -H ${BMC_IP} -U ${BMC_SSH_USERNAME} -P ${BMC_SSH_PASSWORD} -N 10 fru print | tac | awk '/${FRU_DEVICE_STR}/,/FRU Device Description/' | grep -oP '\(ID\s+\K\d+'"
				fru_id=$(eval ${fru_id_cmd})
			fi

			echo "FRU ID is ${fru_id}"

			if [[ "${fru_id}" == "" ]] ;then
				echo "{{CORE_ERROR_MSG:unable to determine FRU ID}}"
				exit 1
			fi
			
			
			Input_Upper_BBSN=$(ipmitool -C 17 -I lanplus -H ${BMC_IP} -U ${BMC_SSH_USERNAME} -P ${BMC_SSH_PASSWORD} fru print ${fru_id} | grep -oP "Board Serial\s+:\s+\K.*")
			Input_Upper_PSN=$(ipmitool -C 17 -I lanplus -H ${BMC_IP} -U ${BMC_SSH_USERNAME} -P ${BMC_SSH_PASSWORD} fru print ${fru_id} | grep -oP "Product Serial\s+:\s+\K.*")
			#Input_Upper_BPN=$(ipmitool -C 17 -I lanplus -H ${BMC_IP} -U ${BMC_SSH_USERNAME} -P ${BMC_SSH_PASSWORD} fru print ${fru_id} | grep -oP "Board Part Number\s+:\s+\K.*")
			Input_Upper_BPR=$(ipmitool -C 17 -I lanplus -H ${BMC_IP} -U ${BMC_SSH_USERNAME} -P ${BMC_SSH_PASSWORD} fru print ${fru_id} | grep -oP "Board Product\s+:\s+\K.*")
			
			if [ -n "$Input_Upper_PSN" ];then
				if [ "$Input_Upper_BBSN" = "$Input_Upper_PSN" ];then
					status=0
					flg=0
					num=0
					let num+=1
					
					while [ $status = 0 ]; do
						if [ $flg = 1 ]; then
							read -p "	Scan Pruduct SN again: " Input_Upper_SCN 
						else
							echo -e "\033[32m	Please Scan Pruduct SN : Serial number \033[0m"
							read -p "	Scan Pruduct SN : " Input_Upper_SCN
						fi
						if [[ ${#Input_Upper_SCN} = "13" ]]; then
							status=1
						else
							flg=1
						fi
					done
					Input_Upper_SN=$Input_Upper_SCN
				else
					Input_Upper_SN=$Input_Upper_PSN
				fi	
				status="CHECK_SFC_ROUTE"
			else
				show_fail_message "Can't Detect UUT Please Inserd one UUT"
				exit 1
			fi	
			;;
			
		"CHECK_SFC_ROUTE")
			if [ $Run_Mode = "0" ];then
				Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo ${Input_Upper_SN}
				Input_Upper_Station=$station_name
				Input_Upper_PN=$part_number
				if [[ "${list_st_all[@]}" =~ "$Input_Upper_Station" ]];then
					Input_Wareconn_Serial_Number_RestAPI_Mode ${Input_Upper_SN}
					analysis_sta					
				else
					show_fail_message "Current Station is $Input_Upper_Station  not test station"
					exit 1 
				fi					
			else
				Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo ${Input_Upper_SN}
				Input_Upper_Station=$station_name
				Input_Upper_PN=$part_number
				read -p "Please Input station :" station
				if [[ "${list_st_all[@]}" =~ "$station" ]];then
					Input_Wareconn_Serial_Number_RestAPI_Mode ${Input_Upper_SN} $station
					analysis_sta
				else
					show_fail_message "station wrong please check!!!"
					exit 1
				fi
			fi	
			status="TEST_DIAGS"
			;;
			
		"TEST_DIAGS")
			if [[ ${Input_Upper_Station} == "FCT" ]] || [[ ${station} == "FCT" ]];then
				PING_BMC
				PING_TH500
				CHECK_NVME_FW
				CHECK_MST_STATUS
				CHECK_PCIE_SPEED
				if [ ${check_status} -ne 0 ];then
					FAILED
				else
					PASSED
				fi
			else
				PING_BMC
				PING_TH500
			fi
			
			if [ -f $mods/$diag_VER ]; then
				Run_Diag
			else
				DownLoad
				Run_Diag			
			fi
			
			
			Path_testlog=`cat $mods/logs/event_logs.log | tail -n 1 | awk -F" " '{printf $5}'  | sed 's/\n//g' | sed 's/\r//g' | sed 's/$//g'`
			_test_result=`cat ${Path_testlog}/nautilus/output.txt | grep "TestStatus" | awk -F"=" '{printf $2}' | awk '{gsub(" ","");print}' | sed 's/\n//g' | sed 's/\r//g' | sed 's/$//g'`
			
			echo_green $Path_testlog
			echo_green $_test_result
			
			cd ${mods}
			if [[ ${_test_result} == "PASS" ]];then
				Upload_Log ${Input_Upper_SN} PASS
				PASSED
				if [[ ${current_stc_name} == "DCC" ]];then
					echo 'computenode' | sudo -S python3 /home/com/$PDU_control_file  R${PDU_rack} ${PDU} off
					echo_green "Test diag finish. ${PDU_rack} ${PDU} power off"
					exit 3
				else
					if [ $Run_Mode = "0" ];then 
						status="CHECK_SFC_ROUTE"
					else
						step=1
					fi	
				fi
			else
				Upload_Log ${Input_Upper_SN} FAIL
				check_station ${Input_Upper_SN} ${current_stc_name} FAIL ${FactoryErrorCode} ${FactoryErrorMsg}
				#FAILED
				echo 'computenode' | sudo -S python3 /home/com/$PDU_control_file R${PDU_rack} ${PDU} off
				echo_alert "Test diag fail. ${PDU_rack} ${PDU} power off"
				exit 3
			fi
						
			;;
			
		"AC_POWER_CYCLE")
			
			
			echo_message "${PDU_rack} ${PDU} power off"
			sudo python3 /home/com/$PDU_control_file R${PDU_rack} ${PDU} off
			echo_message "sleep 90"
			sleep 90
			AC_POWER_CYCLE
			echo_message "${PDU_rack} ${PDU} power on"
			sudo python3 /home/com/$PDU_control_file R${PDU_rack} ${PDU} on
			echo_message "sleep 300"
			sleep 300
			
			status="CHECK_SFC_ROUTE"
			;;

		*)
			exit 3
			
	esac

done



exit 3


