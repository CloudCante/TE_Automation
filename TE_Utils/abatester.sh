#!/bin/bash
## Project       : ABAG3Tester 
## Filename      : abatester.sh
## Version       : 1.0.0
## Release date  : 2025-09-11
## Revised by    : Anyi Wang
## Description   : Test G3 tester by automatically executing FLA BAT offline testing twice
##--------------------------------------------------------------------------------------------------------------------------------
## Version       : 1.0.1
## Release date  : 2025-11-04
## Revised by    : Anyi Wang
## Description   : 1.remove get token - from 1.1.2_autotest.sh
## Description   : 2.add retry api function - from 1.1.2_autotest.sh
## Description   : 3.add Gen5 support
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
export Tester_Logs_Path="/mnt/nv/server_logs/ABAG3Tester"
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
export INI_folder="$Diag_Path/INI/"
export Script_File="autotest.sh"
export site="NC"
export logserver_IP=""
export diagserver_IP=""
export API_IP=""
export ID=""
export SECRET=""
export TID="client_id=NocHScsf53aqE"
export TSECRET="client_secret=f8d6b0450c2a2af273a26569cdb0de04"
export NID="client_id=vE7BhzDJhqO"
export NSECRET="client_secret=0f40daa800fd87e20e0c6a8230c6e28593f1904c7edfaa18cbbca2f5bc9272b5"
export TYPE="grant_type=client_credentials"
export TJ_pw_diag="TJ77921~"
export TJ_pw_log="NVD77921~"
export NC_pw_diag="TJ77921~"
export NC_pw_log="TJ77921~"
export pw_diag=""
export pw_log=""
export Input_Upper_699PN=""
export Input_Lower_699PN=""
declare -u station
declare -u fixture_id
declare -a list_st=()
declare -a list_stn=()
declare -a single_list_stn=()
declare -a list_st_all=()


Script_VER="1.0.1"  
CFG_VERSION="1.1.1"
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
Output_Upper_699PN=""
Output_Lower_699PN=""
cont="true"


STATUS_FILE="/mnt/nv/status.txt"
SIDE_FILE="/mnt/nv/side.txt"
SIDE_STATUS=""
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
export DEBUG_MODE=$(get_config "DEBUG_MODE")

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
	echo 
	echo
	echo 
	echo
	echo
	echo
	show_fail_message " 		XXXXXXX     XXXX    XXXXXXXX  XXX"
	show_fail_message " 		XXXXXXX     XXXX    XXXXXXXX  XXX"
	show_fail_message " 		XXXXXXX    XXXXXX   XXXXXXXX  XXX"
	show_fail_message " 		XX        XX    XX     XX     XXX"
	show_fail_message " 		XX        XX    XX     XX     XXX"
	show_fail_message " 		XXXXXXX   XXXXXXXX     XX     XXX"
	show_fail_message " 		XXXXXXX   XXXXXXXX     XX     XXX"
	show_fail_message " 		XX        XX    XX     XX     XXX"
	show_fail_message " 		XX        XX    XX  XXXXXXXX  XXXXXXXX"
	show_fail_message " 		XX        XX    XX  XXXXXXXX  XXXXXXXX"
	echo 
	echo 
	echo 
	echo
	
}

#################capture "ctrl+c"############################################
function trap_ctrlc()
{
	# perform cleanup here 2024-12-14

	echo -e ""
	echo -e ""
	echo -e "\033[47;30m\033[05m	LINE No: ${LINENO}	Ctrl-C caught ...	\033[0m"
	echo -e ""
	echo -e ""
if [ -n "${diag_VER}" ];then
	if [ $mods/$diag_VER ];then
		rm -rf $mods/$diag_VER
		echo "delete local diag $diag_VER complete"
	fi
fi	

	exit 1
}
trap "trap_ctrlc" 2

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
	board_699pn=""
	###API

	##get_information from wareconn#########
	echo "get data information from wareconn"

	max_attempts=3
	attempt=1
	sleep_time=5
	timeout=60
	while [ $attempt -le $max_attempts ]; do
		show_warning_message "connecting API $attempt times (timeout: ${timeout}s)..."   
		Input_RestAPI_Message=$(curl -m 60 -k "$iurl?serial_number=$1") ####add parameters type 2024-05-07 
		curl_exit_code=$?

		if [ $curl_exit_code -eq 0 ]; then
			break
		fi

		if [ $attempt -lt $max_attempts ]; then
			sleep $sleep_time
		fi

		((attempt++))
	done
	#echo $Input_RestAPI_Message
	#pause
	if [ -n "$Input_RestAPI_Message" ] && echo "$Input_RestAPI_Message" | jq -e '.code == 0' > /dev/null; then
		station_name=$(echo "$Input_RestAPI_Message" | jq -r '.list.now_stn')
		Eboard_SN=$(echo "$Input_RestAPI_Message" | jq -r '.list.equipment_fixture[-1].equipment_serial_number')
		Eboard=$(echo "$Input_RestAPI_Message" | jq -r '.list.equipment_fixture[-1].equipment_name')
		HS_QR_CODE=$(echo "$Input_RestAPI_Message" | jq -r '.list.replace_parts[-1].sn')
		part_number=$(echo "$Input_RestAPI_Message" | jq -r '.list.part_number')
		service_status=$(echo "$Input_RestAPI_Message" | jq -r '.list.is_serving')
		board_699pn=$(echo "$Input_RestAPI_Message" | jq -r '.list."699pn"')
		show_pass_msg "$1 Get data information from wareconn!!!"
	else	
		show_fail_message "$Input_RestAPI_Message"
		show_fail_message "$1 Get Data information from Wareconn Fail Please call TE"
		exit 1
	fi	


}

###get information from wareconn#### 
Input_Wareconn_Serial_Number_RestAPI_Mode()
{
	###API

	now_stn=""
	Input_RestAPI_Message=""

	##get_information from wareconn#########
	echo "get test information from wareconn API "
	max_attempts=3
	attempt=1
	sleep_time=5
	timeout=60
	while [ $attempt -le $max_attempts ]; do
		show_warning_message "connecting API $attempt times (timeout: ${timeout}s)..."
		
		Input_RestAPI_Message=$(curl -m 60 -k "$surl?serial_number=$1&type=stc&stc_name=$2")
		curl_exit_code=$?

		if [ $curl_exit_code -eq 0 ]; then
			break
		fi

		if [ $attempt -lt $max_attempts ]; then
			sleep $sleep_time
		fi

		((attempt++))
	done	
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
			umount $Diag_Path >/dev/null 2>&1
			mount -t cifs -o username=administrator,password=$pw_diag //$diagserver_IP/e/current $Diag_Path
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
			mount -t cifs -o username=administrator,password=$pw_log //$logserver_IP/d $Logs_Path
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
				if [ $(expr length $operator_id) -eq 8 ] || [ -n "$operator_id" ];then
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
	if [ ! -f "nvflash_mfg" ] || [ ! -f "uutself.cfg.env" ];then
		Input_Server_Connection
		if [ -f $Diag_Path/nvflash_mfg ] && [ -f $Diag_Path/uutself.cfg.env ];then
			cp $Diag_Path/nvflash_mfg ./
			[ ! -f "uutself.cfg.env" ] && cp $Diag_Path/uutself.cfg.env ./
		else
			show_warning_message "Please call TE to check diag server, nvflash_mfg or uutself.cfg.env is not exist"
			exit 1
		fi	
	fi
		
	counts=$(./nvflash_mfg -A -a | grep "10DE" | wc -l)

	if [ $counts = "2" ]; then
		port1=$(lspci | grep NV | head -n 1 | awk '{ print $1 }')
		port2=$(lspci | grep NV | tail -n 1 | awk '{ print $1 }')
		Output_Upper_SN=$(./nvflash_mfg -B $port1  --rdobd | grep -m 1 'BoardSerialNumber' | awk -F ':' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
		Output_Upper_699PN=$(./nvflash_mfg -B $port1  --rdobd | grep -m 1 'Board699PartNumber' | awk -F ':' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
		Output_Lower_SN=$(./nvflash_mfg -B $port2  --rdobd | grep -m 1 'BoardSerialNumber' | awk -F ':' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
		Output_Lower_699PN=$(./nvflash_mfg -B $port2  --rdobd | grep -m 1 'Board699PartNumber' | awk -F ':' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
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
		Output_Upper_699PN=$(./nvflash_mfg --rdobd | grep -m 1 'Board699PartNumber' | awk -F ':' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
		if [ -z ${Output_Upper_SN} ]; then
			show_fail_msg "Read SN error Please check!!!"
			exit 1
		else
			show_pass_message "######SerialNumber1:$Output_Upper_SN######"
			show_pass_msg "Read SN OK"
			testqty="1"	
		fi
	else
		Output_Upper_SN=$(printf $(python3 aardvark/aai2c_fru_eeprom.py 0 400 read 0x50 0x00 256 | cut -d ":" -f 2 | tail -n +5 | xargs | sed 's/ / \\x/ g'| sed 's/^/\\x/' | tr -d " " ) | LC_ALL=C sed 's/[^ -~]/ /g' | xargs -0 | tr ' ' '\n' | awk '$1 ~ /[0-9]{13}/{print $1}' | tail -n -1 )
		if [ -n "$Output_Upper_SN" ];then
			show_pass_message "######SerialNumber1:$Output_Upper_SN######"
			show_pass_msg "Read SN OK"
			testqty="1"
		else	
			show_fail_message "Can't Detect Cards Please Inserd one Card"
			show_fail_msg "Read SN FAIL"
			exit 1
		fi	
		
	fi
	 
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
	else
		show_warning_message "diag_name is null, please call TE to check the wareconn settings"
		exit 1
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

	####Prepare BIOS####
	if [ ! ${BIOS_NAME} = "NA" ];then
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
	else
		show_pass_msg "Diag download OK"
	fi	

}

get_information()
{
	MACHINE=$(get_config "MACHINE")
	Input_Upper_PN=$(get_config "part_number")
	current_stc_name=$(get_config "current_stc_name")
	NVFLASH_VER=$(get_config "NVFLAH_VER")
	NVINFOROM=$(get_config "NVINFOROM")
	HEAVEN_VER=$(get_config "HEAVEN")
	BIOS_NAME=$(get_config "BIOS1_NAME")
	BIOS_VER=$(get_config "BIOS1_VER")
	Input_Script=$(get_config "SCRIPT_VER")
	operator_id="`grep "operator_id=" $SCANFILE |sed 's/.*= *//'`"
	fixture_id="`grep "fixture_id=" $SCANFILE |sed 's/.*= *//'`"
	Input_Upper_699PN=$(get_config "699PN")
	if [ $current_stc_name = "FLA2" ];then
		Tstation="FLA"
	elif [ $current_stc_name = "IST2" ];then
		Tstation="IST"
	elif [ $current_stc_name = "CHIFLASH" ];then
		Tstation="CHI"	
	else
		Tstation=$current_stc_name
	fi
	
}

###Upload Logs###
Upload_Tester_Log()
{
	cd /mnt/nv
	if grep -q "B:65" nvflash_output.log && grep -q "B:B3" nvflash_output.log ; then
		SIDE_STATUS="None"
		echo "This Test Does Not Support Dual Units, Please Remove One -Gen5"
		exit 1
	elif grep -q "B:17" nvflash_output.log && grep -q "B:9B" nvflash_output.log ; then
		SIDE_STATUS="None"
		echo "This Test Does Not Support Dual Units, Please Remove One -Gen5"
		exit 1
	elif grep -q "B:65" nvflash_output.log ; then
		SIDE_STATUS="LEFT"
	elif grep -q "B:B3" nvflash_output.log ; then
		SIDE_STATUS="RIGHT"
	elif grep -q "B:17" nvflash_output.log ; then
		SIDE_STATUS="LEFT"
	elif grep -q "B:9B" nvflash_output.log ; then
		SIDE_STATUS="RIGHT"
	else 
		echo "Check The Tester"
		exit 1
	fi		
	if [ $Script_Output -eq 0 ];then
		if ! cp -rf "$mods/logs" "$Tester_Logs_Path/${fixture_id}/${SIDE_STATUS}_SIDE_${2}_PASS_${StartTestTime}" 2>/dev/null; then
			mkdir -p "$Tester_Logs_Path/${fixture_id}/${SIDE_STATUS}_SIDE_${2}_PASS_${StartTestTime}"
			cp -rf "$mods/logs" "$Tester_Logs_Path/${fixture_id}/${SIDE_STATUS}_SIDE_${2}_PASS_${StartTestTime}"
		fi
	else
		if ! cp -rf "$mods/logs" "$Tester_Logs_Path/${fixture_id}/${SIDE_STATUS}_SIDE_${2}_FAIL_${StartTestTime}" 2>/dev/null; then
			mkdir -p "$Tester_Logs_Path/${fixture_id}/${SIDE_STATUS}_SIDE_${2}_FAIL_${StartTestTime}"
			cp -rf "$mods/logs" "$Tester_Logs_Path/${fixture_id}/${SIDE_STATUS}_SIDE_${2}_FAIL_${StartTestTime}"
		fi
	fi
	
}

###Run FLA BAT 2 times###
Run_Diag_ABAtester()
{
case "$STATUS" in
	"FLA_1")
		echo "Running first iteration - FLA"
		Read_SN
		if [ -f $SCANFILE ];then
			Scan_Upper_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number=" | awk -F '=' '{print$2}'))
			Scan_Lower_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number2=" | awk -F '=' '{print$2}'))
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
		operator_id=$(echo $(cat ${SCANFILE} | grep "^operator_id=" | awk -F '=' '{print$2}'))
		Input_Wareconn_Serial_Number_RestAPI_Mode_ItemInfo ${Output_Upper_SN}
		Input_Upper_Station=$station_name
		Input_Upper_ESN=$Eboard_SN
		Input_Upper_Eboard=$Eboard
		Input_Upper_Status=$service_status
		Input_Upper_HSC=$HS_QR_CODE
		Input_Upper_699PN=$board_699pn
		station="FLA"
		Input_Wareconn_Serial_Number_RestAPI_Mode ${Output_Upper_SN} $station
		#copy rsp to cfg.ini
		cd $mods/cfg/
		cp ${Output_Upper_SN}.RSP cfg.ini
		get_information
		diag_name=$(get_config "Diag1")
		diag_VER=$diag_name.tar.gz
		if [ ! -f $mods/$diag_VER ]; then
			DownLoad
		fi	
		cd $mods/core/flash
		./nvflash_mfg -A -a > /mnt/nv/nvflash_output.log	
		mkdir -p "$Tester_Logs_Path/${fixture_id}"
		cd $mods
		./rwcsv.sh
		sleep 1
		./FLA.sh
		Script_Output=$?
		Upload_Tester_Log "$Script_Output" "FLA_1"
		echo "BAT_1" > "$STATUS_FILE"
		reboot
		;;
	"BAT_1")
		echo "Running first iteration - BAT"
		get_information
		cd $mods
		./BAT.sh
		Script_Output=$?
		Upload_Tester_Log "$Script_Output" "BAT_1"
		echo "FLA_2" > "$STATUS_FILE"		
		reboot
		;;
	"FLA_2")
		echo "Running second iteration - FLA"
		get_information
		cd $mods
		./rwcsv.sh
		sleep 1
		./FLA.sh
		Script_Output=$?
		Upload_Tester_Log "$Script_Output" "FLA_2"	
		echo "BAT_2" > "$STATUS_FILE"
		reboot
		;;
	"BAT_2")
		echo "Running second iteration - BAT"
		get_information
		cd $mods
		./BAT.sh
		Script_Output=$?
		Upload_Tester_Log "$Script_Output" "BAT_2"
		if [ "$SIDE_COUNT" -eq 1 ]; then
			echo "FLA_1" > "$STATUS_FILE"
			echo "2" > "$SIDE_FILE"
			echo -ne "\033[32m"
			echo "ABATESTER Testing Is Done On One Side."
			read -p "Does This Tester have only one side? (Y/y/N/n):" response
			if [[ "$response" =~ ^[Yy]$ ]]; then
				cp -f "$STATUS_FILE" "$Tester_Logs_Path/${fixture_id}"
				rm -f "$STATUS_FILE"
				rm -f "$SIDE_FILE"	
				echo "ABATESTER Testing Is Done"
				echo "Call TE To Restore The Environment"
			else			
				echo -ne "\033[31m"
				echo "Please Poweroff Then Move The Unit To The Other Side."
				echo -e "\033[0m"
			fi
		elif [ "$SIDE_COUNT" -eq 2 ]; then
			echo "DONE" > "$STATUS_FILE"
			cp -f "$STATUS_FILE" "$Tester_Logs_Path/${fixture_id}"
			rm -f "$STATUS_FILE"
			rm -f "$SIDE_FILE"
			rm -f /mnt/nv/nvflash_output.log
			echo -ne "\033[32m"
			echo "ABATESTER Testing Is Done"
			echo -ne "\033[31m"
			echo "Call TE To Restore The Environment"
			echo -e "\033[0m"

		else
			echo -ne "\033[31m"
			echo "Unknown Side: [$SIDE_COUNT]"
			echo -e "\033[0m"			
		fi
		;;
	"DONE")
		echo -ne "\033[32m"
		echo "All completed."
		echo -e "\033[0m"
		rm -f "$STATUS_FILE"
		rm -f "$SIDE_FILE"
		;;
	*)
		echo -ne "\033[31m"
		echo "Unknown Status: [$STATUS]"
		echo -e "\033[0m"
		;;
esac
}

####Main####
if [ $site = "NC" ];then
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


rm -rf $LOGFILE/*
echo "" > /var/log/message
#sleep 50
if [ ! -f $OPID ] && [ ! -d ${INI_folder} ];then
	Input_Server_Connection
fi

if [ -f "$INI_folder/list_st.ini" ] && [ -f "$INI_folder/list_stn.ini" ] && [ -f "$INI_folder/single_list_stn.ini" ] && [ -f "$INI_folder/list_st_all.ini" ] && [ -f "$INI_folder/list_error.ini" ] && [ -f "$INI_folder/list_tpc_error.ini" ] && [ -f "$INI_folder/list_ist_error.ini" ];then
	mapfile -t list_st < "$INI_folder/list_st.ini" 2>/dev/null
	mapfile -t list_stn < "$INI_folder/list_stn.ini" 2>/dev/null
	mapfile -t single_list_stn < "$INI_folder/single_list_stn.ini" 2>/dev/null
	mapfile -t list_st_all < "$INI_folder/list_st_all.ini" 2>/dev/null
	mapfile -t list_error < "$INI_folder/list_error.ini" 2>/dev/null
	mapfile -t list_tpc_error < "$INI_folder/list_tpc_error.ini" 2>/dev/null
	mapfile -t list_ist_error < "$INI_folder/list_ist_error.ini" 2>/dev/null	
else
	show_warning_message "make sure ini file is exist please call TE to check diag server"
	exit 1
fi	


surl="https://$API_IP:4443/api/v1/test-profile/get"
iurl="https://$API_IP:4443/api/v1/ItemInfo/get"
rurl="https://$API_IP:4443/api/v1/Station/end"
turl="https://$API_IP:4443/api/v1/Station/start"
update
ntpdate $diagserver_IP
hwclock -w
StartTestTime=`date +"%Y%m%d%H%M%S"`

if [ $site = "NC" ];then
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
export start_time=$(date '+%F %T')

if [ ! -f "$STATUS_FILE" ];then
	echo "FLA_1" >  "$STATUS_FILE"
fi

if [ ! -f "$SIDE_FILE" ];then
	echo "1" >  "$SIDE_FILE"
fi
STATUS=$(cat "$STATUS_FILE")
SIDE_COUNT=$(cat "$SIDE_FILE")
echo -ne "\033[32m"
echo "Start Testing ABATester"
echo "Current Status = [$STATUS]; Current SIDE = [$SIDE_COUNT]"
echo -e "\033[0m"
Run_Diag_ABAtester
