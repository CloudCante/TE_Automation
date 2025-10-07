#!/bin/bash
##**********************************************************************************
## Project       : NVIDIA
## Filename      : inforcheck_debug.sh
## Description   : Displays the reasoning behind an inforom fail on a unit(s)
## Usage         : n/a
##
## Version History
##-------------------------------
## Version       : 1.0.0
## Release date  : 2025-05-16
## Revised by    : Janet Mbugua
## Description   : Initial release
##**********************************************************************************

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Re-running with sudo..."
    sudo "$0" "$@"
    exit
fi

# Global variables to color code message text 
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
NOCOLOR='\e[0m'

# Main two file paths being utilized
info_folder="cfg"

# Counts the number of boards inserted into the tester
counts=$(./nvflash_mfg_mfg -A -a | grep "10DE" | wc -1)

# Reads the port code to insert into nvflash and grep for the specific unit
UNIT_1=$(lspci | grep NV | head -n 1 | awk '( print $1 )')
UNIT_2=$(lspci | grep NV | tail -n 1 | awk '( print $1 )')

# Validating variables
CFG_SERIALNUMBER=""
CFG_BOARDPRODUCTPARTNUMBER=""
CFG_BOARD699PARTNUMBER=""
CFG_BIOS_VERSION=""
CFG_MARKETINGNAME=""

LOCAL_SERIALNUMBER=""
LOCAL_BOARDPRODUCTPARTNUMBER=""
LOCAL_BOARD699PARTNUMBER=""
LOCAL_BIOS_VERSION=""
LOCAL_MARKETINGNAME=""

STATUS_SERIALNUMBER=false
STATUS_BOARDPRODUCTPARTNUMBER=false
STATUS_BOARD699PARTNUMBER=false
STATUS_BIOS_VERSION=false
STATUS_MARKETINGNAME=false

wareconn_check()
{
	# Making a unique directory to store files into/cleaning up anything prior
	local port=$1
	[ -f "janet" ] && rm -rf "janet"
	
	mkdir "janet"

	./nvflash_mfg -B -$port --rdobd | tee -a ${serial_number}/log.txt
	
	# Scrapes the 5 data points from wareconn we want to compare to our local unit
	LOCAL_SERIALNUMBER=`grep "BoardSerialNumber:" "${serial_number}/log.txt" | head -1 | sed 's/.*: *//'`
	LOCAL_BOARDPRODUCTPARTNUMBER=`grep "BoardPartNumber:" "${serial_number}/log.txt" | head -1 | sed 's/.*: *//'`
    LOCAL_BOARD699PARTNUMBER=`grep "Board699PartNumber:" "${serial_number}/log.txt" | head -1 | sed 's/.*: *//'`
    LOCAL_MARKETINGNAME=`grep "MarketingName" "${serial_number}/log.txt" | head -1 | sed 's/.*: *//'`

	./nvflash_mfg -B -$port --version | tee -a "${serial_number}/bios_info.txt"

	LOCAL_BIOS_VERSION=`grep "VBIOS_VERSION" "${serial_number}/bios_info.txt" | head -1 | sed 's/.*: *//'`
	
	# Message text for debuging in case results_page() is not printing correctly
	# echo -e "${YELLOW}----------------------------------Local Stats----------------------------------${NOCOLOR}"
	# echo -e "SerialNumber: $LOCAL_SERIALNUMBER\nBoardProductPartNumber: $LOCAL_BOARDPRODUCTPARTNUMBER\nBoard699PartNumber: $LOCAL_BOARD699PARTNUMBER\nBiosVersion: $LOCAL_BIOS_VERSION\nMarketingName: $LOCAL_MARKETINGNAME\n"
	
	rm -rf ${serial_number}
}

local_check()
{
	# Scrapes the 5 data points from the local unit that we want to compare to wareconn
	CFG_SERIALNUMBER=$(get_config "serial_number")
	CFG_BOARDPRODUCTPARTNUMBER=$(get_config "900PN")
	CFG_BOARD699PARTNUMBER=$(get_config "699PN")
	CFG_MARKETINGNAME=$(get_config "MarketingName")
	CFG_BIOS_VERSION=$(get_config "BIOS1_VER") 
	# CFG_SERIALNUMBER=`grep "serial_number" ${info_folder}/cfg.ini | head -1 | sed 's/.*= *//'` 
    # CFG_BOARDPRODUCTPARTNUMBER=`grep "900PN" ${info_folder}/cfg.ini | head -1 | sed 's/.*= *//'` 
    # CFG_BOARD699PARTNUMBER=`grep "699PN" ${info_folder}/cfg.ini | head -1 | sed 's/.*= *//'` 
    # CFG_BIOS_VERSION=`grep "BIOS1_VER" ${info_folder}/cfg.ini | head -1 | sed 's/.*= *//'`
	# CFG_MARKETINGNAME=`grep "MarketingName" ${info_folder}/cfg.ini | head -1 | sed 's/.*= *//'` 

	# Message text for debuging in case results_page() is not printing correctly
	# echo -e "${YELLOW}----------------------------------Wareconn Stats----------------------------------${NOCOLOR}"
	# echo -e "SerialNumber: $CFG_SERIALNUMBER\nBoardProductPartNumber: $CFG_BOARDPRODUCTPARTNUMBER\nBoard699PartNumber: $CFG_BOARD699PARTNUMBER\nBiosVersion: $CFG_BIOS_VERSION\nMarketingName: $CFG_MARKETINGNAME\n" 
}

validate_output()
{
	# Compares each 5 data points from wareconn and the local unit and saves corresponding booleans that confirm if they are the same or otherwise
	if [[ $LOCAL_SERIALNUMBER != $CFG_SERIALNUMBER ]]; then
		echo -e "${RED}ERROR: Expected BoardSerialNumber: $CFG_SERIALNUMBER Found: $LOCAL_SERIALNUMBER${NOCOLOR}"
	else
		STATUS_SERIALNUMBER=true
	fi
	if [[ $LOCAL_BOARDPRODUCTPARTNUMBER != $CFG_BOARDPRODUCTPARTNUMBER ]]; then
		echo -e "${RED}ERROR: Expected BoardProductPartNumber: $CFG_BOARDPRODUCTPARTNUMBER Found: $LOCAL_BOARDPRODUCTPARTNUMBER${NOCOLOR}"
	else
		STATUS_BOARDPRODUCTPARTNUMBER=true
	fi	
	if [[ $LOCAL_BOARD699PARTNUMBER != $CFG_BOARD699PARTNUMBER ]]; then
		echo -e "${RED}ERROR: Expected Board699PartNumber: $CFG_BOARD699PARTNUMBER Found: $LOCAL_BOARD699PARTNUMBER${NOCOLOR}"
	else
		STATUS_BOARD699PARTNUMBER=true
	fi
	if [[ $LOCAL_BIOS_VERSION != $CFG_BIOS_VERSION ]]; then
		echo -e "${RED}ERROR: Expected Bios Version: $CFG_BIOS_VERSION Found: $LOCAL_BIOS_VERSION ${NOCOLOR}"
	else
		STATUS_BIOS_VERSION=true
	fi	
	if [[ $LOCAL_MARKETINGNAME != $CFG_MARKETINGNAME ]]; then
		echo -e "${RED}ERROR: Expected MarketingName: $CFG_MARKETINGNAME Found: $LOCAL_MARKETINGNAME ${NOCOLOR}"
	else
		STATUS_MARKETINGNAME=true
	fi	
}

results_page()
{
	# Prints the final output from the booleans, in color-coded fashion
	echo -e "\n${BLUE}================= RESULTS =================${NOCOLOR}\n"
	printf "| %-20s | %-20s | %-20s | %-20s |\n" "Parameter" "Wareconn" "Detected" "Status"| sed 's/^/ /'
	echo -e "--------------------------------------------------------------------------------"
	printf "| %-20s | %-20s | %-20s | %-20s |\n" "Serial Number" "$CFG_SERIALNUMBER" "$LOCAL_SERIALNUMBER" "$(pass_or_fail $STATUS_SERIALNUMBER)" | sed 's/^/ /'
	printf "| %-20s | %-20s | %-20s | %-20s |\n" "900PN" "$CFG_BOARDPRODUCTPARTNUMBER" "$LOCAL_BOARDPRODUCTPARTNUMBER" "$(pass_or_fail $STATUS_BOARDPRODUCTPARTNUMBER)" | sed 's/^/ /'
	printf "| %-20s | %-20s | %-20s | %-20s |\n" "699PN" "$CFG_BOARD699PARTNUMBER" "$LOCAL_BOARD699PARTNUMBER" "$(pass_or_fail $STATUS_BOARD699PARTNUMBER)" | sed 's/^/ /'
	printf "| %-20s | %-20s | %-20s | %-20s |\n" "VBIOS" "$CFG_BIOS_VERSION" "$LOCAL_BIOS_VERSION" "$(pass_or_fail $STATUS_BIOS_VERSION)" | sed 's/^/ /'
	printf "| %-20s | %-20s | %-20s | %-20s |\n" "Marketing Name" "$CFG_MARKETINGNAME" "$LOCAL_MARKETINGNAME" "$(pass_or_fail $STATUS_MARKETINGNAME)" | sed 's/^/ /'
	echo -e "--------------------------------------------------------------------------------"
}


pass_or_fail()
{
	# Takes the presaved booleans returned from validate_output() and prints them as 'Pass' or 'Fail' in the colors of green and red
    local status=$1
	if [[ $status == true ]]; then
		echo -e "${GREEN}Pass${NOCOLOR}"
    else
        echo -e "${RED}Fail${NOCOLOR}"
    fi
}

# main execution
if [[${counts} == 2]]; then
	wareconn_check $UNIT_1
	local_check
	validate_output
	results_page

	wareconn_check $UNIT_2
	local_check
	validate_output
	results_page
else
	wareconn_check $UNIT_1
	local_check
	validate_output
	results_page
fi

 