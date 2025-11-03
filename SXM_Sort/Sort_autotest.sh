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
## Version       : 1.0.4
## Release date  : 2024-11-01
## Revised by    : Thay Khang
## Description   : Initial release
## add PG520 IST files download 2024-06-04
## add run_mode for debug 2024-08-08
## add exist diag and sort_diag no need download 2024-08-16
##**********************************************************************************

[ -d "/home/diags/nv/logs/" ] || mkdir /home/diags/nv/logs
[ -d "/home/diags/nv/HEAVEN/" ] || mkdir /home/diags/nv/HEAVEN/
[ -d "/home/diags/nv/server_diag" ] || mkdir /home/diags/nv/server_diag
[ -d "/home/diags/nv/server_logs" ] || mkdir /home/diags/nv/server_logs
[ -d "/home/diags/nv/mods/test" ] || mkdir /home/diags/nv/mods/test
[ -d "/home/diags/nv/mods/test/cfg" ] || mkdir /home/diags/nv/mods/test/cfg

export HEAVEN="/home/diags/nv/HEAVEN/"
export Diag_Path="/home/diags/nv/server_diag"
export Logs_Path="/home/diags/nv/server_logs"
export mods="/home/diags/nv/mods/test"
export CSVFILE="$mods/core/flash/PESG.csv"
export CFGFILE="$mods/cfg/cfg.ini"
export LOGFILE="$mods/logs"
export SCANFILE="$mods/cfg/uutself.cfg.env"
export Local_Logs="/home/diags/nv/logs"
export TJ_logserver_IP="10.67.240.77"
export TJ_diagserver_IP="10.67.240.67"
export NC_logserver_IP="192.168.102.20"
export NC_diagserver_IP="192.168.102.21"
export NC_API_IP="192.168.102.20"
export TJ_API_IP="10.67.240.66"
export OPID="$Diag_Path/OPID/OPID.ini"  ###add check operator ID 4/4/2024####
export Script_File="$Diag_Path/Sort_autotest.sh"
export ISTdata="/home/diags/ISTdata" ###IST folder###2024-06-04
export IST_file="FXSJ_Zipped_DFX_GH100_IST_MUPT_RMA_Images_h100.7.tar.gz" ###IST file name###2024-06-04
export MODS_VER="525.213.tar.gz"

Script_VER="1.0.3"  ###script version 2024-08-16
CFG_VERSION="1.0"
PROJECT="SORT_TESLA"
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
sort_diagname=""
sort_diagver=""
Run_Mode=0

######test station list######
list_st="TEST" ###no need spare parts station list###
list_stn=""                   ###need more spare parts station list###
single_list_stn=""                    ###single baord station list###

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
####get information from wareconn#################
Input_Wareconn_Serial_Number_RestAPI_Mode()
{
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
surl="http://$NC_API_IP/api/v1/test-profile/get"
##get_token#############################

echo "get token from wareconn API"
Input_RestAPI_Message=$(curl -X GET "$NC_API_IP/api/v1/Oauth/token?${ID}&${SECRET}&${TYPE}")
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
echo "get test information from wareconn API "
Input_RestAPI_Message=$(curl -X GET "$surl" -H "content-type: application/json" -H "Authorization: Bearer "$token"" -d '{"serial_number":'"$1"',"type":"war"}') ####add parameters type 2024-05-07 
#echo $Input_RestAPI_Message
#pause
echo $Input_RestAPI_Message | grep "error" || echo $Input_RestAPI_Message | grep "50004" > /dev/null
if [ $? -eq 0 ]; then
	show_fail_message "$Input_RestAPI_Message"
	show_fail_message "Get Data information from Wareconn Fail Please call TE"
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
	show_pass_msg "Get Data information from wareconn!!!"
	
fi
	
}

##mount server folder###########
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
###SCAN#################
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
		# if [ $testqty = "2" ];then	
		
			# let num+=1
			# status=0
			# flg=0	
			# while [ $status = 0 ]; do
				# if [ $flg = 1 ]; then
				# else
					# read -p " $num. Scan Board SN1 (length 13):" Scan_Upper_SN
				# fi
				# if [ $(expr length $Scan_Upper_SN) -eq 13 ]; then
					# status=1
				# else
					# flg=1
				# fi
			# done	
			
			# let num+=1
			# status=0
			# flg=0	
			# while [ $status = 0 ]; do
				# if [ $flg = 1 ]; then
					# read -p " $num. Scan Board SN2 (length 13) again:" Scan_Lower_SN 
				# else
					# read -p " $num. Scan Board SN2 (length 13):" Scan_Lower_SN
				# fi
				# lengt=$(echo $Scan_Lower_SN | wc -m)
				# if [ $lengt = "14" ] || [ $lengt = "1"  ]; then
				# else
					# flg=1
				# fi
			# done
		# else
			# let num+=1
			# status=0
			# flg=0	
			# while [ $status = 0 ]; do
				# if [ $flg = 1 ]; then
					# read -p " $num. Scan Board SN (length 13) again:" Scan_Upper_SN 
				# else
					# read -p " $num. Scan Board SN (length 13):" Scan_Upper_SN
				# fi
				# if [ $(expr length $Scan_Upper_SN) -eq 13 ]; then
					# status=1
				# else
					# flg=1
				# fi
			# done
		# fi		

	}
	if [ ! -f $OPID ];then
		Input_Server_Connection
	fi	
	scan_label
	sed -i 's/operator_id=.*$/operator_id='${operator_id}'/g' $SCANFILE
	sed -i 's/fixture_id=.*$/fixture_id='${fixture_id}'/g' $SCANFILE
	#sed -i 's/serial_number=.*$/serial_number='${Scan_Upper_SN}'/g' $SCANFILE
	#sed -i 's/serial_number2=.*$/serial_number2='${Scan_Lower_SN}'/g' $SCANFILE
	show_pass_msg "SCAN info OK"

}
#####Read serial number from tester###########
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
		num=0
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
		Output_Upper_SN=${Scan_Upper_SN}
		sed -i 's/serial_number=.*$/serial_number='${Output_Upper_SN}'/g' $SCANFILE	
		testqty="1"
	else
		show_pass_message "######SerialNumber1:$Output_Upper_SN######"
		show_pass_msg "Read SN OK"
		sed -i 's/serial_number=.*$/serial_number='${Output_Upper_SN}'/g' $SCANFILE
		testqty="1"	
	fi
else
	show_fail_message "Can't Detect Cards Please Inserd one Card"
	show_fail_msg "Read SN FAIL"
	num=0
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
	Output_Upper_SN=${Scan_Upper_SN}
	sed -i 's/serial_number=.*$/serial_number='${Output_Upper_SN}'/g' $SCANFILE
	testqty="1"	
	
fi

	
	 
}
#####download diag from diagserver#####
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

####Prepare Sorting script#####

if [ -d ${Diag_Path}/${MACHINE}/${sort_diagname} ]; then
#if [ -d ${Diag_Path}/${Input_Upper_PN}/${diag_name} ]; then
	show_pass_message "DownLoad Sort_Diag From Server Please Waiting ..."
	#echo "${diag_VER}"
	#pause
	#cp -rf ${Diag_Path}/${Input_Upper_PN}/${diag_name}/* $mods
	cp -rf ${Diag_Path}/${MACHINE}/${sort_diagname}/* $mods
	cd $mods
	tar -xf ${sort_diagver} 
	if [ $? -ne 0 ];then
		show_fail_message "Please make sure exist sort_diag zip files"
		show_fail_msg "DownLoad Sort_Diag FAIL"
		exit 1
	fi	
	#cp  ${Diag_Path}/${MACHINE}/${NVFLAH_VER}/* 
	
else
	Input_Server_Connection
	if [ -d ${Diag_Path}/${MACHINE}/${sort_diagname} ]; then
	#if [ -d ${Diag_Path}/${Input_Upper_PN}/${diag_name} ]; then
		show_pass_message "DownLoad Sort_Diag From Server Please Waiting ..."
		cp -rf ${Diag_Path}/${MACHINE}/${sort_diagname}/* $mods
		#cp -rf ${Diag_Path}/${Input_Upper_PN}/${diag_name}/* $mods
		cd $mods
		tar -xf ${sort_diagver} 
		if [ $? -ne 0 ];then
			show_fail_message "Please make sure exist sort_diag zip files"
			show_fail_msg "DownLoad Sort_Diag FAIL"
			exit 1
		fi	
		#cp  ${Diag_Path}/${MACHINE}/${NVFLAH_VER}/* ./
	else
		show_fail_message "Sort_Diag isn't exist Please Call TE"
		show_fail_msg "DownLoad Sort_Diag FAIL"
		exit 1
	fi	
fi


	
####PG520 Prepare DFX files#####
if [ $MACHINE = SG520 ];then
	DFX=$(get_config "Diag3")
	if [ -f $HEAVEN/$DFX ];then
		show_pass_message "DownLoad DFX From Local Please Waiting ..."
		cp -rf $HEAVEN/$DFX $mods/core/mods0
		cd $mods/core/mods0
		tar -xf $DFX 
		if [ $? -ne 0 ];then
			show_fail_message "Please make sure exist DFX zip files"
			show_fail_msg "DownLoad DFX FAIL"
			exit 1
		else
			show_pass_msg "DownLoad Diag pass"
		fi		
	else
		#echo "${Diag_Path}/HEAVEN/$HEAVEN_VER"
		#pause
		if [ -f ${Diag_Path}/HEAVEN/$DFX ]; then
			show_pass_message "DownLoad DFX From Server Please Waiting ..."
			cp -rf ${Diag_Path}/HEAVEN/$DFX $HEAVEN
			cp -rf $HEAVEN/$DFX $mods/core/mods0
			cd $mods/core/mods0
			tar -xf $DFX 
			if [ $? -ne 0 ];then
				show_fail_message "Please make sure exist DFX zip files"
				show_fail_msg "DownLoad DFX FAIL"
				exit 1
			else
				show_pass_msg "DownLoad Diag pass"
			fi		
		else
			Input_Server_Connection
			if [ -f ${Diag_Path}/HEAVEN/$DFX ]; then
				show_pass_message "DownLoad DFX From Server Please Waiting ..."
				cp -rf ${Diag_Path}/HEAVEN/$DFX $HEAVEN
				cp -rf $HEAVEN/$DFX $mods/core/mods0
				cd $mods/core/mods0
				tar -xf $DFX 
				if [ $? -ne 0 ];then
					show_fail_message "Please make sure exist DFX zip files"
					show_fail_msg "DownLoad DFX FAIL"
					exit 1
				else
					show_pass_msg "DownLoad Diag pass"
				fi		
			else
				show_fail_message "DFX isn't exist Please Call TE"
				show_fail_msg "DownLoad DFX FAIL"
				exit 1 
			fi
		fi
	fi
fi	

####Prepare IST files#####2024-06-04

# if [ $MACHINE = SG520 ];then
	# #DFX=$(get_config "Diag3")
	# if [ -f $ISTdata/$IST_file ];then
		# show_pass_message "IST_file already exist!!!"		
	# else
		# #echo "${Diag_Path}/HEAVEN/$HEAVEN_VER"
		# #pause
		# if [ -f ${Diag_Path}/HEAVEN/$IST_file ]; then
			# show_pass_message "DownLoad IST_file From Server Please Waiting ..."
			# cp -rf ${Diag_Path}/HEAVEN/$IST_file $ISTdata
			# cd $ISTdata
			# tar -xf $IST_file 
			# if [ $? -ne 0 ];then
				# show_fail_message "Please make sure exist IST file zip files"
				# show_fail_msg "DownLoad IST file FAIL"
				# exit 1
			# else
				# show_pass_msg "DownLoad Diag pass"
			# fi		
		# else
			# Input_Server_Connection
			# if [ -f ${Diag_Path}/HEAVEN/$IST_file ]; then
				# show_pass_message "DownLoad DFX From Server Please Waiting ..."
				# cp -rf ${Diag_Path}/HEAVEN/$IST_file $ISTdata
				# cd $ISTdata
				# tar -xf $IST_file
				# if [ $? -ne 0 ];then
					# show_fail_message "Please make sure exist IST file zip files"
					# show_fail_msg "DownLoad IST file FAIL"
					# exit 1
				# else
					# show_pass_msg "DownLoad Diag pass"
				# fi		
			# else
				# show_fail_message "IST file isn't exist Please Call TE"
				# show_fail_msg "DownLoad IST file FAIL"
				# exit 1 
			# fi
		# fi
	# fi
# fi
# ###Prepare MODS file###2024-06-04

# if [ $MACHINE = SG520 ];then
	# #DFX=$(get_config "Diag3")
	# if [ -f $ISTdata/$IST_file ];then
		# show_pass_message "IST_file already exist!!!"		
	# else
		# #echo "${Diag_Path}/HEAVEN/$HEAVEN_VER"
		# #pause
		# if [ -f ${Diag_Path}/HEAVEN/$IST_file ]; then
			# show_pass_message "DownLoad IST_file From Server Please Waiting ..."
			# cp -rf ${Diag_Path}/HEAVEN/$IST_file $ISTdata
			# cd $ISTdata
			# tar -xf $IST_file 
			# if [ $? -ne 0 ];then
				# show_fail_message "Please make sure exist IST file zip files"
				# show_fail_msg "DownLoad IST file FAIL"
				# exit 1
			# else
				# show_pass_msg "DownLoad Diag pass"
			# fi		
		# else
			# Input_Server_Connection
			# if [ -f ${Diag_Path}/HEAVEN/$IST_file ]; then
				# show_pass_message "DownLoad DFX From Server Please Waiting ..."
				# cp -rf ${Diag_Path}/HEAVEN/$IST_file $ISTdata
				# cd $ISTdata
				# tar -xf $IST_file
				# if [ $? -ne 0 ];then
					# show_fail_message "Please make sure exist IST file zip files"
					# show_fail_msg "DownLoad IST file FAIL"
					# exit 1
				# else
					# show_pass_msg "DownLoad Diag pass"
				# fi		
			# else
				# show_fail_message "IST file isn't exist Please Call TE"
				# show_fail_msg "DownLoad IST file FAIL"
				# exit 1 
			# fi
		# fi
	# fi
# fi		

####Prepare BIOS####
#if [ -f ${Diag_Path}/${MACHINE}/BIOS/${BIOS_NAME} ]; then
#	cp -rf ${Diag_Path}/${MACHINE}/BIOS/${BIOS_NAME} $mods
#	show_pass_msg "Diag download OK"
#else
#	Input_Server_Connection
#	if [ -f ${Diag_Path}/${MACHINE}/BIOS/${BIOS_NAME} ]; then
#		cp -rf ${Diag_Path}/${MACHINE}/BIOS/${BIOS_NAME} $mods
#		show_pass_msg "Diag download OK"
#	else
#		show_fail_message "Please make sure $BIOS_NAME is exsit!!!"
#		show_fail_msg "Diag download OK"
#		exit 1
#	fi
#fi

}
#####run diag#####
Run_Diag()
{
if [ $Run_Mode = "0" ];then
	cd $mods
	if [ $testqty = "2" ];then	
		upload_start_log  ${Scan_Upper_SN}
		upload_start_log  ${Scan_Lower_SN}
	else
		upload_start_log  ${Output_Upper_SN}
	fi	
	if [ ${current_stc_name} = "FT" ];then
		test_item="inforcheck bioscheck BAT BIT FCT FPF"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_FPF*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_FPF*" 2>/dev/null)		
				if [ -n "$resf" ] && [ -n "$resc" ];then
					Upload_Log ${Scan_Upper_SN} PASS
					Upload_Log ${Scan_Lower_SN} PASS
					show_pass
					sleep 20
					reboot
				elif [ -n "$resf" ] ; then
					Upload_Log ${Scan_Upper_SN} PASS
					show_pass
					sleep 20
					reboot
				else
					Upload_Log ${Scan_Lower_SN} PASS
					show_pass
					sleep 20
					reboot
				fi			
			else
				Upload_Log ${Scan_Upper_SN} PASS
				show_pass
				sleep 20
				reboot
			fi	
		else
			if [ $testqty = "2" ];then
				Upload_Log ${Scan_Upper_SN} FAIL
				Upload_Log ${Scan_Lower_SN} FAIL
				show_fail
			else
				Upload_Log ${Scan_Upper_SN} FAIL
				show_fail
			fi	
		fi
	elif [ ${current_stc_name} = "FLA" ];then
		test_item="rwcsv FLA bioscheck"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS
			show_pass	
		else
			Upload_Log ${Scan_Upper_SN} FAIL
			show_fail			
		fi
	elif [ ${current_stc_name} = "FLB" ];then
		test_item="rwcsv FLB"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			Upload_Log ${Scan_Upper_SN} PASS
			show_pass			
		else
			Upload_Log ${Scan_Upper_SN} FAIL
			show_fail	
		fi	
	else
		test_item="${current_stc_name}"
		run_command "$test_item"
		if [ $? -eq 0 ];then
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${current_stc_name}*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${current_stc_name}*" 2>/dev/null)
				if [ -n "$resf" ] && [ -n "$resc" ];then
					Upload_Log ${Scan_Upper_SN} PASS
					Upload_Log ${Scan_Lower_SN} PASS
					show_pass
					sleep 20
					reboot
				elif [ -n "$resf" ] ; then
					Upload_Log ${Scan_Upper_SN} PASS
					show_pass
					sleep 20
					reboot
				else
					Upload_Log ${Scan_Lower_SN} PASS
					show_pass
					sleep 20
					reboot
				fi	
			else
				Upload_Log ${Output_Upper_SN} PASS
				#show_pass
				#sleep 20
				#reboot
			fi	
		else
			if [ $testqty = "2" ];then
				resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${current_stc_name}*" 2>/dev/null)
				resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${current_stc_name}*" 2>/dev/null)
				if [ -n "$resf" ];then
					Upload_Log ${Scan_Upper_SN} PASS
					Upload_Log ${Scan_Lower_SN} FAIL
					show_fail
				elif [ -n "$resc" ];then	
					Upload_Log ${Scan_Lower_SN} PASS
					Upload_Log ${Scan_Upper_SN} FAIL
					show_fail
				else
					Upload_Log ${Scan_Upper_SN} FAIL
					Upload_Log ${Scan_Lower_SN} FAIL
					show_fail
				fi		
			else
				Upload_Log ${Output_Upper_SN} FAIL
				#show_fail
			fi	
		fi	
	fi	
else
	cd $mods
	# if [ $testqty = "2" ];then	
		# upload_start_log  ${Scan_Upper_SN}
		# upload_start_log  ${Scan_Lower_SN}
	# else
		# upload_start_log  ${Scan_Upper_SN}
	# fi	
	if [ ${station} = "FT" ];then
		test_item="BAT BIT FCT FPF"
		run_command "$test_item"
		# if [ $? -eq 0 ];then
			# if [ $testqty = "2" ];then
				# resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_FPF*" 2>/dev/null)
				# resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_FPF*" 2>/dev/null)		
				# if [ -n "$resf" ] && [ -n "$resc" ];then
					# # Upload_Log ${Scan_Upper_SN} PASS
					# # Upload_Log ${Scan_Lower_SN} PASS
					# show_pass
					# #sleep 20
					# #reboot
				# elif [ -n "$resf" ] ; then
					# # Upload_Log ${Scan_Upper_SN} PASS
					# # show_pass
					# #sleep 20
					# #reboot
				# else
					# Upload_Log ${Scan_Lower_SN} PASS
					# show_pass
					# #sleep 20
					# #reboot
				# fi			
			# else
				# Upload_Log ${Scan_Upper_SN} PASS
				# show_pass
				# #sleep 20
				# #reboot
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
	elif [ ${station} = "FLA" ];then
		test_item="rwcsv FLA"
		run_command "$test_item"
		# if [ $? -eq 0 ];then
			# Upload_Log ${Scan_Upper_SN} PASS
			# show_pass
			# show_pass_message "FLA station need poweroff and turn off/on 54v PSU as well"	
		# else
			# Upload_Log ${Scan_Upper_SN} FAIL
			# show_fail			
		# fi
	elif [ ${station} = "FLB" ];then
		test_item="rwcsv FLB"
		run_command "$test_item"
		# if [ $? -eq 0 ];then
			# Upload_Log ${Scan_Upper_SN} PASS
			# show_pass
			# show_pass_message "FLB station need poweroff and turn off/on 54v PSU as well"	
		# else
			# Upload_Log ${Scan_Upper_SN} FAIL
			# show_fail	
		# fi
	elif [ ${station} = "CHIFLASH" ];then ####for clear BBX station### 2024-04-26
		test_item="rwcsv CHIFLASH"
		run_command "$test_item"
		# if [ $? -eq 0 ];then
			# if [ $testqty = "2" ];then
				# resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_FLA*" 2>/dev/null)
				# resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_FLA*" 2>/dev/null)
				# if [ -n "$resf" ] && [ -n "$resc" ];then
					# Upload_Log ${Scan_Upper_SN} PASS
					# Upload_Log ${Scan_Lower_SN} PASS
					# show_pass
					# #sleep 20
					# #reboot
				# elif [ -n "$resf" ] ; then
					# Upload_Log ${Scan_Upper_SN} PASS
					# show_pass
					# #sleep 20
					# #reboot
				# else
					# Upload_Log ${Scan_Lower_SN} PASS
					# show_pass
					# #sleep 20
					# #reboot
				# fi	
			# else
				# Upload_Log ${Scan_Upper_SN} PASS
				# show_pass
				# #sleep 20
				# #reboot
			# fi	
		# else
			# if [ $testqty = "2" ];then
				# resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_FLA*" 2>/dev/null)
				# resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_FLA*" 2>/dev/null)
				# if [ -n "$resf" ];then
					# Upload_Log ${Scan_Upper_SN} PASS
					# Upload_Log ${Scan_Lower_SN} FAIL
					# show_fail
				# elif [ -n "$resc" ];then	
					# Upload_Log ${Scan_Lower_SN} PASS
					# Upload_Log ${Scan_Upper_SN} FAIL
					# show_fail
				# else
					# Upload_Log ${Scan_Upper_SN} FAIL
					# Upload_Log ${Scan_Lower_SN} FAIL
					# show_fail
				# fi		
			# else
				# Upload_Log ${Scan_Upper_SN} FAIL
				# show_fail
			# fi	
		# fi
	else
		test_item="${station}"
		run_command "$test_item"
		# if [ $? -eq 0 ];then
			# if [ $testqty = "2" ];then
				# resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${current_stc_name}*" 2>/dev/null)
				# resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${current_stc_name}*" 2>/dev/null)
				# if [ -n "$resf" ] && [ -n "$resc" ];then
					# Upload_Log ${Scan_Upper_SN} PASS
					# Upload_Log ${Scan_Lower_SN} PASS
					# show_pass
					# #sleep 20
					# #reboot
				# elif [ -n "$resf" ] ; then
					# Upload_Log ${Scan_Upper_SN} PASS
					# show_pass
					# #sleep 20
					# #reboot
				# else
					# Upload_Log ${Scan_Lower_SN} PASS
					# show_pass
					# #sleep 20
					# #reboot
				# fi	
			# else
				# Upload_Log ${Scan_Upper_SN} PASS
				# show_pass
				# #sleep 20
				# #reboot
			# fi	
		# else
			# if [ $testqty = "2" ];then
				# resf=$(find $LOGFILE/ -name "*${Scan_Upper_SN}_P_${current_stc_name}*" 2>/dev/null)
				# resc=$(find $LOGFILE/ -name "*${Scan_Lower_SN}_P_${current_stc_name}*" 2>/dev/null)
				# if [ -n "$resf" ];then
					# Upload_Log ${Scan_Upper_SN} PASS
					# Upload_Log ${Scan_Lower_SN} FAIL
					# show_fail
				# elif [ -n "$resc" ];then	
					# Upload_Log ${Scan_Lower_SN} PASS
					# Upload_Log ${Scan_Upper_SN} FAIL
					# show_fail
				# else
					# Upload_Log ${Scan_Upper_SN} FAIL
					# Upload_Log ${Scan_Lower_SN} FAIL
					# show_fail
				# fi		
			# else
				# Upload_Log ${Scan_Upper_SN} FAIL
				# show_fail
			# fi	
		# fi	
	fi
fi	
	
#run_command ${current_stc_name}

#./$mods/"${current_stc_name}".sh


}
####upload log to logserver######
Upload_Log()
{
if [ $testqty = 2 ]; then
	Final_status="DUAL Board Final status"
else
	Final_status="Final status"
fi	

# Get the BIOS Version from the tmp.log file
bios="$(get_bios ${Input_Upper_PN})" 2>&1
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

cd $mods
echo "${PROJECT} L5 Functional Test" >"${filename}"
echo "${diag_name} (config version: ${CFG_VERSION})" >>"${filename}"
echo "============================================================================" >>"${filename}"
echo "Start time              :$start_time" >>"${filename}"
echo "End time                :$(date '+%F %T')" >>"${filename}"
echo "Part number             :${Input_Upper_PN}" >>"${filename}"
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

cat $mods/log.txt | tr -d "\000" >>"${filename}"

## upload test log to log server
if [ -d ${Logs_Path}/$PROJECT ]; then
	[ ! -d ${Logs_Path}/$PROJECT/${Input_Upper_PN} ] && mkdir ${Logs_Path}/$PROJECT/${Input_Upper_PN}
	cp -rf *$1*.{zip,log} ${Logs_Path}/$PROJECT/${Input_Upper_PN}
	cp -rf *$1*.{zip,log} ${Local_Logs}
	rm -rf *$1*	
else
	Input_Server_Connection
	if [ -d ${Logs_Path}/$PROJECT ]; then
		[ ! -d ${Logs_Path}/$PROJECT/${Input_Upper_PN} ] && mkdir ${Logs_Path}/$PROJECT/${Input_Upper_PN}
		cp -rf *$1*.{zip,log} ${Logs_Path}/$PROJECT/${Input_Upper_PN}
		cp -rf *$1*.{zip,log} ${Local_Logs}
		rm -rf *$1*
	else
		show_fail_message "show_fail_message Mounting log server fail."
		exit 1 
	fi	
	
fi	


}

run_command()
{
    for m in $1; do
        echo $m | grep -i "untest" > /dev/null 2>&1
        [ $? -eq 0 ] && continue

        echo -e "\033[32m Begin $m module Test\033[0m"
        echo " " | tee -a $mods/log.txt
        date +"<Info message>: $m - start time: %F %T" | tee -a $mods/log.txt 
        cd $mods
        ./$m.sh 
        if [ $? -ne 0 ]; then
            echo "$m module Test ------------ [ FAIL ]" | tee -a $mods/log.txt
            #color "$m module test" FAIL
            date +"<Info message>: $m - end time: %F %T" | tee -a $mods/log.txt
			Fail_Module=$m
            echo " "
            echo " " | tee -a $mods/log.txt 
            return 1
        else
            echo "$m module Test ----------- [ PASS ]" | tee -a $mods/log.txt
            #color "$m module test" PASS
            date +"<Info message>: $m - end time: %F %T" | tee -a $mods/log.txt 
            echo " "
            echo " " | tee -a $mods/log.txt
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
}

analysis_sta()
{
if [ $Run_Mode = "0" ];then
	cd $mods/cfg/
	cp  ${Output_Upper_SN}.RSP cfg.ini
	get_information
	script_check
	if [ $MACHINE = SG520 ];then
		prepare_file $ISTdata $IST_file
		prepare_file $ISTdata $MODS_VER
	fi	

	if [ $current_stc_name = "OQA" ]; then
		diag_name=$(get_config "Diag2")
		diag_VER=$diag_name.tar.gz
		if [ -f $mods/$diag_VER ]; then
			Run_Diag
		else
			DownLoad
			Run_Diag			
		fi

	elif [[ "$list_st" =~ "$current_stc_name" ]];then
		diag_name=$(get_config "Diag1")
		diag_VER=$diag_name.tar.gz
		sort_diagname=$(get_config "Diag2")
		sort_diagver=$sort_diagname.tar.gz
		#echo $diag_VER
		#pause
		if [ -f $mods/$diag_VER ] && [ -f $mods/$sort_diagver ]; then  ###add exist diag and sort_diag no need download 
			Run_Diag
		else
			DownLoad
			Run_Diag
		
		fi
	elif [[ "$list_stn" =~ "$current_stc_name" ]]; then
		show_fail_message "Current Station is $current_stc_name, need more spare parts Please check!!!"
		pause
		diag_name=$(get_config "$Diag1")
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
	read -p "Please Input station :" station
	#echo $station
	#pause
	if [[ "$list_st_all" =~ "$station" ]];then
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
	else
		show_fail_message "station wrong please check!!!"
		exit 1
	fi	
fi	
}

upload_start_log()
{
    start_log_time=`date +"%Y%m%d_%H%M%S"`
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
		cp -rf *$1*.log ${Logs_Path}/$PROJECT/${Input_Upper_PN}
		cp -rf *$1*.log ${Local_Logs}
		rm -rf *$1*	
	else
		Input_Server_Connection
		if [ -d ${Logs_Path}/$PROJECT ]; then
			[ ! -d ${Logs_Path}/$PROJECT/${Input_Upper_PN} ] && mkdir ${Logs_Path}/$PROJECT/${Input_Upper_PN}
			cp -rf *$1*.log ${Logs_Path}/$PROJECT/${Input_Upper_PN}
			cp -rf *$1*.log ${Local_Logs}
			rm -rf *$1* 
		else
			show_fail_message "show_fail_message Mounting log server fail."
			exit 1 
		fi	
		
	fi	

}

#####wareconn control script version#####
script_check()
{

	if [ "${Script_VER}" = "${Input_Script}" ];then
		echo "Script Version is ${Script_VER}"
	else
		echo "Script Version is ${Script_VER}"
		if [ -f $Script_File ];then
			cp -rf $Script_File /home/diags/nv
			sleep 15
			reboot
		else
			Input_Server_Connection
			if [ -f $Script_File ];then
				cp -rf $Script_File /home/diags/nv
				sleep 15
				reboot
			else
				show_fail_msg "not exsit script please check"
				exit 1
			fi
		fi		
	fi	


}

#####before test Prepare some files####2024-06-04
prepare_file()
{


	#DFX=$(get_config "Diag3")
	if [ -f $1/$2 ];then
		show_pass_message "$2 already exist!!!"		
	else
		#echo "${Diag_Path}/HEAVEN/$HEAVEN_VER"
		#pause
		if [ -f ${Diag_Path}/HEAVEN/$2 ]; then
			show_pass_message "DownLoad $2 From Server Please Waiting ..."
			cp -rf ${Diag_Path}/HEAVEN/$2 $1
			cd $1
			tar -xf $2 
			if [ $? -ne 0 ];then
				show_fail_message "Please make sure exist $2 zip files"
				show_fail_msg "DownLoad $2 file FAIL"
				exit 1
			else
				show_pass_msg "DownLoad $2 pass"
			fi		
		else
			Input_Server_Connection
			if [ -f ${Diag_Path}/HEAVEN/$2 ]; then
				show_pass_message "DownLoad $2 From Server Please Waiting ..."
				cp -rf ${Diag_Path}/HEAVEN/$2 $1
				cd $1
				tar -xf $2
				if [ $? -ne 0 ];then
					show_fail_message "Please make sure exist $2 file zip files"
					show_fail_msg "DownLoad $2 file FAIL"
					exit 1
				else
					show_pass_msg "DownLoad $2 pass"
				fi		
			else
				show_fail_message "$2 file isn't exist Please Call TE"
				show_fail_msg "DownLoad $2 file FAIL"
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
get_bios(){	
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

#############################################################################################################
#############################################################################################################
####Main Part####
#################

#export flow_name="${current_stc_name}"
rm -rf $LOGFILE/*
rm -rf $mods/log.txt
echo "" > /var/log/message
if [ ! -f $OPID ];then
	Input_Server_Connection
fi	
ntpdate $NC_diagserver_IP
hwclock -w
export start_time=$(date '+%F %T')
rmmod nvidia_drm nvidia_modeset nvidia
Read_SN

if [ -f $SCANFILE ]; then
	Output_Scan_Infor
	# Scan_Upper_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number=" | awk -F '=' '{print$2}'))
	# Scan_Lower_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number2=" | awk -F '=' '{print$2}'))

	# if [ $testqty = 2 ];then
		# if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ] && [ "${Scan_Lower_SN}" == "${Output_Lower_SN}" ]; then
			# show_pass_message "Local Scan Info Have exist "
		# else
			# Output_Scan_Infor
			# Scan_Upper_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number=" | awk -F '=' '{print$2}'))
			# Scan_Lower_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number2=" | awk -F '=' '{print$2}'))
			# if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ] && [ "${Scan_Lower_SN}" == "${Output_Lower_SN}" ]; then
				# echo ""
			# else
				# show_fail_message "Scan Wrong Please Check!!!!"
				# exit 1
			# fi	
		# fi
	# else
		# if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ]; then
			# show_pass_message "Local Scan Info Have exist "
		# else
			# Output_Scan_Infor
			# Scan_Upper_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number=" | awk -F '=' '{print$2}'))
			# if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ]; then
				# echo ""
			# else
				# show_fail_message "Scan Wrong Please Check!!!!"
				# exit 1
			# fi	
		# fi
	# fi	
		
else
	if [ -f "uutself.cfg.env" ]; then
		rsync -av uutself.cfg.env $mods/cfg/
		Output_Scan_Infor
		# if [ $testqty = 2 ];then
			# Scan_Upper_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number=" | awk -F '=' '{print$2}'))
			# Scan_Lower_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number2=" | awk -F '=' '{print$2}'))
			# if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ] && [ "${Scan_Lower_SN}" == "${Output_Lower_SN}" ]; then
				# echo ""
			# else
				# show_fail_message "Scan Wrong Please Check!!!!"
				# exit 1
			# fi
		# else
			# Scan_Upper_SN=$(echo $(cat ${SCANFILE} | grep "^serial_number=" | awk -F '=' '{print$2}'))
			# if [ "${Scan_Upper_SN}" == "${Output_Upper_SN}" ]; then
				# echo ""
			# else
				# show_fail_message "Scan Wrong Please Check!!!!"
				# exit 1
			# fi
		# fi	
	else
		show_fail_message "uutself.cfg.env is not exist please call TE!!!"
		exit 1 
	fi	
fi	

#echo $testqty

if [ $testqty = "2" ]; then
	if [ $Run_Mode = "0" ];then
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
		Input_Wareconn_Serial_Number_RestAPI_Mode ${Output_Upper_SN}
		Input_Upper_PN=$(grep "900PN" $mods/cfg/${Output_Upper_SN}.RSP | awk -F '=' '{ print $2 }'  )
		Input_Upper_Station=$(grep "current_stc_name" $mods/cfg/${Output_Upper_SN}.RSP | awk -F '=' '{ print $2 }'  )
		Input_Wareconn_Serial_Number_RestAPI_Mode ${Output_Lower_SN}
		Input_Lower_PN=$(grep "900PN" $mods/cfg/${Output_Lower_SN}.RSP | awk -F '=' '{ print $2 }'  )
		Input_Lower_Station=$(grep "current_stc_name" $mods/cfg/${Output_Lower_SN}.RSP | awk -F '=' '{ print $2 }'  )

		if [ ${Input_Upper_PN} = ${Input_Lower_PN} ]; then
			analysis_sta
		else
			show_fail_message "make sure the cards PN and station is right!!! "
			show_fail_message "!!!! ${Input_Upper_PN}:${Input_Upper_Station}!!!!${Input_Lower_PN}:${Input_Lower_Station}!!!!"
			exit 1
		fi
	fi		
else
	Input_Wareconn_Serial_Number_RestAPI_Mode ${Output_Upper_SN}
	analysis_sta
fi	


