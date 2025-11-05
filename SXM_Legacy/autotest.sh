#!/bin/bash
##**********************************************************************************
## Project       : RMA_NVIDIA
## Filename      : autotest.sh
## Description   : NVIDIA test automatic
## Usage         : n/a
##
##
## Version History
##-------------------------------
## Version       : 1.0.8
## Release date  : 2024-03-08
## Revised by    : Winter Liu
## Description   : Initial release
## add compatibility with clear BBX station 2024-04-26 "when wareconn can get test information by station this function no need"
## Add the transmission parameters type, and return the information according to the warranty and the station 2024-05-07
## Add script version control 2024-05-07
## Add analysis Log 2024-05-22
## Add run mode 2024-06-15
## add install tool function 2024-08-26
## add new log for nvidia 2024-08-26
## add blocking test pass but wareconn doesn't auto-pass feature
## add upload result to LF API 2024-11-08
##**********************************************************************************

[ -d "/mnt/nv/logs/" ] || mkdir /mnt/nv/logs
[ -d "/mnt/nv/HEAVEN/" ] || mkdir /mnt/nv/HEAVEN/
[ -d "/mnt/nv/server_diag" ] || mkdir /mnt/nv/server_diag
[ -d "/mnt/nv/server_logs" ] || mkdir /mnt/nv/server_logs
[ -d "/mnt/nv/mods/test" ] || mkdir /mnt/nv/mods/test
[ -d "/mnt/nv/mods/test/cfg" ] || mkdir /mnt/nv/mods/test/cfg
[ -d "/mnt/nv/mods/test/logs" ] || mkdir /mnt/nv/mods/test/logs

export HEAVEN="/mnt/nv/HEAVEN/"
export Diag_Path="/mnt/nv/server_diag"
export Logs_Path="/mnt/nv/server_logs"
export mods="/mnt/nv/mods/test"
export CSVFILE="$mods/core/flash/PESG.csv"
export CFGFILE="$mods/cfg/cfg.ini"
export LOGFILE="$mods/logs"
export SCANFILE="$mods/cfg/uutself.cfg.env"
export Local_Logs="/mnt/nv/logs"
export TJ_logserver_IP="10.67.240.77"
export TJ_diagserver_IP="10.67.240.67"
export NC_logserver_IP="192.168.102.20"
export NC_diagserver_IP="192.168.102.21"
export NC_API_IP="192.168.102.20"
export TJ_API_IP="10.67.240.77"
export OPID="$Diag_Path/OPID/OPID.ini"  ###add check operator ID 4/4/2024####
export Script_File="autotest.sh"
declare -u station
#declare -u operator_id
declare -u fixture_id


Script_VER="1.0.8"  ###script version 2024-11-08
CFG_VERSION="1.0.8"
PROJECT="TESLA"
Process_Result=""
Input_Upper_SN=""
Input_Lower_SN=""
Output_Upper_SN=""
Output_Lower_SN=""
Input_Upper_PN=""
Input_Lower_PN=""
testqty=""
current_stc_name=""
diag_name=""
HEAVEN_VER=""
Scan_Upper_SN=""
Scan_Lower_SN=""
MACHINE=""
NVFLASH_VER=""
NVINFOROM=""
diag_VER=""
Input_Upper_Station=""
Input_Lower_Station=""
BIOS_VER=""
BIOS_NAME=""
test_item=""
Fail_Module=""
Final_status=""
LogName=""
FactoryErrorCode=""
FactoryErrorMsg=""
VBIOS_VERSION=""
Run_Mode=0
Input_Lower_ESN=""
Input_Lower_Eboard=""
Input_Lower_Status=""
Input_Lower_HSC=""
Input_Upper_ESN=""
Input_Upper_Eboard=""
Input_Upper_Status=""
Input_Upper_HSC=""
Tstation=""
cont="true"


######test station list######
list_st="FLA BAT BIT FCT FPF OQA FT FLB IST CHIFLASH DG5 FLC IST2 EFT ZPI FLA2" ###no need spare parts station list###
list_stn="NVL DG3 DG4 IOT FLK"                   ###need more spare parts station list###
single_list_stn="FLA FLB CHIFLASH IOT FLK NVL FLC FLA2"                    ###single baord station list###
list_st_all="CHIFLASH FLA FLB BAT BIT FCT FT FPF OQA IST NVL DG3 DG4 DG5 IOT FLK FLA2 FLC IST2 EFT ZPI" ###ALL TEST STATION 2024-06-15

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
# Show title message                                                 #
#                                                                    #
######################################################################
show_title()
{
    _TEXT=$@
    len=${#_TEXT}

    while [ $len -lt 60 ]
    do
    _TEXT=$_TEXT"-"
    len=${#_TEXT}
    done
    echo "$_TEXT"
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

#####################################################################
#                                                                   #
# Show PASS                                                         #
#                                                                   #
#####################################################################
show_pass()
{
	echo
	echo
	echo
	echo
	echo
	echo
	echo
	echo
	echo	
	echo	
	show_pass_message " 			XXXXXXX     XXXX     XXXXXX    XXXXXX"
	show_pass_message " 			XXXXXXXX   XXXXXX   XXXXXXXX  XXXXXXXX"
	show_pass_message " 			XX    XX  XX    XX  XX     X  XX     X"
	show_pass_message " 			XX    XX  XX    XX   XXX       XXX"
	show_pass_message " 			XXXXXXXX  XXXXXXXX    XXXX      XXXX"
	show_pass_message " 			XXXXXXX   XXXXXXXX      XXX       XXX"
	show_pass_message " 			XX        XX    XX  X     XX  X     XX"
	show_pass_message " 			XX        XX    XX  XXXXXXXX  XXXXXXXX"
	show_pass_message " 			XX        XX    XX   XXXXXX    XXXXXX"
	echo
	echo

}

#####################################################################
#                                                                   #
# Show FAIL                                                         #
#                                                                   #
#####################################################################
show_fail()
{
 
	echo
	echo
	show_fail_message "############################################################################"
	show_fail_message "Start time              :$start_time"
	show_fail_message "End time                :$(date '+%F %T')"
	show_fail_message "Part number             :${Input_Upper_PN}"
	show_fail_message "diag                    :${diag_name}"
	show_fail_message "Serial number           :${1}"
	show_fail_message "operator_id             :`grep "operator_id=" $SCANFILE |sed 's/.*= *//'`"
	show_fail_message "fixture_id              :`grep "fixture_id=" $SCANFILE |sed 's/.*= *//'`"
	show_fail_message "VBIOS                   :$BIOS_VER"
	show_fail_message "FactoryErrorCode        :${2}"
	show_fail_message "FactoryErrorMsg         :${3}"
	show_fail_message "Status                  :FAIL"
	show_fail_message "############################################################################"
	echo 
	echo 
	echo 
	echo
	
}
####get information from wareconn####################################
Input_Wareconn_Serial_Number_RestAPI_Mode()
{
###API

now_stn=""
Input_RestAPI_Message=""
####TJAPI###############################
TID="client_id=NocHScsf53aqE"
TSECRET="client_secret=f8d6b0450c2a2af273a26569cdb0de04"
####NCAPI###############################
ID="client_id=vE7BhzDJhqO"
SECRET="client_secret=0f40daa800fd87e20e0c6a8230c6e28593f1904c7edfaa18cbbca2f5bc9272b5"
########################################
TYPE="grant_type=client_credentials"
furl="http://$NC_API_IP/api/v1/Oauth/token"
surl="http://$NC_API_IP/api/v1/test-profile/get"
turl="http://$NC_API_IP/api/v1/Station/get"
##get_token#############################

echo "get token from wareconn API"
Input_RestAPI_Message=$(curl -X GET "$NC_API_IP/api/v1/Oauth/token?${ID}&${SECRET}&${TYPE}")
if echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
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
		Input_RestAPI_Message=$(curl -X GET "$surl" -H "content-type: application/json" -H "Authorization: Bearer "$token"" -d '{"serial_number":'"$1"',"type":"war,sta"}') ####add parameters type 2024-05-07
	else
		Input_RestAPI_Message=$(curl -X GET "$surl?serial_number=$1&type=stc&stc_name=$2" -H "content-type: application/json" -H "Authorization: Bearer "$token"")
	fi
if echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
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
			show_fail_message "$1 have pass $Fstation station but wareconn not please call TE or wareconn team!!!"
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
		umount $Diag_Path >/dev/null 2>&1
		mount -t cifs -o username=administrator,password=TJ77921~ //$NC_diagserver_IP/e/current $Diag_Path
		if [ $? -eq 0 ];then
			break
		fi	
	done	
echo -e ""
sleep 5
echo -e "\033[33m	Network Contacting : $Logs_Path	, Wait .....	\033[0m"

while true
	do
		umount $Logs_Path >/dev/null 2>&1
		mount -t cifs -o username=administrator,password=TJ77921~ //$NC_logserver_IP/d $Logs_Path
		if [ $? -eq 0 ];then
			break
		fi	
	done	
echo -e ""
sleep 5

}
###SCAN################################################################
Output_Scan_Infor()
{

	chk_len()
	{
		if [ $(expr length ${2}) -ne $3 ]; then
			echo "Please check ${1} (${2}, length ${3}) " | tee -a $LOGFILE/log.txt && flg = 1
		fi
	}

	scan_label()
	{
	
	
		status=0
		flg=0
		num=0
		let num+=1
		
		while [ $status = 0 ]; do
			if [ $flg = 1 ]; then
				read -p " $num. Scan operator ID again:" operator_id 
			else
				read -p " $num. Scan Operator ID:" operator_id
			fi
			if grep -q "^$operator_id$" $OPID ; then
				if [ -n "$operator_id" ];then
					status=1
				else
					flg=1
				fi
			else
				flg=1
			fi
		done
	
		let num+=1
		status=0
		flg=0
		while [ $status = 0 ]; do
			if [ $flg = 1 ]; then
				read -p " $num. Scan Fixture ID (length 9) again:" fixture_id 
			else
				read -p " $num. Scan Fixture ID (length 9):" fixture_id
			fi
			if [ $(expr length $fixture_id) -eq 9 ]; then
				status=1
			else
				flg=1
			fi
		done
		if [ $testqty = "2" ];then	
		
			let num+=1
			status=0
			flg=0	
			while [ $status = 0 ]; do
				if [ $flg = 1 ]; then
					read -p " $num. Scan Board SN1 (length 13) again:" Scan_Upper_SN 
				else
					read -p " $num. Scan Board SN1 (length 13):" Scan_Upper_SN
				fi
				if [ $(expr length $Scan_Upper_SN) -eq 13 ]; then
					status=1
				else
					flg=1
				fi
			done	
			
			let num+=1
			status=0
			flg=0	
			while [ $status = 0 ]; do
				if [ $flg = 1 ]; then
					read -p " $num. Scan Board SN2 (length 13) again:" Scan_Lower_SN 
				else
					read -p " $num. Scan Board SN2 (length 13):" Scan_Lower_SN
				fi
				if [ $(expr length $Scan_Lower_SN) -eq 13 ]; then
					status=1
				else
					flg=1
				fi
			done
		else
			let num+=1
			status=0
			flg=0	
			while [ $status = 0 ]; do
				if [ $flg = 1 ]; then
					read -p " $num. Scan Board SN (length 13) again:" Scan_Upper_SN 
				else
					read -p " $num. Scan Board SN (length 13):" Scan_Upper_SN
				fi
				if [ $(expr length $Scan_Upper_SN) -eq 13 ]; then
					status=1
				else
					flg=1
				fi
			done
		fi		

	}
	if [ ! -f $OPID ]; then
		Input_Server_Connection
	fi	
	scan_label
	sed -i 's/operator_id=.*$/operator_id='${operator_id}'/g' $SCANFILE
	sed -i 's/fixture_id=.*$/fixture_id='${fixture_id}'/g' $SCANFILE
	sed -i 's/serial_number=.*$/serial_number='${Scan_Upper_SN}'/g' $SCANFILE
	sed -i 's/serial_number2=.*$/serial_number2='${Scan_Lower_SN}'/g' $SCANFILE
	show_pass_msg "SCAN info OK"

}
#####Read serial number from tester###################################
Read_SN()

{
if [ ! -f "nvflash_mfg" ];then
	Input_Server_Connection
	cp $Diag_Path/nvflash_mfg ./
	[ ! -f "uutself.cfg.env" ] && cp $Diag_Path/uutself.cfg.env ./
fi

counts=$(lspci | grep NV | wc -l)

if [ $counts = "2" ]; then
	port1=$(lspci | grep NV | head -n 1 | awk '{ print $1 }')
	port2=$(lspci | grep NV | tail -n 1 | awk '{ print $1 }')
	Output_Upper_SN=$(./nvflash_mfg -B $port1  --rdobd | grep -m 1 'BoardSerialNumber' | awk -F ':' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
	Output_Lower_SN=$(./nvflash_mfg -B $port2  --rdobd | grep -m 1 'BoardSerialNumber' | awk -F ':' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
	if [ -z ${Output_Upper_SN} ] && [ -z ${Output_Lower_SN} ]; then
		show_fail_msg "Read SN error Please check!!!"
		exit 1
	else
		show_pass_message "######SerialNumber1:$Output_Upper_SN######"
		show_pass_message "######SerialNumber2:$Output_Lower_SN######" 
		show_pass_msg "Read SN OK"
		testqty="2"
	fi
elif [ $counts = "1" ]; then
	Output_Upper_SN=$(./nvflash_mfg --rdobd | grep -m 1 'BoardSerialNumber' | awk -F ':' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
	if [ -z ${Output_Upper_SN} ]; then
		show_fail_msg "Read SN error Please check!!!"
		exit 1
	else
		show_pass_message "######SerialNumber1:$Output_Upper_SN######"
		show_pass_msg "Read SN OK"
		testqty="1"	
	fi
else
	show_fail_message "Can't Detect Cards Please Inserd one Card"
	show_fail_msg "Read SN FAIL"
	exit 1 	
	
fi

	
	 
}
#####download diag from diagserver#####################################
DownLoad()
{

#####Prepare diag######
cd $mods 
ls | grep -v cfg | xargs rm -fr
if [ -d ${Diag_Path}/${MACHINE}/${diag_name} ]; then
#if [ -d ${Diag_Path}/${Input_Upper_PN}/${diag_name} ]; then
	show_pass_message "DownLoad Diag From Server Please Waiting ..."
	#echo "${diag_VER}"
	#pause
	#cp -rf ${Diag_Path}/${Input_Upper_PN}/${diag_name}/* $mods
	cp -rf ${Diag_Path}/${MACHINE}/${diag_name}/* $mods
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
		cp -rf ${Diag_Path}/${MACHINE}/${diag_name}/* $mods
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
#####Prepare HEAVEN#####
if [ ! $HEAVEN_VER = "NA" ];then	
	if [ -f $HEAVEN/$HEAVEN_VER ];then
		show_pass_message "DownLoad HEAVEN From Local Please Waiting ..."
		cp -rf $HEAVEN/$HEAVEN_VER $mods/core/mods0
		cd $mods/core/mods0
		tar -xf $HEAVEN_VER 
		if [ $? -ne 0 ];then
			show_fail_message "Please make sure exist HEAVEN zip files"
			show_fail_msg "DownLoad HEAVEN FAIL"
			exit 1
		fi		
	else
		#echo "${Diag_Path}/HEAVEN/$HEAVEN_VER"
		#pause
		if [ -f ${Diag_Path}/HEAVEN/$HEAVEN_VER ]; then
			show_pass_message "DownLoad HEAVEN From Server Please Waiting ..."
			cp -rf ${Diag_Path}/HEAVEN/$HEAVEN_VER $HEAVEN
			cp -rf $HEAVEN/$HEAVEN_VER $mods/core/mods0
			cd $mods/core/mods0
			tar -xf $HEAVEN_VER 
			if [ $? -ne 0 ];then
				show_fail_message "Please make sure exist HEAVEN zip files"
				show_fail_msg "DownLoad HEAVEN FAIL"
				exit 1
			fi		
		else
			Input_Server_Connection
			if [ -f ${Diag_Path}/HEAVEN/$HEAVEN_VER ]; then
				show_pass_message "DownLoad HEAVEN From Server Please Waiting ..."
				cp -rf ${Diag_Path}/HEAVEN/$HEAVEN_VER $HEAVEN
				cp -rf $HEAVEN/$HEAVEN_VER $mods/core/mods0
				cd $mods/core/mods0
				tar -xf $HEAVEN_VER 
				if [ $? -ne 0 ];then
					show_fail_message "Please make sure exist HEAVEN zip files"
					show_fail_msg "DownLoad HEAVEN FAIL"
					exit 1
				fi		
			else
				show_fail_message "HEAVEN isn't exist Please Call TE"
				show_fail_msg "DownLoad HEAVEN FAIL"
				exit 1 
			fi
		fi
	fi
fi	
	
####PG520 Prepare DFX files#####
# if [ "$MACHINE" = "G520" ] && [ "$current_stc_name" != "CHIFLASH" ];then ####for clear BBX station### 2024-04-26
	# DFX=$(get_config "Diag3")
	# if [ -f $HEAVEN/$DFX ];then
		# show_pass_message "DownLoad DFX From Local Please Waiting ..."
		# cp -rf $HEAVEN/$DFX $mods/core/mods0
		# cd $mods/core/mods0
		# tar -xf $DFX 
		# if [ $? -ne 0 ];then
			# show_fail_message "Please make sure exist DFX zip files"
			# show_fail_msg "DownLoad DFX FAIL"
			# exit 1
		# fi		
	# else
		# #echo "${Diag_Path}/HEAVEN/$HEAVEN_VER"
		# #pause
		# if [ -f ${Diag_Path}/HEAVEN/$DFX ]; then
			# show_pass_message "DownLoad DFX From Server Please Waiting ..."
			# cp -rf ${Diag_Path}/HEAVEN/$DFX $HEAVEN
			# cp -rf $HEAVEN/$DFX $mods/core/mods0
			# cd $mods/core/mods0
			# tar -xf $DFX 
			# if [ $? -ne 0 ];then
				# show_fail_message "Please make sure exist DFX zip files"
				# show_fail_msg "DownLoad DFX FAIL"
				# exit 1
			# fi		
		# else
			# Input_Server_Connection
			# if [ -f ${Diag_Path}/HEAVEN/$DFX ]; then
				# show_pass_message "DownLoad DFX From Server Please Waiting ..."
				# cp -rf ${Diag_Path}/HEAVEN/$DFX $HEAVEN
				# cp -rf $HEAVEN/$DFX $mods/core/mods0
				# cd $mods/core/mods0
				# tar -xf $DFX 
				# if [ $? -ne 0 ];then
					# show_fail_message "Please make sure exist DFX zip files"
					# show_fail_msg "DownLoad DFX FAIL"
					# exit 1
				# fi		
			# else
				# show_fail_message "DFX isn't exist Please Call TE"
				# show_fail_msg "DownLoad DFX FAIL"
				# exit 1 
			# fi
		# fi
	# fi
# fi	

####Prepare BIOS####
if [ -f ${Diag_Path}/${MACHINE}/BIOS/${BIOS_NAME} ]; then
	cp -rf ${Diag_Path}/${MACHINE}/BIOS/${BIOS_NAME} $mods
	show_pass_msg "Diag download OK"
else
	Input_Server_Connection
	if [ -f ${Diag_Path}/${MACHINE}/BIOS/${BIOS_NAME} ]; then
		cp -rf ${Diag_Path}/${MACHINE}/BIOS/${BIOS_NAME} $mods
		show_pass_msg "Diag download OK"
	else
		show_fail_message "Please make sure $BIOS_NAME is exsit!!!"
		show_fail_msg "Diag download OK"
		exit 1
	fi
fi

}
#####run diag#########################################################
Run_Diag()
{
if [ $Run_Mode = "0" ];then ###2024-06-15
	cd $mods
	if [ $testqty = "2" ];then	
		Output_Wareconn_Serial_Number_RestAPI_Mode_Start  ${Scan_Upper_SN} ${Input_Upper_Status}
		Output_Wareconn_Serial_Number_RestAPI_Mode_Start  ${Scan_Lower_SN} ${Input_Lower_Status}
	else
		Output_Wareconn_Serial_Number_RestAPI_Mode_Start  ${Scan_Upper_SN} ${Input_Upper_Status}
	fi	
	# if [ ${current_stc_name} = "FT" ];then
		# test_item="inforcheck bioscheck BAT BIT FCT FPF"
		# run_command "$test_item"
		# if [ $? -eq 0 ];then
			# if [ $testqty = "2" ];then
				# resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_FPF*" 2>/dev/null)
				# resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_FPF*" 2>/dev/null)		
				# if [ -n "$resf" ] && [ -n "$resc" ];then
					# Upload_Log ${Scan_Upper_SN} PASS 
					# Upload_Log ${Scan_Lower_SN} PASS
					# show_pass
					# sleep 20
					# reboot
				# elif [ -n "$resf" ] ; then
					# Upload_Log ${Scan_Upper_SN} PASS 
					# show_pass
					# sleep 20
					# reboot
				# else
					# Upload_Log ${Scan_Lower_SN} PASS
					# show_pass
					# sleep 20
					# reboot
				# fi			
			# else
				# Upload_Log ${Scan_Upper_SN} PASS 
				# show_pass
				# sleep 20
				# reboot
			# fi	
		# else
			# if [ $testqty = "2" ];then
				# Upload_Log ${Scan_Upper_SN} FAIL 
				# Upload_Log ${Scan_Lower_SN} FAIL 
				# show_fail
			# else
				# Upload_Log ${Scan_Upper_SN} FAIL 
				# show_fail
			# fi	
		# fi
	if [ ${current_stc_name} = "FLA" ];then
		test_item="rwcsv FLA bioscheck"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			show_pass
			show_pass_message "FLA station need poweroff and turn off/on 54v PSU as well"	
		else
			Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			show_fail ${Scan_Upper_SN} ${FactoryErrorCode} ${FactoryErrorMsg} 		
		fi
	elif [ ${current_stc_name} = "FLA2" ];then
		test_item="rwcsv FLA2"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			show_pass
			show_pass_message "FLA2 station need poweroff and turn off/on 54v PSU as well"	
		else
			Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			show_fail ${Scan_Upper_SN} ${FactoryErrorCode} ${FactoryErrorMsg}			
		fi	
	elif [ ${current_stc_name} = "FLB" ];then
		test_item="rwcsv FLB"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			show_pass
			if [ "$MACHINE" = "G520" ];then
				sleep 10
				reboot
			else	
				show_pass_message "FLB station need poweroff and turn off/on 54v PSU as well"
			fi		
		else
			Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			show_fail ${Scan_Upper_SN} ${FactoryErrorCode} ${FactoryErrorMsg}	
		fi
	elif [ ${current_stc_name} = "FLC" ];then
		test_item="rwcsv FLC"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			show_pass
			show_pass_message "FLC station need poweroff and turn off/on 54v PSU as well"	
		else
			Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			show_fail ${Scan_Upper_SN} ${FactoryErrorCode} ${FactoryErrorMsg}	
		fi
	elif [ ${current_stc_name} = "CHIFLASH" ];then
		test_item="rwcsv CHIFLASH"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			show_pass
			sleep 10
			reboot	
		else
			Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			show_fail ${Scan_Upper_SN} ${FactoryErrorCode} ${FactoryErrorMsg}	
		fi		
	elif [ ${current_stc_name} = ${Tstation} ];then ####for clear BBX station### 2024-04-26
		test_item="inforcheck bioscheck ${current_stc_name}"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${current_stc_name}*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${current_stc_name}*" 2>/dev/null)
				if [ -n "$resf" ] && [ -n "$resc" ];then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					show_pass
					if [ "$cont" = "true" ];then
						sleep 10
						reboot
					fi
						
				elif [ -n "$resf" ] ; then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					show_pass
					if [ "$cont" = "true" ];then
						sleep 10
						reboot
					fi
				else
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					show_pass
					if [ "$cont" = "true" ];then
						sleep 10
						reboot
					fi
				fi	
			else
				Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
				show_pass
				if [ "$cont" = "true" ];then
					sleep 10
					reboot
				fi
			fi	
		else
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${current_stc_name}*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${current_stc_name}*" 2>/dev/null)
				if [ -n "$resf" ];then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					Upload_Log ${Scan_Lower_SN} FAIL ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					show_fail ${Scan_Lower_SN} ${FactoryErrorCode} ${FactoryErrorMsg}
				elif [ -n "$resc" ];then	
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					show_fail ${Scan_Upper_SN} ${FactoryErrorCode} ${FactoryErrorMsg}
				else
					Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					show_fail ${Scan_Upper_SN} ${FactoryErrorCode} ${FactoryErrorMsg}
					Upload_Log ${Scan_Lower_SN} FAIL ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					show_fail ${Scan_Lower_SN} ${FactoryErrorCode} ${FactoryErrorMsg}
				fi		
			else
				Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
				show_fail ${Scan_Upper_SN} ${FactoryErrorCode} ${FactoryErrorMsg}
			fi	
		fi
	else
		test_item="inforcheck bioscheck ${current_stc_name}"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${Tstation}*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${Tstation}*" 2>/dev/null)
				if [ -n "$resf" ] && [ -n "$resc" ];then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					show_pass
					if [ "$cont" = "true" ];then
						sleep 10
						reboot
					fi
				elif [ -n "$resf" ] ; then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					show_pass
					if [ "$cont" = "true" ];then
						sleep 10
						reboot
					fi
				else
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					show_pass
					if [ "$cont" = "true" ];then
						sleep 10
						reboot
					fi
				fi	
			else
				Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
				show_pass
				if [ "$cont" = "true" ];then
					sleep 10
					reboot
				fi
			fi	
		else
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${Tstation}*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${Tstation}*" 2>/dev/null)
				if [ -n "$resf" ];then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					Upload_Log ${Scan_Lower_SN} FAIL ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					show_fail ${Scan_Lower_SN} ${FactoryErrorCode} ${FactoryErrorMsg}
				elif [ -n "$resc" ];then	
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					show_fail ${Scan_Upper_SN} ${FactoryErrorCode} ${FactoryErrorMsg}
				else
					Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					show_fail ${Scan_Upper_SN} ${FactoryErrorCode} ${FactoryErrorMsg}
					Upload_Log ${Scan_Lower_SN} FAIL ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					show_fail ${Scan_Lower_SN} ${FactoryErrorCode} ${FactoryErrorMsg}
				fi		
			else
				Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
				show_fail ${Scan_Upper_SN} ${FactoryErrorCode} ${FactoryErrorMsg}
			fi	
		fi	
	fi
else
	cd $mods
	if [ $station = "CHIFLASH" ] || [ $station = "FLA2" ];then
		Tstation="FLA"
	elif [ $station = "IST2" ];then
		Tstation="IST"
	else
		Tstation=$current_stc_name
	fi	
	if [ ${station} = "FT" ];then
		test_item="BAT BIT FCT FPF"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_FPF*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_FPF*" 2>/dev/null)		
				if [ -n "$resf" ] && [ -n "$resc" ];then
					Upload_Log ${Scan_Upper_SN} PASS
					Upload_Log ${Scan_Lower_SN} PASS
					# show_pass
					# #sleep 20
					# #reboot
				elif [ -n "$resf" ] ; then
					Upload_Log ${Scan_Upper_SN} PASS
					# # show_pass
					# #sleep 20
					# #reboot
				else
					Upload_Log ${Scan_Lower_SN} PASS
					# show_pass
					# #sleep 20
					# #reboot
				fi			
			else
				Upload_Log ${Scan_Upper_SN} PASS
				# show_pass
				# #sleep 20
				# #reboot
			fi	
		else
			if [ $testqty = "2" ];then
				Upload_Log ${Scan_Upper_SN} FAIL
				Upload_Log ${Scan_Lower_SN} FAIL
				# show_fail
			else
				Upload_Log ${Scan_Upper_SN} FAIL
				# show_fail
			fi	
		fi
	elif [ ${station} = "FLA" ];then
		test_item="rwcsv FLA"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			# show_pass
			# show_pass_message "FLA station need poweroff and turn off/on 54v PSU as well"	
		else
			Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			# show_fail			
		fi
	elif [ ${station} = "FLA2" ];then
		test_item="rwcsv FLA2"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			# show_pass
			# show_pass_message "FLA station need poweroff and turn off/on 54v PSU as well"	
		else
			Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			# show_fail			
		fi		
	elif [ ${station} = "FLB" ];then
		test_item="rwcsv FLB"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			# show_pass
			# show_pass_message "FLB station need poweroff and turn off/on 54v PSU as well"	
		else
			Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			# show_fail	
		fi
	elif [ ${station} = "FLC" ];then
		test_item="rwcsv FLC"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			# show_pass
			# show_pass_message "FLC station need poweroff and turn off/on 54v PSU as well"	
		else
			Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
			# show_fail	
		fi		
	elif [ ${station} = "CHIFLASH" ];then ####for clear BBX station### 2024-04-26
		test_item="rwcsv CHIFLASH"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
		else
			Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
		fi
	elif [ ${station} = ${Tstation} ];then
		test_item="${station}"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${station}*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${station}*" 2>/dev/null)
				if [ -n "$resf" ] && [ -n "$resc" ];then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					# show_pass
					# #sleep 20
					# #reboot
				elif [ -n "$resf" ] ; then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					# show_pass
					# #sleep 20
					# #reboot
				else
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					# show_pass
					# #sleep 20
					# #reboot
				fi	
			else
				Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
				# show_pass
				# #sleep 20
				# #reboot
			fi	
		else
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${station}*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${station}*" 2>/dev/null)
				if [ -n "$resf" ];then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					Upload_Log ${Scan_Lower_SN} FAIL ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					# show_fail
				elif [ -n "$resc" ];then	
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					# show_fail
				else
					Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					Upload_Log ${Scan_Lower_SN} FAIL ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					# show_fail
				fi		
			else
				Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
				# show_fail
			fi	
		fi
	else
		test_item="${station}"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${Tstation}*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${Tstation}*" 2>/dev/null)
				if [ -n "$resf" ] && [ -n "$resc" ];then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					# show_pass
					# #sleep 20
					# #reboot
				elif [ -n "$resf" ] ; then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					# show_pass
					# #sleep 20
					# #reboot
				else
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					# show_pass
					# #sleep 20
					# #reboot
				fi	
			else
				Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
				# show_pass
				# #sleep 20
				# #reboot
			fi	
		else
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${Tstation}*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${Tstation}*" 2>/dev/null)
				if [ -n "$resf" ];then
					Upload_Log ${Scan_Upper_SN} PASS ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					Upload_Log ${Scan_Lower_SN} FAIL ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					# show_fail
				elif [ -n "$resc" ];then	
					Upload_Log ${Scan_Lower_SN} PASS ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					# show_fail
				else
					Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
					Upload_Log ${Scan_Lower_SN} FAIL ${Input_Lower_Eboard} ${Input_Lower_ESN} ${Input_Lower_HSC}
					# show_fail
				fi		
			else
				Upload_Log ${Scan_Upper_SN} FAIL ${Input_Upper_Eboard} ${Input_Upper_ESN} ${Input_Upper_HSC}
				# show_fail
			fi	
		fi	
		
	fi
fi	
	
#run_command ${current_stc_name}

#./$mods/"${current_stc_name}".sh


}
####upload log to logserver###########################################
Upload_Log()
{
if [ $testqty = 2 ]; then
	Final_status="DUAL Board Final status"
else
	Final_status="Final status"
fi

if [ "$Run_Mode" != "0" ];then
	current_stc_name=$station	
fi	

end_time=`date +"%Y%m%d_%H%M%S"`
EndTesttime=`date +"%Y%m%d%H%M%S"`
filename=$1_"${current_stc_name}"_"$end_time"_$2.log
analysis_log $1 $2 $3 $4 $5

cd $LOGFILE
echo "${PROJECT} L5 Functional Test" >"${filename}"
echo "${diag_name} (config version: ${CFG_VERSION})" >>"${filename}"
echo "============================================================================" >>"${filename}"
echo "Start time              :$start_time" >>"${filename}"
echo "End time                :$(date '+%F %T')" >>"${filename}"
echo "Part number             :${Input_Upper_PN}" >>"${filename}"
echo "Serial number           :${1}" >>"${filename}"
echo "operator_id             :`grep "operator_id=" $SCANFILE |sed 's/.*= *//'`" >>"${filename}"
echo "fixture_id              :`grep "fixture_id=" $SCANFILE |sed 's/.*= *//'`" >>"${filename}"
echo "VBIOS                   :$BIOS_VER" >> "${filename}"
echo "FactoryErrorCode        :$FactoryErrorCode" >> "${filename}"
echo "FactoryErrorMsg         :$FactoryErrorMsg" >> "${filename}"
echo " " >>"${filename}"
echo "============================================================================" >>"${filename}"
echo "$Final_status: ${2}" >> "${filename}"
echo "****************************************************************************" >>"${filename}"
echo "FUNCTIONAL TESTING" >>"${filename}"
echo "****************************************************************************" >>"${filename}"

cat $LOGFILE/log.txt | tr -d "\000" >>"${filename}"

## upload test log to log server
if [ -d ${Logs_Path}/$PROJECT ]; then
	[ ! -d ${Logs_Path}/$PROJECT/${Input_Upper_PN} ] && mkdir ${Logs_Path}/$PROJECT/${Input_Upper_PN}
	cp -rf *$1* ${Logs_Path}/$PROJECT/${Input_Upper_PN}
	cp -rf *$1* ${Local_Logs}
	rm -rf *$1*	
else
	Input_Server_Connection
	if [ -d ${Logs_Path}/$PROJECT ]; then
		[ ! -d ${Logs_Path}/$PROJECT/${Input_Upper_PN} ] && mkdir ${Logs_Path}/$PROJECT/${Input_Upper_PN}
		cp -rf *$1* ${Logs_Path}/$PROJECT/${Input_Upper_PN}
		cp -rf *$1* ${Local_Logs}
		rm -rf *$1*
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

run_command()
{
    for m in $1; do
        echo $m | grep -i "untest" > /dev/null 2>&1
        [ $? -eq 0 ] && continue

        echo -e "\033[32m Begin $m module Test\033[0m"
        echo " " | tee -a $LOGFILE/log.txt
        date +"<Info message>: $m - start time: %F %T" | tee -a $LOGFILE/log.txt 
        cd $mods
        ./$m.sh 
        if [ $? -ne 0 ]; then
            echo "$m module Test ------------ [ FAIL ]" | tee -a $LOGFILE/log.txt
            color "$m module test" FAIL
            date +"<Info message>: $m - end time: %F %T" | tee -a $LOGFILE/log.txt
			Fail_Module=$m
            echo " "
            echo " " | tee -a $LOGFILE/log.txt 
            return 1
        else
            echo "$m module Test ----------- [ PASS ]" | tee -a $LOGFILE/log.txt
            color "$m module test" PASS
            date +"<Info message>: $m - end time: %F %T" | tee -a $LOGFILE/log.txt 
            echo " "
            echo " " | tee -a $LOGFILE/log.txt
        fi
    done
	
}

get_information()
{
MACHINE=$(get_config "MACHINE")
Input_Upper_PN=$(get_config "900PN")
current_stc_name=$(get_config "current_stc_name")
NVFLASH_VER=$(get_config "NVFLAH_VER")
NVINFOROM=$(get_config "NVINFOROM")
HEAVEN_VER=$(get_config "HEAVEN")
BIOS_NAME=$(get_config "BIOS1_NAME")
BIOS_VER=$(get_config "BIOS1_VER")
Input_Script=$(get_config "SCRIPT_VER")
operator_id="`grep "operator_id=" $SCANFILE |sed 's/.*= *//'`"
fixture_id="`grep "fixture_id=" $SCANFILE |sed 's/.*= *//'`"

if [ $current_stc_name = "CHIFLASH" ] || [ $current_stc_name = "FLA2" ];then
	Tstation="FLA"
elif [ $current_stc_name = "IST2" ];then
	Tstation="IST"
else
	Tstation=$current_stc_name
fi
	
}

analysis_sta()
{
if [ $Run_Mode = "0" ];then #### 2024-06-15

	cd $mods/cfg/
	cp  ${Output_Upper_SN}.RSP cfg.ini
	get_information
	script_check
	if [ "$current_stc_name" = "OQA" ] ; then 
		diag_name=$(get_config "Diag2")
		diag_VER=$diag_name.tar.gz
		if [ -f $mods/$diag_VER ]; then
			Run_Diag
		else
			DownLoad
			Run_Diag			
		fi
		
	elif [ "$current_stc_name" = "CHIFLASH" ];then ###for clear BBX station## 2024-04-26
		diag_name=$(get_config "Diag3")
		diag_VER=$diag_name.tar.gz
		#echo $diag_VER
		#pause
		if [ -f $mods/$diag_VER ]; then
			Run_Diag
		else
			DownLoad
			Run_Diag
		
		fi
		
	elif [[ "$list_st" =~ "$current_stc_name" ]];then
		diag_name=$(get_config "Diag1")
		diag_VER=$diag_name.tar.gz
		#echo $diag_VER
		#pause
		if [ -f $mods/$diag_VER ]; then
			Run_Diag
		else
			DownLoad
			Run_Diag
		
		fi
	elif [[ "$list_stn" =~ "$current_stc_name" ]]; then
		cont="false"
		show_fail_message "Current Station is $current_stc_name, need more spare parts Please check!!!"
		pause
		diag_name=$(get_config "Diag1")
		diag_VER=$diag_name.tar.gz
		if [ -f $mods/$diag_VER ]; then
			Run_Diag
		else
			DownLoad
			Run_Diag
		fi	
	else
		show_fail_message "Current Station is $current_stc_name not test station"
		exit 1 
		
	fi
else
	cd $mods/cfg/
	cp  ${Output_Upper_SN}.RSP cfg.ini
	get_information
	script_check
	#read -p "Please Input station :" station
	#echo $station
	#pause
	#if [[ "$list_st_all" =~ "$station" ]];then
		if [ $station = "OQA" ];then
			diag_name=$(get_config "Diag2")
			diag_VER=$diag_name.tar.gz
			if [ ! -f $mods/$diag_VER ];then
				DownLoad
				Run_Diag
			else
				Run_Diag
			fi
		elif [ $station = "CHIFLASH" ];then
			diag_name=$(get_config "Diag3")
			diag_VER=$diag_name.tar.gz
			if [ ! -f $mods/$diag_VER ];then
				DownLoad
				Run_Diag
			else
				Run_Diag
			fi
		else
			diag_name=$(get_config "Diag1")
			diag_VER=$diag_name.tar.gz
			if [ ! -f $mods/$diag_VER ];then
				DownLoad
				Run_Diag
			else
				Run_Diag
			fi
		fi
	#else
		#show_fail_message "station wrong please check!!!"
		#exit 1
	#fi	
fi		

}

upload_start_log()
{
    start_log_time=`date +"%Y%m%d_%H%M%S"`
	StartTestTime=`date +"%Y%m%d%H%M%S"`
    filename="$1"_"${current_stc_name}"_"$start_log_time"_"START".log
    
	cd $LOGFILE
    echo "${PROJECT} L5 Functional Test" >"${filename}"
    echo "${diag_name} (config version: ${CFG_VERSION})" >>"${filename}"
    echo "============================================================================" >>"${filename}"
    echo "Start time              :$start_time" >>"${filename}"
    echo "Part number             :${Input_Upper_PN}" >>"${filename}"
    echo "Serial number           :${1}" >>"${filename}"
    echo "operator_id             :`grep "operator_id=" $SCANFILE |sed 's/.*= *//'`" >>"${filename}"
    echo "fixture_id              :`grep "fixture_id=" $SCANFILE |sed 's/.*= *//'`" >>"${filename}"

    ## upload test log to log server
	if [ -d ${Logs_Path}/$PROJECT ]; then
		[ ! -d ${Logs_Path}/$PROJECT/${Input_Upper_PN} ] && mkdir ${Logs_Path}/$PROJECT/${Input_Upper_PN}
		cp -rf *$1* ${Logs_Path}/$PROJECT/${Input_Upper_PN}
		cp -rf *$1* ${Local_Logs}
		rm -rf *$1*	
	else
		Input_Server_Connection
		if [ -d ${Logs_Path}/$PROJECT ]; then
			[ ! -d ${Logs_Path}/$PROJECT/${Input_Upper_PN} ] && mkdir ${Logs_Path}/$PROJECT/${Input_Upper_PN}
			cp -rf *$1* ${Logs_Path}/$PROJECT/${Input_Upper_PN}
			cp -rf *$1* ${Local_Logs}
			rm -rf *$1* 
		else
			show_fail_message "show_fail_message Mounting log server fail."
			exit 1 
		fi	
		
	fi	

}

#####wareconn control script version##################################################################
script_check()
{

	if [ "${Script_VER}" = "${Input_Script}" ];then
		echo "Script Version is ${Script_VER}"
	else
		echo "Script Version is ${Script_VER}"
		if [ -f ${Diag_Path}/${Input_Script}_${Script_File} ];then
			cp -rf ${Diag_Path}/${Input_Script}_${Script_File} /mnt/nv/$Script_File
			sleep 15
			reboot
		else
			Input_Server_Connection
			if [ -f ${Diag_Path}/${Input_Script}_${Script_File} ];then
				cp -rf ${Diag_Path}/${Input_Script}_${Script_File} /mnt/nv/$Script_File
				sleep 15
				reboot
			else
				show_fail_msg "not exsit script please check"
				exit 1
			fi
		fi		
	fi	


}

######################################################################################################


analysis_log()
{
FactoryErrorCode=""
FactoryErrorMsg=""

cd $LOGFILE

if [ $current_stc_name = $Tstation ];then
	LogName=$(find $LOGFILE/ -name "*$1_*_${current_stc_name}*.tsg" 2>/dev/null)
	if [ -n "$LogName" ];then
		if [ "$2" = "PASS" ];then
			FactoryErrorCode="0"
		else	
			FactoryErrorCode=$(jq -r '.[] | select(.tag == "FactoryErrorCode") | .value' "$LogName")
		fi	
		FactoryErrorMsg=$(jq -r '.[] | select(.tag == "FactoryErrorMsg") | .value' "$LogName")
		HOST_MAC_ADDR=$(jq -r '.[] | select(.tag == "HOST_MAC_ADDR") | .value' "$LogName")
		PORT_ADDRESS=$(jq -r '.[] | select(.tag == "PORT_ADDRESS") | .value' "$LogName")
		Bin=$(jq -r '.[] | select(.tag == "Bin") | .value' "$LogName")
		#VBIOS_VERSION=$(jq -r '.[] | select(.tag == "VBIOS_VERSION") | .value' "$LogName")
		name=$(find -name "*$1*" -type d)
		filenames=$(basename $name)
		outputfile=$(find $filenames -name "output.txt" )
		tasfile=$(find $filenames -name "tas.txt")
		FAN_RPM_2_6_3_4=$(grep -m 1 "FAN_RPM/2/6/3/4" $tasfile | awk -F '|' '{print$2}')
		Inlet_Temp=$(grep -m 1 "Inlet_Temp" $tasfile | awk -F '|' '{print$2}')
		if [ "$FAN_RPM_2_6_3_4" = "" ];then
			FAN_RPM_2_6_3_4="NA"
		fi
		if [ "$Inlet_Temp" = "" ];then
			Inlet_Temp="NA"
		fi	
		outputpath=$(pwd)/$outputfile
		cat $tasfile > $filenames.log
		echo "" >> $filenames.log
		echo ""  >> $filenames.log
		echo "file:$outputpath" >> $filenames.log
		echo ""  >> $filenames.log
		cat $outputfile >> $filenames.log
		echo ""  >> $filenames.log
		echo ""  >> $filenames.log
		
		echo "$3:$4" >> $filenames.log ##from wareconn
		echo "" >> $filenames.log
		echo "Factory Information" >> $filenames.log
		echo "Monitor SN:" >> $filenames.log ##??
		echo "HardDisk SN:" >> $filenames.log ##??
		echo "HardDisk Health:N/A" >> $filenames.log
		echo "Power-On Time Count:" >> $filenames.log ##??
		echo "Drive Power Cycle Count:" >> $filenames.log ##??
		echo "CPUID:`dmidecode -t 4 | grep "ID" | awk -F ':' '{print $2}'`" >> $filenames.log 
		echo "Brand String: `dmidecode -t 4 | grep "Version" | awk -F ':' '{print $2}'` " >> $filenames.log 
		echo "Mac Address:$HOST_MAC_ADDR" >> $filenames.log ##from tsg log
		echo "DiagVer:${diag_name}" >> $filenames.log
		echo "PCIE Riser Card ID:NONE" >> $filenames.log ##??
		echo "BrdSN:$1" >> $filenames.log
		echo "FLAT ID:`grep "fixture_id=" $SCANFILE |sed 's/.*= *//'`" >> $filenames.log
		echo "Routing:${current_stc_name}" >> $filenames.log
		echo "FOX_Routing:${current_stc_name}" >> $filenames.log
		echo "PN:${Input_Upper_PN}" >> $filenames.log
		echo "BIOS:$BIOS_VER" >> $filenames.log
		echo "BIN:$Bin" >> $filenames.log ##??
		echo "Error Code:$FactoryErrorCode" >> $filenames.log ##use factory error code 
		echo "StartTestTime:$StartTestTime" >> $filenames.log
		echo "EndTesttime:$EndTesttime" >> $filenames.log
		echo "Operator:`grep "operator_id=" $SCANFILE |sed 's/.*= *//'`" >> $filenames.log
		echo "System Ver:`cat /etc/centos-release`" >> $filenames.log 
		echo "SFC:YES" >> $filenames.log
		echo "PortWell-B SN:`dmidecode -t 1 | grep "Serial Number" | awk -F ':' '{print $2}'`" >> $filenames.log ##ipmitool 
		echo "Hotplug Status:YES" >> $filenames.log ##TJ all testers enable Hotplug
		echo "0SN_From_SCAN,,relates_slots,$PORT_ADDRESS" >> $filenames.log ##from tsg log
		echo "0SN_From_SCAN,,relates_slots,$PORT_ADDRESS" >> $filenames.log ##from tsg log
		echo "QR_CODE: N/A" >> $filenames.log ##??
		echo "HS_QR_CODE:$5" >> $filenames.log ##??
		echo "FAN_RPM_2_6_3_4:$FAN_RPM_2_6_3_4" >> $filenames.log
		echo "Inlet_Temp:$Inlet_Temp" >> $filenames.log
		echo "" >> $filenames.log
		echo "" >> $filenames.log
		echo "****END****" >> $filenames.log
	else
		show_fail_message "Can't find the analysis Log"
	fi	
else
		
	LogName=$(find $LOGFILE/ -name "*$1_*_${Tstation}*.tsg" 2>/dev/null)
	if [ -n "$LogName" ];then
		if [ "$2" = "PASS" ];then
			FactoryErrorCode="0"
		else	
			FactoryErrorCode=$(jq -r '.[] | select(.tag == "FactoryErrorCode") | .value' "$LogName")
		fi	
		FactoryErrorMsg=$(jq -r '.[] | select(.tag == "FactoryErrorMsg") | .value' "$LogName")
		HOST_MAC_ADDR=$(jq -r '.[] | select(.tag == "HOST_MAC_ADDR") | .value' "$LogName")
		PORT_ADDRESS=$(jq -r '.[] | select(.tag == "PORT_ADDRESS") | .value' "$LogName")
		Bin=$(jq -r '.[] | select(.tag == "Bin") | .value' "$LogName")
		#VBIOS_VERSION=$(jq -r '.[] | select(.tag == "VBIOS_VERSION") | .value' "$LogName")
		name=$(find -name "*$1*" -type d)
		filenames=$(basename $name)
		outputfile=$(find $filenames -name "output.txt" )
		tasfile=$(find $filenames -name "tas.txt")
		FAN_RPM_2_6_3_4=$(grep -m 1 "FAN_RPM/2/6/3/4" $tasfile | awk -F '|' '{print$2}')
		Inlet_Temp=$(grep -m 1 "Inlet_Temp" $tasfile | awk -F '|' '{print$2}')
		if [ "$FAN_RPM_2_6_3_4" = "" ];then
			FAN_RPM_2_6_3_4="NA"
		fi
		if [ "$Inlet_Temp" = "" ];then
			Inlet_Temp="NA"
		fi
		outputpath=$(pwd)/$outputfile
		cat $tasfile > $filenames.log
		echo "" >> $filenames.log
		echo ""  >> $filenames.log
		echo "file:$outputpath" >> $filenames.log
		echo ""  >> $filenames.log
		cat $outputfile >> $filenames.log
		echo ""  >> $filenames.log
		echo ""  >> $filenames.log
		
		echo "$3:$4" >> $filenames.log ##from wareconn
		echo "" >> $filenames.log
		echo "Factory Information" >> $filenames.log
		echo "Monitor SN:" >> $filenames.log ##??
		echo "HardDisk SN:" >> $filenames.log ##??
		echo "HardDisk Health:N/A" >> $filenames.log
		echo "Power-On Time Count:" >> $filenames.log ##??
		echo "Drive Power Cycle Count:" >> $filenames.log ##??
		echo "CPUID:`dmidecode -t 4 | grep "ID" | awk -F ':' '{print $2}'`" >> $filenames.log 
		echo "Brand String: `dmidecode -t 4 | grep "Version" | awk -F ':' '{print $2}'` " >> $filenames.log 
		echo "Mac Address:$HOST_MAC_ADDR" >> $filenames.log ##from tsg log
		echo "DiagVer:${diag_name}" >> $filenames.log
		echo "PCIE Riser Card ID:NONE" >> $filenames.log ##??
		echo "BrdSN:$1" >> $filenames.log
		echo "FLAT ID:`grep "fixture_id=" $SCANFILE |sed 's/.*= *//'`" >> $filenames.log
		echo "Routing:${current_stc_name}" >> $filenames.log
		echo "FOX_Routing:${current_stc_name}" >> $filenames.log
		echo "PN:${Input_Upper_PN}" >> $filenames.log
		echo "BIOS:$BIOS_VER" >> $filenames.log
		echo "BIN:$Bin" >> $filenames.log ##??
		echo "Error Code:$FactoryErrorCode" >> $filenames.log ##use factory error code 
		echo "StartTestTime:$StartTestTime" >> $filenames.log
		echo "EndTesttime:$EndTesttime" >> $filenames.log
		echo "Operator:`grep "operator_id=" $SCANFILE |sed 's/.*= *//'`" >> $filenames.log
		echo "System Ver:`cat /etc/centos-release`" >> $filenames.log 
		echo "SFC:YES" >> $filenames.log
		echo "PortWell-B SN:`dmidecode -t 1 | grep "Serial Number" | awk -F ':' '{print $2}'`" >> $filenames.log ##ipmitool 
		echo "Hotplug Status:YES" >> $filenames.log ##TJ all testers enable Hotplug
		echo "0SN_From_SCAN,,relates_slots,$PORT_ADDRESS" >> $filenames.log ##from tsg log
		echo "0SN_From_SCAN,,relates_slots,$PORT_ADDRESS" >> $filenames.log ##from tsg log
		echo "QR_CODE: N/A" >> $filenames.log ##??
		echo "HS_QR_CODE:$5" >> $filenames.log ##??
		echo "FAN_RPM_2_6_3_4:$FAN_RPM_2_6_3_4" >> $filenames.log
		echo "Inlet_Temp:$Inlet_Temp" >> $filenames.log		
		echo "" >> $filenames.log
		echo "" >> $filenames.log
		echo "****END****" >> $filenames.log
	
	else
		show_fail_message "Can't find the analysis Log"
	fi
fi	


}

####install tool########################################################################################
update()
{

####ntpdate install###
if [ ! -f /usr/sbin/ntpdate ];then
	if [ -f $Diag_Path/updates/ntpdate-4.2.6p5-28.el7.centos.x86_64.rpm ];then
		cp $Diag_Path/updates/ntpdate-4.2.6p5-28.el7.centos.x86_64.rpm $mods
		rpm -Uvh $mods/ntpdate-4.2.6p5-28.el7.centos.x86_64.rpm
	else
		show_fail_message "update files ntpdate not exist !!!"
		exit 1
	fi	
fi

####jq install####
		
if [ ! -f /usr/bin/jq ];then
	if [ -f $Diag_Path/updates/jq ];then
		cp $Diag_Path/updates/jq /usr/bin
	else
		show_fail_message "update files ntpdate not exist !!!"
		exit 1
	fi	
fi
}


########################################################################################################
Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo()
{

station_name=""
Eboard_SN=""
Eboard=""
HS_QR_CODE=""
Input_RestAPI_Message=""
part_number=""
service_status=""

###API

####TJAPI###############################
TID="client_id=NocHScsf53aqE"
TSECRET="client_secret=f8d6b0450c2a2af273a26569cdb0de04"
####NCAPI###############################
ID="client_id=vE7BhzDJhqO"
SECRET="client_secret=0f40daa800fd87e20e0c6a8230c6e28593f1904c7edfaa18cbbca2f5bc9272b5"
########################################
TYPE="grant_type=client_credentials"
furl="http://$NC_API_IP/api/v1/Oauth/token"
iurl="http://$NC_API_IP/api/v1/ItemInfo/get"
turl="http://$NC_API_IP/api/v1/Station/get"
##get_token#############################

echo "get token from wareconn API"
Input_RestAPI_Message=$(curl -X GET "$NC_API_IP/api/v1/Oauth/token?${ID}&${SECRET}&${TYPE}")
if echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
	token=$(echo "$Input_RestAPI_Message" | awk -F '"' '{print $10 }')
	show_pass_message "get_token successful:$token"	
else
	show_fail_message "$Input_RestAPI_Message"
	show_fail_message "get token Fail Please check net cable or call TE"
	exit 1
fi

##get_information from wareconn#########
echo "get data information from wareconn"
Input_RestAPI_Message=$(curl -X GET "$iurl" -H "content-type: application/json" -H "Authorization: Bearer "$token"" -d '{"serial_number":'"$1"'}') ####add parameters type 2024-05-07 
#echo $Input_RestAPI_Message
#pause
if echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
	station_name=$(echo "$Input_RestAPI_Message" | jq -r '.list.now_stn')
	Eboard_SN=$(echo "$Input_RestAPI_Message" | jq -r '.list.equipment_fixture[-1].equipment_serial_number')
	Eboard=$(echo "$Input_RestAPI_Message" | jq -r '.list.equipment_fixture[-1].equipment_name')
	HS_QR_CODE=$(echo "$Input_RestAPI_Message" | jq -r '.list.assy_records[-1].serial_number')
	part_number=$(echo "$Input_RestAPI_Message" | jq -r '.list.part_number')
	service_status=$(echo "$Input_RestAPI_Message" | jq -r '.list.is_serving')
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
Input_RestAPI_Message=""
station_name=""

###API

####TJAPI###############################
TID="client_id=NocHScsf53aqE"
TSECRET="client_secret=f8d6b0450c2a2af273a26569cdb0de04"
####NCAPI###############################
ID="client_id=vE7BhzDJhqO"
SECRET="client_secret=0f40daa800fd87e20e0c6a8230c6e28593f1904c7edfaa18cbbca2f5bc9272b5"
########################################
TYPE="grant_type=client_credentials"
furl="http://$NC_API_IP/api/v1/Oauth/token"
turl="http://$NC_API_IP/api/v1/Station/start"
##get_token#############################

#if [ "$2" = "false" ];then

	echo "get token from wareconn API"
	Input_RestAPI_Message=$(curl -X GET "$NC_API_IP/api/v1/Oauth/token?${ID}&${SECRET}&${TYPE}")
	if echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
		token=$(echo "$Input_RestAPI_Message" | awk -F '"' '{print $10 }')
		show_pass_message "get_token successful:$token"	
	else
		show_fail_message "$Input_RestAPI_Message"
		show_fail_message "get token Fail Please check net cable or call TE"
		exit 1
	fi

	## result start to api/vi/Station/start
	echo "upload start info to API "

	Input_RestAPI_Message=$(curl -X GET "$turl" -H "content-type: application/json" -H "Authorization: Bearer "$token"" -d '{"serial_number":"'"$1"'","station_name":"'"$current_stc_name"'","start_time":"'"${stime}"'","operator_id":"'"$operator_id"'","test_machine_number":"'"$fixture_id"'","test_program_name":"'"$diag_name"'","test_program_version":"'"$CFG_VERSION"'","pn":"'"$Input_Upper_PN"'","model":"'"$PROJECT"'"}')
	if echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
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

####TJAPI###############################
TID="client_id=NocHScsf53aqE"
TSECRET="client_secret=f8d6b0450c2a2af273a26569cdb0de04"
####NCAPI###############################
ID="client_id=vE7BhzDJhqO"
SECRET="client_secret=0f40daa800fd87e20e0c6a8230c6e28593f1904c7edfaa18cbbca2f5bc9272b5"
########################################
TYPE="grant_type=client_credentials"
furl="http://$NC_API_IP/api/v1/Oauth/token"
rurl="http://$NC_API_IP/api/v1/Station/end"
##get_token#############################
log_path="D:\\$PROJECT\\${Input_Upper_PN}\\${filename}"
echo "get token from wareconn API"
Input_RestAPI_Message=$(curl -X GET "$NC_API_IP/api/v1/Oauth/token?${ID}&${SECRET}&${TYPE}")
if echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
	token=$(echo "$Input_RestAPI_Message" | awk -F '"' '{print $10 }')
	show_pass_message "get_token successful:$token"	
else
	show_fail_message "$Input_RestAPI_Message"
	show_fail_message "Get token Fail Please check net cable or call TE"
	exit 1
fi

##Report station result to api/vi/Station/end
echo "report station result to wareconn API "
Input_RestAPI_Message=$(curl -X GET "$rurl?serial_number=$1&log_path=$log_path" -H "content-type: application/json" -H "Authorization: Bearer "$token"")
if echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
	show_pass_msg "$1 report result pass"	
else	
	show_fail_message "$Input_RestAPI_Message"
	show_fail_message "$1 report result FAIL Please call TE or wareconn Team"
	#exit 1
fi

}

#############################################################################################################
#############################################################################################################
####Main Part####
#################

#export flow_name="${current_stc_name}"

rm -rf $LOGFILE/*
echo "" > /var/log/message
#sleep 50
if [ ! -f $OPID ];then
	Input_Server_Connection
fi
update
ntpdate $NC_diagserver_IP
hwclock -w
StartTestTime=`date +"%Y%m%d%H%M%S"`
stime=$(date '+%FT%T'-04:00)
export start_time=$(date '+%F %T')	

Read_SN

if [ -f $SCANFILE ]; then
	Scan_Upper_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number=" | awk -F '=' '{print$2}'))
	Scan_Lower_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number2=" | awk -F '=' '{print$2}'))
#	echo ${Scan_Upper_SN}
#	echo ${Output_Upper_SN}
#	echo ${Scan_Lower_SN}
#	echo ${Output_Lower_SN}
#	pause
	if [ $testqty = 2 ];then
		if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ] && [ "${Scan_Lower_SN}" == "${Output_Lower_SN}" ]; then
			show_pass_message "Local Scan Info Have exist "
		else
			Output_Scan_Infor
			Scan_Upper_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number=" | awk -F '=' '{print$2}'))
			Scan_Lower_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number2=" | awk -F '=' '{print$2}'))
			if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ] && [ "${Scan_Lower_SN}" == "${Output_Lower_SN}" ]; then
				echo ""
			else
				show_fail_message "Scan Wrong Please Check!!!!"
				exit 1
			fi	
		fi
	else
		if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ]; then
			show_pass_message "Local Scan Info Have exist "
		else
			Output_Scan_Infor
			Scan_Upper_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number=" | awk -F '=' '{print$2}'))
			if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ]; then
				echo ""
			else
				show_fail_message "Scan Wrong Please Check!!!!"
				exit 1
			fi	
		fi
	fi	
		
else
	if [ -f "uutself.cfg.env" ]; then
		rsync -av uutself.cfg.env $mods/cfg/
		Output_Scan_Infor
		if [ $testqty = 2 ];then
			Scan_Upper_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number=" | awk -F '=' '{print$2}'))
			Scan_Lower_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number2=" | awk -F '=' '{print$2}'))
			if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ] && [ "${Scan_Lower_SN}" == "${Output_Lower_SN}" ]; then
				echo ""
			else
				show_fail_message "Scan Wrong Please Check!!!!"
				exit 1
			fi
		else
			Scan_Upper_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number=" | awk -F '=' '{print$2}'))
			if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ]; then
				echo ""
			else
				show_fail_message "Scan Wrong Please Check!!!!"
				exit 1
			fi
		fi	
	else
		show_fail_message "uutself.cfg.env is not exist please call TE!!!"
		exit 1 
	fi	
fi	

#echo $testqty
operator_id=$(echo $(cat ${SCANFILE} | grep "^operator_id=" | awk -F '=' '{print$2}'))
if [ "$operator_id" = "DEBUG001" ];then
	Run_Mode=1
	PROJECT="DEBUG"
fi	
if [ $testqty = "2" ]; then
	if [ $Run_Mode = "0" ];then
		Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo ${Output_Upper_SN}
		Input_Upper_Station=$station_name
		Input_Upper_ESN=$Eboard_SN
		Input_Upper_Eboard=$Eboard
		Input_Upper_Status=$service_status
		Input_Upper_HSC=$HS_QR_CODE
		Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo ${Output_Lower_SN}
		Input_Lower_Station=$station_name
		Input_Lower_ESN=$Eboard_SN
		Input_Lower_Eboard=$Eboard
		Input_Lower_Status=$service_status
		Input_Lower_HSC=$HS_QR_CODE		
		if [[ "$list_st_all" =~ "$Input_Lower_Station" ]] && [[ "$list_st_all" =~ "$Input_Upper_Station" ]]; then
			Input_Wareconn_Serial_Number_RestAPI_Mode ${Output_Upper_SN}
			Input_Upper_PN=$(grep "900PN" $mods/cfg/${Output_Upper_SN}.RSP | awk -F '=' '{ print $2 }'  )
			Input_Upper_Station=$(grep "current_stc_name" $mods/cfg/${Output_Upper_SN}.RSP | awk -F '=' '{ print $2 }'  )
			Input_Wareconn_Serial_Number_RestAPI_Mode ${Output_Lower_SN}
			Input_Lower_PN=$(grep "900PN" $mods/cfg/${Output_Lower_SN}.RSP | awk -F '=' '{ print $2 }'  )
			Input_Lower_Station=$(grep "current_stc_name" $mods/cfg/${Output_Lower_SN}.RSP | awk -F '=' '{ print $2 }'  )
			
			if [ ${Input_Upper_PN} = ${Input_Lower_PN} ] && [ ${Input_Upper_Station} = ${Input_Lower_Station} ] && [[ ! "$single_list_stn" =~ "$Input_Upper_Station" ]]; then
				analysis_sta
			else
				show_fail_message "make sure the cards PN and station is right!!! "
				show_fail_message "!!!! ${Input_Upper_PN}:${Input_Upper_Station}!!!!${Input_Lower_PN}:${Input_Lower_Station}!!!!"
				exit 1
			fi
		else
			show_fail_message "Current Station is !!!!${Output_Upper_SN}:$Input_Upper_Station!!!${Output_Lower_SN}:${Input_Lower_Station}!!! not test station"
			exit 1 
		fi		
	else
		Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo ${Output_Upper_SN}
		Input_Upper_Station=$station_name
		Input_Upper_ESN=$Eboard_SN
		Input_Upper_Eboard=$Eboard
		Input_Upper_Status=$service_status
		Input_Upper_HSC=$HS_QR_CODE
		Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo ${Output_Lower_SN}
		Input_Lower_Station=$station_name
		Input_Lower_ESN=$Eboard_SN
		Input_Lower_Eboard=$Eboard
		Input_Lower_Status=$service_status
		Input_Lower_HSC=$HS_QR_CODE
		read -p "Please Input station :" station
		if [[ "$list_st_all" =~ "$station" ]];then
			Input_Wareconn_Serial_Number_RestAPI_Mode ${Output_Upper_SN} $station
			Input_Upper_PN=$(grep "900PN" $mods/cfg/${Output_Upper_SN}.RSP | awk -F '=' '{ print $2 }'  )
			Input_Upper_Station=$(grep "current_stc_name" $mods/cfg/${Output_Upper_SN}.RSP | awk -F '=' '{ print $2 }'  )
			Input_Wareconn_Serial_Number_RestAPI_Mode ${Output_Lower_SN} $station
			Input_Lower_PN=$(grep "900PN" $mods/cfg/${Output_Lower_SN}.RSP | awk -F '=' '{ print $2 }'  )
			Input_Lower_Station=$(grep "current_stc_name" $mods/cfg/${Output_Lower_SN}.RSP | awk -F '=' '{ print $2 }'  )

			if [ ${Input_Upper_PN} = ${Input_Lower_PN} ]; then
				analysis_sta
			else
				show_fail_message "make sure the cards PN and station is right!!! "
				show_fail_message "!!!! ${Input_Upper_PN}:${Input_Upper_Station}!!!!${Input_Lower_PN}:${Input_Lower_Station}!!!!"
				exit 1
			fi
		else
			show_fail_message "station wrong please check!!!"
			exit 1
		fi	
	fi	
		
	
else
	if [ $Run_Mode = "0" ];then
		Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo ${Output_Upper_SN}
		Input_Upper_Station=$station_name
		Input_Upper_ESN=$Eboard_SN
		Input_Upper_Eboard=$Eboard
		Input_Upper_Status=$service_status
		Input_Upper_HSC=$HS_QR_CODE
		if [[ "$list_st_all" =~ "$Input_Upper_Station" ]]; then		
			Input_Wareconn_Serial_Number_RestAPI_Mode ${Output_Upper_SN}
			analysis_sta
		else
			show_fail_message "Current Station is $Input_Upper_Station  not test station"
			exit 1 
		fi
	else
		Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo ${Output_Upper_SN}
		Input_Upper_Station=$station_name
		Input_Upper_ESN=$Eboard_SN
		Input_Upper_Eboard=$Eboard
		Input_Upper_Status=$service_status
		Input_Upper_HSC=$HS_QR_CODE
		read -p "Please Input station :" station
		if [[ "$list_st_all" =~ "$station" ]];then
			Input_Wareconn_Serial_Number_RestAPI_Mode ${Output_Upper_SN} $station
			analysis_sta
		else
			show_fail_message "station wrong please check!!!"
			exit 1
		fi	
	fi	

fi	


