#!/bin/bash
##**********************************************************************************
## Project       : NVIDIA
## Filename      : pci_lane_check.sh
## Description   : Counts number of lanes per GPU to preemptively catch errors/fails
##                 to conserve on time
## Usage         : n/a
##
## Version History
##-------------------------------
## Version       : 1.0.0
## Release date  : 2025-08-26
## Revised by    : Janet Mbugua
## Description   : Initial release
##**********************************************************************************

. /mnt/nv/mods/test/commonlib

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
PURPLE='\e[35m'
NOCOLOR='\e[0m'
WHITE='\e[47m'

# Counts the number of boards inserted into the tester
counts=$(./nvflash_mfg -A -a | grep "10DE" | wc -l)
pass=0

UNIT_1=$(lspci | grep NV | head -n 1 | awk '{ print $1 }')

PN=$(./nvflash_mfg -B $UNIT_1 --rdobd | grep "BoardPartNumber:" | head -1 | sed 's/.*: *//')
gunit="${PN:5:4}"

lanes=""
speed=""

# Reads the port code to insert into nvflash and grep for the specific unit (Doesnt matter if single unit is 1 or 2)
UNIT_1=$(lspci | grep NV | head -n 1 | awk '{ print $1 }')
UNIT_2=$(lspci | grep NV | tail -n 1 | awk '{ print $1 }')


main()
{
if [[ $counts -gt 1 ]]; then
    echo -e "${YELLOW}Two units detected, checking both units...${NOCOLOR}"
    printf "${PURPLE}%-80s${NOCOLOR}\n" "------------------------------ Left Unit ------------------------------"
    lane_check $UNIT_1
    speed_check $UNIT_1 $gunit
    printf "${PURPLE}%-80s${NOCOLOR}\n" "------------------------------ Right Unit ------------------------------"
    lane_check $UNIT_2
    speed_check $UNIT_2 $gunit
elif [[ $counts -eq 1 ]]; then
    echo -e "${YELLOW}Single unit detected, checking unit...${NOCOLOR}"
    lane_check $UNIT_1
    speed_check $UNIT_1 $gunit
else
    echo -e "${RED}No units detected, exiting...${NOCOLOR}"
    exit 1
fi

sleep 2

if [[ $pass == 0 ]]; then
    echo -e "\n${GREEN}All PCIe checks passed.${NOCOLOR}"
    exit 0
else
    echo -e "\n${RED}One or more PCIe checks failed.${NOCOLOR}"
    exit 1
fi
}

lane_check() 
{
    local port=$1
    lanes=$(lspci -vv -s $port | grep "LnkSta:" | awk '{ print $5 }' | sed 's/,$//')
    echo -e "\n${WHITE}${BLUE}Port: $port SHOULD have x16 lanes${NOCOLOR}${NOCOLOR}\n"

    if [[ $lanes == "x16" ]]; then
        echo -e "${GREEN}Success: Port $port has sufficient lanes (${lanes} lanes)${NOCOLOR}\n"
    else
        echo -e "${RED}Error: Port $port has less than 16 lanes (${lanes} lanes)${NOCOLOR}\n"
        pass=1
    fi
}

speed_check()
{
    local port=$1
    local PN=$2
    speed=$(lspci -vv -s $port | grep "LnkSta:" | awk '{ print $3 }' | sed 's/,$//')

    if [[ $PN == 'G520' || $PN == 'G525' ]]; then 
        echo -e "${WHITE}${BLUE}Port: $port is SHOULD be running at unknown GT/s ${NOCOLOR}${NOCOLOR}\n"
        if [[ $speed == "unknown" ]]; then
            echo -e "${GREEN}Success: Port $port has sufficient speed ${PURPLE}(${speed} GT/s)${NOCOLOR}\n"
        else 
            echo -e "${RED}Error: Port $port has less than 8 GT/s ${PURPLE}(${speed} GT/s)${NOCOLOR}\n"
            pass=1
        fi
    else
        echo -e "${WHITE}${BLUE}Port: $port is SHOULD be running at 8 GT/s ${NOCOLOR}${NOCOLOR}\n"
        if [[ $speed == "8GT/s" ]]; then
            echo -e "${GREEN}Success: Port $port has sufficient speed ${PURPLE}(${speed})${NOCOLOR}\n"
        else
            echo -e "${RED}Error: Port $port has less than 8 GT/s ${PURPLE}(${speed})${NOCOLOR}\n"
            pass=1
        fi
    fi
}

main