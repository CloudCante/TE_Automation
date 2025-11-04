#!/bin/bash
##**********************************************************************************
## Project       : RMA_NVIDIA
## Filename      : sort_autotest.sh
## Description   : NVIDIA test automatic
## Usage         : n/a
##
##
## Version History
##-------------------------------
## Version       : 1.0.6
## Release date  : 2025-03-20
## Revised by    : Rick Stingel
## Description   : Initial release
## add PG520 IST files download 2024-06-04
## add run_mode for debug 2024-08-08
## add exist diag and sort_diag no need download 2024-08-16
## add PG520 looping or stuck issue reboot and run step2 2024-11-07
## add check IST file md5sum 2024-11-07
## add integration of new scripts that broke automation 2025-02-26
##**********************************************************************************

export Local_Logs="/home/diags/nv/logs"
export HEAVEN="/home/diags/nv/HEAVEN/"
export Diag_Path="/home/diags/nv/server_diag"
export Logs_Path="/home/diags/nv/server_logs"
export mods="/home/diags/nv/mods/test"

[ -d "$Local_Logs" ] || mkdir -p "$Local_Logs"
[ -d "$HEAVEN" ] || mkdir -p "$HEAVEN"
[ -d "$Diag_Path" ] || mkdir -p "$Diag_Path"
[ -d "$Logs_Path" ] || mkdir -p "$Logs_Path"
[ -d "$mods" ] || mkdir -p "$mods"
[ -d "$mods/cfg" ] || mkdir $mods/cfg

export CSVFILE="$mods/core/flash/PESG.csv"
export CFGFILE="$mods/cfg/cfg.ini"
export LOGFILE="$mods/logs"
export SCANFILE="$mods/cfg/uutself.cfg.env"
export TJ_logserver_IP="10.67.240.77"
export TJ_diagserver_IP="10.67.240.67"
export NC_logserver_IP="192.168.102.20"
export NC_diagserver_IP="192.168.102.21"
export NC_API_IP="192.168.102.20"
export TJ_API_IP="10.67.240.66"
export OPID="$Diag_Path/OPID/OPID.ini"  ###add check operator ID 4/4/2024####
export Script_File="Sort_autotest.sh"
export ISTdata="/home/diags/ISTdata" ###IST folder###2024-06-04
export IST_file="FXSJ_Zipped_DFX_GH100_IST_MUPT_RMA_Images_h100.7.tar.gz" ###IST file name###2024-06-04
export IST_folder="DFX_GH100_IST_MUPT_RMA_Images_h100.7"
export MODS_VER="525.213.tar.gz"
export MODS_folder="525.213"

Script_VER="1.0.6"
CFG_VERSION="1.0"
PROJECT="SORT_TESLA"
Process_Result=""
Output_SN=""
Input_PN=""
current_stc_name="TEST"
diag_name=""
HEAVEN_VER=""
Scaned_SN=""
MACHINE=""
NVFLASH_VER=""
NVINFOROM=""
diag_VER=""
BIOS_VER=""
BIOS_NAME=""
test_item=""
Fail_Module=""
Final_status=""
sort_diagname=""
sort_diagver=""
Run_Mode=0
declare -u station
declare -u fixture_id
declare -u current_stc_name

######test station list######
list_st="TEST"

#####################################################################
#                                                                   #
# Pause                                                             #
#                                                                   #
#####################################################################
pause()
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


######################################################################
#                                                                    #
# Show warning message (color: yellow)                               #
#                                                                    #
######################################################################
show_warn_message()
{ 
	tput bold
	TEXT=$1
	echo -ne "\033[33m$TEXT\033[0m"
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
}


#####################################################################
#                                                                   #
# Get information from wareconn                                     #
#                                                                   #
#####################################################################
Input_Wareconn_Serial_Number_RestAPI_Mode()
{
	####NCAPI###############################
	ID="client_id=vE7BhzDJhqO"
	SECRET="client_secret=0f40daa800fd87e20e0c6a8230c6e28593f1904c7edfaa18cbbca2f5bc9272b5"
	########################################
	TYPE="grant_type=client_credentials"
	furl="http://$NC_API_IP/api/v1/Oauth/token"
	surl="http://$NC_API_IP/api/v1/test-profile/get"
	##get_token#############################

	echo "get token from wareconn API"
	Input_RestAPI_Message=$(curl -X GET "$furl?${ID}&${SECRET}&${TYPE}")
	echo $Input_RestAPI_Message | grep "success"  > /dev/null
	if [ $? -eq 0 ]; then
		token=$(echo "$Input_RestAPI_Message" | awk -F '"' '{print $10 }')
		show_pass_message "get_token successful:$token"
	else
		show_fail_message "$Input_RestAPI_Message"
		show_fail_message "API connection Fail Please check net cable or call TE"
		exit 1
	fi

	##get_information from wareconn#########
	echo "get test information from wareconn API $1"
	Input_RestAPI_Message=$(curl -X GET "$surl" -H "content-type: application/json" -H "Authorization: Bearer "$token"" -d '{"serial_number":'"$1"',"type":"war"}')
	# Input_RestAPI_Message=$(curl -X GET "$surl?serial_number=$1&type=stc&stc_name=$2" -H "content-type: application/json" -H "Authorization: Bearer "$token"")
	echo $Input_RestAPI_Message | grep "error" || echo $Input_RestAPI_Message | grep "50004" > /dev/null
	if [ $? -eq 0 ]; then
		show_fail_message "$Input_RestAPI_Message"
		show_fail_message "Get Data information from Wareconn Fail Please call TE"
		show_fail_message "Check if there is an active configuration file for PN."
		exit 1
	else
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/"code":0,"data"://g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/{{//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/}}//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/\[//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/\]//g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/:/=/g')
		Input_RestAPI_Message=$(echo $Input_RestAPI_Message | sed 's/"//g')
		echo "$Input_RestAPI_Message" | awk -F ',' '{ for (i=1; i<=NF; i++) print $i }' > $mods/cfg/$1.RSP
		show_pass_message "Got Data information from wareconn!!!"
	fi
}


#####################################################################
#                                                                   #
# mount server folder                                               #
#                                                                   #
#####################################################################
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
	sleep 1
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
	sleep 1
}


#####################################################################
#                                                                   #
# SCAN                                                              #
#                                                                   #
#####################################################################
Output_Scan_Infor()
{
	if [ ! -f $OPID ];then
		Input_Server_Connection
	fi
	Scan_Opperator_ID
	Scan_Fixture_ID
	sed -i 's/operator_id=.*$/operator_id='${operator_id}'/g' $SCANFILE
	sed -i 's/fixture_id=.*$/fixture_id='${fixture_id}'/g' $SCANFILE
	show_pass_message "SCAN info OK"
}


#TODO: Move this lookup table to the log server, so it can be updated easily
declare -A operator_lookup
operator_lookup=(
	[1573]="RickS"
	[2542]="BimalL"
	[2533]="JoseV"
	[1519]="ThayK"
	[1590]="Mehret"
	[9284]="RichardA"
	#TODO: Add Stanley's ID
	[0000]="Stanley Song"
	[2524]="CoreyC"
)

#####################################################################
#                                                                   #
# Read the lookup table for operator ID's							#
# Not necessary if the operator wishes to type their name in		#
#                                                                   #
#####################################################################
lookup_operator_id() {
	local id=$1
	if [[ -n "${operator_lookup[$id]}" ]]; then
		echo "${operator_lookup[$id]}"
	else
		echo "Unknown Operator"
	fi
}


#####################################################################
#                                                                   #
# SCAN Opperator ID                                                 #
#                                                                   #
#####################################################################
Scan_Opperator_ID()
{
	status=0
	flg=0
	num=0
	let num+=1
	
	while [ $status = 0 ]; do
		if [ $flg = 1 ]; then
			read -p " $num. Scan Operator ID again:" operator_id 
		else
			read -p " $num. Scan Operator ID:" operator_id
			if [[ $operator_id =~ ^[0-9]{4}$ ]]; then
				operator_id=$(lookup_operator_id $operator_id)
				echo "Operator: $operator_id"
			fi
		fi
		if grep -q "^$operator_id$" $OPID; then
			status=1
		else
			flg=1
		fi
	done
}


#####################################################################
#                                                                   #
# SCAN Fixture ID                                                   #
#                                                                   #
#####################################################################
Scan_Fixture_ID()
{
	let num+=1
	status=0
	flg=0
	while [ $status = 0 ]; do
		if [ $flg = 0 ]; then
			read -p " $num. Scan Fixture ID (length 9):" fixture_id 
		else
			read -p " $num. Scan Fixture ID (length 9) again:" fixture_id
		fi

		if [ ${#fixture_id} -eq 9 ]; then
			status=1
		else
			flg=1
		fi
	done
}


#####################################################################
#                                                                   #
# SCAN SN                                                   		#
#                                                                   #
#####################################################################
Scan_SN()
{
	let num+=1
	status=0
	flg=0
	while [ $status = 0 ]; do
		#Scan the SN
		if [ $flg = 0 ]; then
			read -p " $num. Scan Board SN (length 13):" Scaned_SN
		else
			read -p " $num. Scan Board SN (length 13) again:" Scaned_SN
		fi
		
		if [ ${#Scaned_SN} -eq 13 ]; then
			status=1
		else
			flg=1
		fi
	done
}


#####################################################################
#                                                                   #
# SCAN SN                                                   		#
#                                                                   #
#####################################################################
Scan_PN()
{
	let num+=1
	status=0
	flg=0
	while [ $status = 0 ]; do
		#Scan the SN
		if [ $flg = 0 ]; then
			read -p " $num. Scan Board PN (length 18):" Input_PN
		else
			read -p " $num. Scan Board PN (length 18) again:" Input_PN
		fi
		
		if [ ${#Input_PN} -eq 18 ]; then
			status=1
		else
			flg=1
		fi
	done
}


#####################################################################
#                                                                   #
# Read serial number from tester                                    #
#                                                                   #
#####################################################################
Read_SN()
{
	if [ ! -f "nvflash_mfg" ]; then
		Input_Server_Connection
		cp $Diag_Path/nvflash_mfg ./ 
		[ ! -f "uutself.cfg.env" ] && cp $Diag_Path/uutself.cfg.env ./
	fi

	#GPU Counts
	#This command is unreliable, attempt to run again if we didnt get the result we want
	echo "Checking for GPU"
	counts=$(timeout 60s lspci | grep NV | wc -l)
	if [ $counts -ne "1" ]; then
		echo "First Check Failed"
		sleep 30
		echo "Checking for GPU"
		counts=$(timeout 60s lspci | grep NV | wc -l)
	fi

	#If there is exactly 1 GPU then continue.
	if [ $counts = "1" ]; then
		Output_SN=$(./nvflash_mfg --rdobd | grep -m 1 'BoardSerialNumber' | awk -F ':' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
		if [ -z "$Output_SN" ]; then
			show_fail_message "Serial number is empty."
			exit 1
		fi
		show_pass_message "######SerialNumber:$Output_SN######"
		show_pass_message "Read SN OK"
		sed -i 's/serial_number=.*$/serial_number='${Output_SN}'/g' $SCANFILE
	else
		show_fail_message "Read SN error."

		Scan_Fixture_ID
		Scan_SN

		#Create a fixtureID.txt file in the project directory if it doesnt exist
		#This file is used to log if the fixture has been reseated by logging the SN.
		#on a reboot, if the last value in the fixtureID.txt file is the same SN, we know we have attempted a reseat.
		[ ! -d $Logs_Path/$PROJECT/Fixture_Logs ] && mkdir -p $Logs_Path/$PROJECT/Fixture_Logs 2>/dev/null
		[ ! -f $Logs_Path/$PROJECT/Fixture_Logs/$fixture_id.txt ] && touch $Logs_Path/$PROJECT/Fixture_Logs/$fixture_id.txt 2>/dev/null
		
		#TODO fix this whole logic. instead of relying on FABRICATE, we should be running the test and having it fabricate for us.
		#Check if we have already reseated this GPU
		if tail -n 2 $Logs_Path/$PROJECT/Fixture_Logs/$fixture_id.txt | grep -q $Scaned_SN; then
			show_fail_message "Reseat Detected"
			show_fail_message "SN $Scaned_SN has already been attempted once."
			Scan_PN
			show_fail_message "Uploading Logs, Please Wait..."
			Upload_start_Log  ${Scaned_SN}
			$Logs_Path/$PROJECT/FabricateSortDissasembly/FabricateSortDissasembly.sh $Scaned_SN $Input_PN
			sleep 5
			fail_logs=$(find $Logs_Path/$PROJECT/$Input_PN/ -name "*${Scaned_SN}_F_1st*.zip" 2>/dev/null | wc -l)
			show_fail
			#if we find 2 or more fail logs, then we know we are ready for dissasembly
			if [ $fail_logs -ge 2 ]; then
				#if we are making a fail log for dissasembly, we need to make a log
				echo "TEST module Test ------------ [ FAIL ]" | tee -a $LOGFILE/log.txt
				date +"<Info message>: $m - end time: %F %T" | tee -a $LOGFILE/log.txt
				sleep 30
				show_fail_message "Multiple FAIL logs detected. Mark unit for dissasembly."
				Upload_End_Log ${Scaned_SN} FAIL
			else
				show_fail_message "Mark Unit for Board Change"
			fi
			exit 1
		fi


		#TODO: Add an automated method to add the Interposer SN to the file

		#Write to the fixture logs in the log server of SN that was not able to connect
		echo $Scaned_SN >> $Logs_Path/$PROJECT/Fixture_Logs/$fixture_id.txt
		

		show_fail_message "Scan successfull, system will now shut down."
		show_fail_message "Please reseat card while system is off."
		pause
		poweroff
	fi
}

#####################################################################
#                                                                   #
# Download diag from diagserver                                     #
#                                                                   #
#####################################################################
DownLoad()
{
	#####Prepare diag######
	cd $mods 
	ls | grep -v cfg | xargs rm -fr
	if [ -d ${Diag_Path}/${MACHINE}/${diag_name} ]; then
		show_pass_message "DownLoad Diag From Server Please Wait..."
		cp -rf ${Diag_Path}/${MACHINE}/${diag_name}/* $mods
		cd $mods
		tar -xf ${diag_VER}
		if [ $? -ne 0 ]; then
			show_fail_message "Please delete ${diag_VER} and reboot"
			show_fail_message "DownLoad Diag FAIL"
			exit 1
		fi
	else
		Input_Server_Connection
		if [ -d ${Diag_Path}/${MACHINE}/${diag_name} ]; then
			show_pass_message "DownLoad Diag From Server Please Wait..."
			cp -rf ${Diag_Path}/${MACHINE}/${diag_name}/* $mods
			cd $mods
			tar -xf ${diag_VER}
			if [ $? -ne 0 ]; then
				show_fail_message "Please delete ${diag_VER} and reboot"
				show_fail_message "DownLoad Diag FAIL"
				exit 1
			fi
		else
			show_fail_message "${Diag_Path}/${MACHINE}/${diag_name}"
			show_fail_message "Diag doesn't exist Please Call TE"
			show_fail_message "DownLoad Diag FAIL"
			exit 1
		fi
	fi

	#####Prepare HEAVEN#####
	if [ -f $HEAVEN/$HEAVEN_VER ]; then
		show_pass_message "DownLoad HEAVEN From Local Please Wait..."
		cp -rf $HEAVEN/$HEAVEN_VER $mods/core/mods0
		cd $mods/core/mods0
		tar -xf $HEAVEN_VER
		if [ $? -ne 0 ]; then
			show_fail_message "Please delete ${diag_VER} and reboot"
			show_fail_message "DownLoad HEAVEN FAIL"
			exit 1
		fi
	else
		if [ -f ${Diag_Path}/HEAVEN/$HEAVEN_VER ]; then
			show_pass_message "DownLoad HEAVEN From Server Please Wait..."
			cp -rf ${Diag_Path}/HEAVEN/$HEAVEN_VER $HEAVEN
			cp -rf $HEAVEN/$HEAVEN_VER $mods/core/mods0
			cd $mods/core/mods0
			tar -xf $HEAVEN_VER
			if [ $? -ne 0 ]; then
				show_fail_message "Please delete ${diag_VER} and reboot"
				show_fail_message "DownLoad HEAVEN FAIL"
				exit 1
			fi
		else
			Input_Server_Connection
			if [ -f ${Diag_Path}/HEAVEN/$HEAVEN_VER ]; then
				show_pass_message "DownLoad HEAVEN From Server Please Wait..."
				cp -rf ${Diag_Path}/HEAVEN/$HEAVEN_VER $HEAVEN
				cp -rf $HEAVEN/$HEAVEN_VER $mods/core/mods0
				cd $mods/core/mods0
				tar -xf $HEAVEN_VER
				if [ $? -ne 0 ]; then
					show_fail_message "Please delete ${diag_VER} and reboot"
					show_fail_message "DownLoad HEAVEN FAIL"
					exit 1
				fi
			else
				show_fail_message "${Diag_Path}/HEAVEN/$HEAVEN_VER"
				show_fail_message "HEAVEN doesn't exist Please Call TE"
				show_fail_message "DownLoad HEAVEN FAIL"
				exit 1
			fi
		fi
	fi

	####Prepare Sorting script#####
	if [ -d ${Diag_Path}/${MACHINE}/${sort_diagname} ]; then
		show_pass_message "DownLoad Sort_Diag From Server Please Wait..."
		cp -rf ${Diag_Path}/${MACHINE}/${sort_diagname}/* $mods
		cd $mods
		tar -xf ${sort_diagver}
		if [ $? -ne 0 ]; then
			show_fail_message "Please delete ${sort_diagver} and reboot"
			show_fail_message "DownLoad Sort_Diag FAIL"
			exit 1
		fi
	else
		Input_Server_Connection
		if [ -d ${Diag_Path}/${MACHINE}/${sort_diagname} ]; then
			show_pass_message "DownLoad Sort_Diag From Server Please Wait..."
			cp -rf ${Diag_Path}/${MACHINE}/${sort_diagname}/* $mods
			cd $mods
			tar -xf ${sort_diagver}
			if [ $? -ne 0 ]; then
				show_fail_message "Please delete ${sort_diagver} and reboot"
				show_fail_message "DownLoad Sort_Diag FAIL"
				exit 1
			fi
		else
			show_fail_message "${Diag_Path}/${MACHINE}/${sort_diagname}"
			show_fail_message "Sort_Diag doesn't exist Please Call TE"
			show_fail_message "DownLoad Sort_Diag FAIL"
			exit 1
		fi
	fi

	####PG520 Prepare DFX files#####
	if [ $MACHINE = SG520 ]; then
		DFX=$(get_config "Diag3")
		if [ -f $HEAVEN/$DFX ]; then
			show_pass_message "DownLoad DFX From Local Please Wait..."
			cp -rf $HEAVEN/$DFX $mods/core/mods0
			cd $mods/core/mods0
			tar -xf $DFX
			if [ $? -ne 0 ]; then
				show_fail_message "Please delete $DFX and reboot"
				show_fail_message "DownLoad DFX FAIL"
				exit 1
			else
				show_pass_message "DownLoad Diag pass"
			fi
		else
			if [ -f ${Diag_Path}/HEAVEN/$DFX ]; then
				show_pass_message "DownLoad DFX From Server Please Wait..."
				cp -rf ${Diag_Path}/HEAVEN/$DFX $HEAVEN
				cp -rf $HEAVEN/$DFX $mods/core/mods0
				cd $mods/core/mods0
				tar -xf $DFX
				if [ $? -ne 0 ]; then
					show_fail_message "Please delete $DFX and reboot"
					show_fail_message "DownLoad DFX FAIL"
					exit 1
				else
					show_pass_message "DownLoad Diag pass"
				fi
			else
				Input_Server_Connection
				if [ -f ${Diag_Path}/HEAVEN/$DFX ]; then
					show_pass_message "DownLoad DFX From Server Please Wait..."
					cp -rf ${Diag_Path}/HEAVEN/$DFX $HEAVEN
					cp -rf $HEAVEN/$DFX $mods/core/mods0
					cd $mods/core/mods0
					tar -xf $DFX
					if [ $? -ne 0 ]; then
						show_fail_message "Please delete $DFX and reboot"
						show_fail_message "DownLoad DFX FAIL"
						exit 1
					else
						show_pass_message "DownLoad Diag pass"
					fi
				else
					show_fail_message "${Diag_Path}/HEAVEN/$DFX"a
					show_fail_message "DFX doesn't exist Please Call TE"
					show_fail_message "DownLoad DFX FAIL"
					exit 1
				fi
			fi
		fi
	fi
}


#####################################################################
#                                                                   #
# Run diag                                                          #
#                                                                   #
#####################################################################
Run_Diag()
{
	if [ $Run_Mode = "0" ]; then
		cd $mods

		Upload_start_Log  ${Output_SN}

		if [ "$MACHINE" = "SG520" ]; then
			current_stc_name="TEST"
		fi
		test_item="$current_stc_name"
		run_command "$test_item"
		if [ $? -eq 0 ]; then
			Upload_End_Log ${Output_SN} PASS
		else
			resf=$(find $mods/ -name "*${Output_SN}_F_1st*.zip" 2>/dev/null)
			if [ -n "$resf" ]; then
				Upload_End_Log ${Output_SN} FAIL
			else
				show_fail_message "There is no FAIL log if looping stop or stuck stop please reboot and run step2"
			fi
		fi

	else
		cd $mods
		
		test_item="${station}"
		run_command "$test_item"
	fi
}


#####################################################################
#                                                                   #
# Upload log to logserver                                           #
#                                                                   #
#####################################################################
Upload_End_Log()
{
	Final_status="Final status"

	# Get the BIOS Version from the tmp.log file
	bios="$(get_bios ${Input_PN})" 2>&1
	# If get_bios was not successfull
	if [[ $? != 0 ]]; then
		# Use the BIOS Version from Wareconn, which is located locally in /cfg/<SN>.RSP
		bios="$(echo $BIOS_VER | egrep "[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}$")"
		if [[ $? != 0 ]]; then
			echo "WARNING: Invalid BIOS Version($BIOS_VER) found, check your Wareconn configuration file"
		fi
	fi

	end_time=`date +"%Y%m%d_%H%M%S"`
	filename=$1_"${current_stc_name}"_"$end_time"_$2.log

	cd $LOGFILE
	echo "${PROJECT} L5 Functional Test" >"${filename}"
	echo "${diag_name} (config version: ${CFG_VERSION})" >>"${filename}"
	echo "============================================================================" >>"${filename}"
	echo "Start time              :$start_time" >>"${filename}"
	echo "End time                :$(date '+%F %T')" >>"${filename}"
	echo "Part number             :${Input_PN}" >>"${filename}"
	echo "Serial number           :${1}" >>"${filename}"
	echo "operator_id             :`grep "operator_id=" $SCANFILE |sed 's/.*= *//'`" >>"${filename}"
	echo "fixture_id              :`grep "fixture_id=" $SCANFILE |sed 's/.*= *//'`" >>"${filename}"
	echo "Bios Version            :$bios" >>"${filename}"
	echo " " >>"${filename}"
	echo "============================================================================" >>"${filename}"
	echo "$Final_status: ${2}" >> "${filename}"
	echo "****************************************************************************" >>"${filename}"
	echo "FUNCTIONAL TESTING" >>"${filename}"
	echo "****************************************************************************" >>"${filename}"

	cat $LOGFILE/log.txt | tr -d "\000" >>"${filename}"

	## upload test log to log server
	if [ ! -d ${Logs_Path}/$PROJECT ]; then
		Input_Server_Connection
	fi
	if [ ! -d ${Logs_Path}/$PROJECT ]; then
		show_fail_message "Mounting log server fail."
		exit 1 
	fi
	
	[ ! -d ${Logs_Path}/$PROJECT/${Input_PN} ] && mkdir ${Logs_Path}/$PROJECT/${Input_PN}
	log_files=$(find $mods -maxdepth 2 -type f -name "*$1*.log" -o -name "*$1*.zip")
	for log_file in $log_files; do
		cp -rf "$log_file" ${Logs_Path}/$PROJECT/${Input_PN}
		mv -f "$log_file" ${Local_Logs}
	done

	#only move these to the backukp, because we dont know what run they came from.
	other_Logs=$(find $mods -maxdepth 2 -type f -name "*_FAIL.log" -o -name "*_START.log" -o -name "*_PASS.log" -o -name "*Z.zip")
	for other_log in $other_Logs; do
		mv -f "$other_log" ${Local_Logs}
	done
}


#####################################################################
#                                                                   #
# Run Command                                                       #
#                                                                   #
#####################################################################
run_command()
{
	for m in $1; do
		echo $m | grep -i "untest" > /dev/null 2>&1
		[ $? -eq 0 ] && continue

		echo -e "\033[32m Begin $m module Test\033[0m"
		echo " " | tee -a $LOGFILE/log.txt
		date +"<Info message>: $m - start time: %F %T" | tee -a $LOGFILE/log.txt 
		cd $mods
		if [ "$m" = "TEST" ]; then
			#1. This will alleviate the first user prompt, were we always enter FXNC and YES
			#2. This will run the test, checking for the computer to output any line of text in 30 minutes, timeout if it doesn't
			#3. This will tee the output to a log file, and prepend the date and time to each line
			if [ "$MACHINE" = "SG520" ]; then
				echo -e "FXNC\nYES" | timeout --foreground 1800 stdbuf -oL -eL ./$m.sh | stdbuf -oL -eL tee >(awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0; fflush(); }' >> $LOGFILE/log.txt)
				exit_status=$?
			elif [ "$MACHINE" = "SG506" ]; then
				#SG506 runs an old diag package that does not require the user input of FXNC and YES
				timeout --foreground 1800 stdbuf -oL -eL ./$m.sh | stdbuf -oL -eL tee >(awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0; fflush(); }' >> $LOGFILE/log.txt)
				exit_status=$?
			else
				echo "Invalid Machine Type: $MACHINE"
				exit 1
			fi
		else
			exit_status=./$m.sh
		fi

		#instead of using exit status, we can check the log file for the string "_P_" or "_F_"
		#this will allow us to determine if the test passed or failed
		#more reliably than relying on the exit code
		if find $mods -maxdepth 2 -type f -name "*${Output_SN}_P_*.zip" | grep -q .; then
			exit_status=0
		elif find $mods -maxdepth 2 -type f -name "*${Output_SN}_F_*.zip" | grep -q .; then
			exit_status=1
		else
			show_warn_message "NO ZIP FILE FOUND"
		fi
		
		if [ $exit_status -ne 0 ]; then
			echo "$m module Test ------------ [ FAIL ]" | tee -a $LOGFILE/log.txt
			date +"<Info message>: $m - end time: %F %T" | tee -a $LOGFILE/log.txt
			Fail_Module=$m
			echo " "
			echo " " | tee -a $LOGFILE/log.txt 
			return 1
		else
			echo "$m module Test ----------- [ PASS ]" | tee -a $LOGFILE/log.txt
			date +"<Info message>: $m - end time: %F %T" | tee -a $LOGFILE/log.txt 
			echo " "
			echo " " | tee -a $LOGFILE/log.txt
		fi
	done
	return 0
}


#####################################################################
#                                                                   #
# Get Information                                                   #
#																   	#
# Reads the cfg.ini file and loads all the variables into memory	#
#                                                                   #
#####################################################################
get_information()
{
	MACHINE=$(get_config "MACHINE")
	Input_PN=$(get_config "900PN")
	current_stc_name=$(get_config "current_stc_name")
	NVFLASH_VER=$(get_config "NVFLAH_VER")
	NVINFOROM=$(get_config "NVINFOROM")
	HEAVEN_VER=$(get_config "HEAVEN")
	BIOS_NAME=$(get_config "BIOS1_NAME")
	BIOS_VER=$(get_config "BIOS1_VER")
	Input_Script=$(get_config "SCRIPT_VER")
}


#####################################################################
#                                                                   #
# Analyize Station                                                  #
#                                                                   #
#####################################################################
analysis_sta()
{
	cd $mods/cfg/
	mv ${Output_SN}.RSP cfg.ini
	get_information
	script_check
	if [ $Run_Mode = "0" ]; then
		if [ $MACHINE = SG520 ]; then
			prepare_file $ISTdata $IST_file $IST_folder
			prepare_file $ISTdata $MODS_VER $MODS_folder
		fi

		zip_file=$(find $mods -maxdepth 2 -name "*${Output_SN}*.zip" 2>/dev/null)
		if [ -n "$zip_file" ]; then
			show_pass_message "Zip file from completed test found: $zip_file"
			read -p "Would you like to skip test and use this Zip? (Y/y):" response
			if [[ "$response" =~ ^[Yy]$ ]]; then
				if [[ "$zip_file" == *"_P_"* ]]; then
					show_pass_message "Bypassing Test"
					Upload_End_Log ${Output_SN} PASS
					return
				else
					show_fail_message "Bypassing Test"
					Upload_End_Log ${Output_SN} FAIL
					return
				fi
			fi
		fi

		if [[ "$list_st" =~ "$current_stc_name" ]]; then
			diag_name=$(get_config "Diag1")
			diag_VER=$diag_name.tar.gz
			sort_diagname=$(get_config "Diag2")
			sort_diagver=$sort_diagname.tar.gz
			#TODO add a check to potentially skip download if the versions match
			DownLoad
			Run_Diag
		else
			show_fail_message "Current Station is $current_stc_name not test station"
			exit 1
		fi
	else
		read -p "Please Input station :" station
		if [ $MACHINE = SG520 ]; then
			prepare_file $ISTdata $IST_file
			prepare_file $ISTdata $MODS_VER
		fi

		if [[ "$list_st" =~ "$station" ]]; then
			diag_name=$(get_config "Diag1")
			diag_VER=$diag_name.tar.gz
			sort_diagname=$(get_config "Diag2")
			sort_diagver=$sort_diagname.tar.gz
			if ! [ -f $mods/$diag_VER ] && [ -f $mods/$sort_diagver ]; then
				DownLoad
			fi
			Run_Diag
		else
			show_fail_message "station wrong please check!!!"
			exit 1
		fi
	fi
}


#####################################################################
#                                                                   #
# Upload Start Log                                                  #
#                                                                   #
#####################################################################
Upload_start_Log()
{
	start_log_time=`date +"%Y%m%d_%H%M%S"`
	filename="$1"_"${current_stc_name}"_"$start_log_time"_"START".log
	
	cd $LOGFILE
	echo "${PROJECT} L5 Functional Test" >"${filename}"
	echo "${diag_name} (config version: ${CFG_VERSION})" >>"${filename}"
	echo "============================================================================" >>"${filename}"
	echo "Start time              :$start_time" >>"${filename}"
	echo "Part number             :${Input_PN}" >>"${filename}"
	echo "Serial number           :${1}" >>"${filename}"
	echo "operator_id             :`grep "operator_id=" $SCANFILE |sed 's/.*= *//'`" >>"${filename}"
	echo "fixture_id              :`grep "fixture_id=" $SCANFILE |sed 's/.*= *//'`" >>"${filename}"


	## upload test log to log server
	
	if [ ! -d ${Logs_Path}/$PROJECT ]; then
		Input_Server_Connection
	fi
	if [ ! -d ${Logs_Path}/$PROJECT ]; then
		show_fail_message "Mounting log server fail."
		exit 1 
	fi

	[ ! -d ${Logs_Path}/$PROJECT/${Input_PN} ] && mkdir ${Logs_Path}/$PROJECT/${Input_PN}
	#this logic could lead to putting zip files in the wrong directories if they werent cleaned up from a previous run
	log_files=$(find $mods -maxdepth 2 -type f -name "*.log")
	for log_file in $log_files; do
		cp -rf "$log_file" ${Logs_Path}/$PROJECT/${Input_PN}
		mv -f "$log_file" ${Local_Logs}
	done
}


#####################################################################
#                                                                   #
# wareconn control script version                                   #
#                                                                   #
#####################################################################
script_check()
{
	echo "Local  Script Version : ${Script_VER}"
	echo "Config Script Version : ${Input_Script}"
	if [ ! -f ${Diag_Path}/${Input_Script}_${Script_File} ]; then
		Input_Server_Connection
	fi

	if [ "${Script_VER}" != "${Input_Script}" ];then
		if [ -f ${Diag_Path}/${Input_Script}_${Script_File} ];then
			cp -f ${Diag_Path}/${Input_Script}_${Script_File} /home/diags/nv/$Script_File
			sleep 3
			reboot
		else
			show_fail_message "Script '$Input_Script_$Script_File' not found in Diag_Path, please check"
			show_fail_message "Please call TE"
			exit 1
		fi
	fi
}

script_self_update()
{
	if ! cmp -s ${Diag_Path}/${Script_VER}_${Script_File} /home/diags/nv/$Script_File; then
		show_warn_message "Script content mismatch, despite versions matching"
		read -t 30 -p "Enter Y to download new version (default Y after 30 seconds): " response
		response=${response:-Y}
		if [[ "$response" == "Y" || "$response" == "y" ]]; then
			cp -f ${Diag_Path}/${Script_VER}_${Script_File} /home/diags/nv/$Script_File
			sleep 1
			/home/diags/nv/$Script_File
			exit 0
		else
			show_warn_message "Continuing with current version..."
		fi
	fi
}


#####################################################################
#                                                                   #
# before test Prepare some files                                    #
#                                                                   #
#####################################################################
prepare_file()
{
	#DFX=$(get_config "Diag3")
	if [ -d $1/$3 ] && [ -f $1/$2.txt ]; then
		cd $1
		echo "Check $2 md5vaule Please Wait..."
		sumvaul=$(md5sum -c $2.txt)
		echo $sumvaul | grep "OK" > /dev/null
		if [ $? -eq 0 ]; then
			show_pass_message "$2 already exists and complete!!!"
		else
			show_fail_message "Please check if $1/$2 is complete !!!"
			show_fail_message "delete $1/$2 and reboot download again !!!"
			exit 1
		fi
	else
		#echo "${Diag_Path}/HEAVEN/$HEAVEN_VER"
		#pause
		if [ -f ${Diag_Path}/HEAVEN/$2 ] && [ -f ${Diag_Path}/HEAVEN/$2.txt ]; then
			show_pass_message "DownLoad $2 From Server Please Wait..."
			cp -rf ${Diag_Path}/HEAVEN/$2 $1
			cp -rf ${Diag_Path}/HEAVEN/$2.txt $1
			cd $1
			echo "Checking $2 md5vaule Please Wait..."
			sumvaul=$(md5sum -c $2.txt)
			echo $sumvaul | grep "OK" > /dev/null
			if [ $? -eq 0 ]; then
				show_pass_message "$2 already exist and complete!!!"
			else
				show_fail_message "Please check if $1/$2 is complete !!!"
				show_fail_message "delete $1/$2 and reboot download again !!!"
				exit 1
			fi
			tar -xf $2
			if [ $? -ne 0 ]; then
				show_fail_message "delete $1/$2 and reboot download again !!!"
				show_fail_message "DownLoad $2 file FAIL"
				exit 1
			else
				show_pass_message "DownLoad $2 ok"
			fi
		else
			Input_Server_Connection
			if [ -f ${Diag_Path}/HEAVEN/$2 ] && [ -f ${Diag_Path}/HEAVEN/$2.txt ]; then
				show_pass_message "DownLoad $2 From Server Please Wait..."
				cp -rf ${Diag_Path}/HEAVEN/$2 $1
				cp -rf ${Diag_Path}/HEAVEN/$2.txt $1
				cd $1
				echo "Check $2 md5vaule Please Wait..."
				sumvaul=$(md5sum -c $2.txt)
				echo $sumvaul | grep "OK" > /dev/null
				if [ $? -eq 0 ]; then
					show_pass_message "$2 already exist and complete!!!"
				else
					show_fail_message "Please check if $1/$2 is complete !!!"
					show_fail_message "delete $1/$2 and reboot download again !!!"
					exit 1
				fi
				tar -xf $2
				if [ $? -ne 0 ]; then
					show_fail_message "delete $1/$2 and reboot download again !!!"
					show_fail_message "DownLoad $2 file FAIL"
					exit 1
				else
					show_pass_message "DownLoad $2 ok"
				fi
			else
				show_fail_message "$2 file doesn't exist Please Call TE"
				show_fail_message "DownLoad $2 file FAIL"
				exit 1
			fi
		fi
	fi
}


##**********************************************************************************
## Function to search for the BIOS version of the SXM from the tmp.log file
## in <SN>_Basic log folder
## name          : get_bios
## param $1      : <serial number> - serial number of SXM
##**********************************************************************************
get_bios()
{
	cd $mods
	# Find *_Basic folder and tmp.log file
	tmp_log="$(find $LOGFILE -name "*${1}*_Basic")/tmp.log"
	if [[ ! -f $tmp_log ]]; then
		echo "WARNING: Log file $tmp_log was not found, unable to search for BIOS Version."
		exit 1
	fi

	# Grep for the bios version in the tmp.log file
	grep_results="$(egrep "^Version\s+:\s[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}$" $tmp_log 2>&1)"
	if [[ $? != 0 ]]; then
		echo "WARNING: BIOS Version was not found in $tmp_log"
		exit 1
	fi

	# Verify the version format
	bios="$(echo $grep_results | cut -d ":" -f2 | egrep "[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}$")"
	if [[ $? != 0 ]]; then
		echo "WARNING: Found BIOS Version($grep_results) found in $tmp_log is invalid."
		exit 1
	fi

	echo $bios
}


#####################################################################
#### Main Part ####
#####################################################################

show_warn_message "Script Version is ${Script_VER}"

#export flow_name="${current_stc_name}"
rm -rf $LOGFILE/*
rm -rf $mods/log.txt
echo "" > /var/log/message
if [ ! -f $OPID ]; then
	Input_Server_Connection
fi
script_self_update
ntpdate $NC_diagserver_IP
hwclock -w
export start_time=$(date '+%F %T')

rmmod nvidia_drm nvidia_modeset nvidia >/dev/null 2>&1

Read_SN

if [ -f $SCANFILE ]; then
	Output_Scan_Infor
else
	if [ -f "uutself.cfg.env" ]; then
		rsync -av uutself.cfg.env $mods/cfg/
		Output_Scan_Infor
	else
		show_fail_message "No uutself.cfg.env exists. Please call TE!!!"
		exit 1
	fi
fi

operator_id=$(echo $(cat ${SCANFILE} | grep "^operator_id=" | awk -F '=' '{print$2}'))
if [ "$operator_id" = "DEBUG001" ]; then
	Run_Mode=1
	PROJECT="DEBUG"
fi


Input_Wareconn_Serial_Number_RestAPI_Mode ${Output_SN} TEST
analysis_sta
#sleep 120 seconds so we have time for wareconn to sync up before we analyze the logs
sleep 120
/home/diags/nv/server_logs/sortToWhere.sh $Output_SN