#!/bin/bash
##**********************************************************************************
## Project       : NVIDIA
## Filename      : validate_logs.sh
## Description   : Helps wareconn sync up with the tester by finding the logs in it 
##                 and validating them with the current station
## Usage         : n/a
##
## Version History
##-------------------------------
## Version       : 1.0.0
## Release date  : 2025-05-29
## Revised by    : Janet Mbugua
## Description   : Initial release
##**********************************************************************************

. /mnt/nv/mods/test/commonlib

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Re-running with sudo..."
    sudo "$0" "$@"
    exit
fi

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
ORANGE="\033[38;5;208m"
NOCOLOR="\033[0m"

# Counts the number of boards inserted into the tester
counts=$(./nvflash_mfg -A -a | grep "10DE" | wc -l)

# Reads the port code to insert into nvflash and grep for the specific unit (Doesnt matter if single unit is 1 or 2)
UNIT_1=$(lspci | grep NV | head -n 1 | awk '{ print $1 }')
UNIT_2=$(lspci | grep NV | tail -n 1 | awk '{ print $1 }')

answer=""
manual=false
no_of_units=0
logs=""
station_index=-1

PN=""
SN=""

log_path=""
backup_path=""
local_path="/mnt/nv/logs/"
destination_path=""

CURRENT_STATION=""
station_found=false

# Station arrays for G506, G510, and G520 (CHIFLASH test shows up as 2nd FLA in the logs)
G506=( "FLA" "BAT" "BIT" "FCT" "FPF" "OQA" "ASSY2" )
G510=( "FLA" "BAT" "BIT" "FCT" "FPF" "OQA" "ASSY2" )
G520=( "FLA" "FLA" "FLB" "FLC" "PHT" "BAT" "BIT" "FCT" "EFT" "IST" "FPF" "OQA" "ASSY2" )
G525=( "FLA" "BAT" "BIT" "FCT" "IOT" "DG5" "IST" "PDT" "FPF" "ASSY2" )
adj_pn=""


validated_logs=()

introductory_queries() {
    while [[ "$testing_choice" != "y" && "$testing_choice" != "n" && "$testing_choice" != "Y" && "$testing_choice" != "N" ]]; do
        read -p "Are you checking for the local unit plugged into the tester, instead of inserting the SN and PN manually? (y/n): " testing_choice
        if [[ "$testing_choice" == "y" || "$testing_choice" == "Y" ]]; then
            manual=false
            echo -e "${YELLOW}You chose to check the local unit plugged into the tester.${NOCOLOR}"
        elif [[ "$testing_choice" == "n" || "$testing_choice" == "N" ]]; then
            manual=true
            echo -e "${YELLOW}You chose to insert the SN and PN manually.${NOCOLOR}"
        else
            echo -e "${RED}Invalid input. Please enter 'y' or 'n'.${NOCOLOR}"
        fi
    done
  
}

manual_main() {
    SN=$1
    PN=$2
    current_station
    find_logs
    validate_logs
    download_logs
}

automated_main() {
    port_code=$1
    read_sn_and_pn "$port_code"
    current_station
    find_logs
    validate_logs
    download_logs
}

read_sn_and_pn(){
	# Making a unique directory to store files into/cleaning up anything prior
	local port=$1
	[ -f "janet" ] && rm -rf "janet"
	
	mkdir "janet"

	./nvflash_mfg -B $port --rdobd | tee -a "janet/log.txt"
	
	# Scrapes the 5 data points from wareconn we want to compare to our local unit
	SN=`grep "BoardSerialNumber:" "janet/log.txt" | head -1 | sed 's/.*: *//'`
	PN=`grep "BoardPartNumber:" "janet/log.txt" | head -1 | sed 's/.*: *//'`

	rm -rf "janet"

    echo -e "${GREEN}Serial Number: ${NOCOLOR}$SN"
    echo -e "${YELLOW}Part Number: ${NOCOLOR}$PN"
}

# ALL DONE
current_station() {
    log_path="/mnt/nv/server_logs/TESLA/${PN}"
    backup_path="/mnt/nv/server_logs/backup/TESLA/${PN}"
    destination_path="/mnt/nv/validated_logs/${PN}/${SN}"
    
    echo "Checking current station left off in wareconn..."
    sleep 3

    IP="192.168.102.20"
	token=$(./get_token.sh $IP)
	
	# --- Config ---
	CLIENT_ID="vE7BhzDJhqO"
	CLIENT_SECRET="0f40daa800fd87e20e0c6a8230c6e28593f1904c7edfaa18cbbca2f5bc9272b5"
	GRANT_TYPE="client_credentials"

	TOKEN_URL="http://${IP}/api/v1/Oauth/token"
	ITEM_INFO_URL="http://${IP}/api/v1/ItemInfo/get"
	TEST_PROFILE_URL="http://${IP}/api/v1/test-profile/get"

	echo "Input IP: $IP, SN: $SN"
	# --- Check input ---
	if [ -z "$SN" ]; then
        echo "Usage: $0 <serial_number>"
        exit 1
	fi

	# --- Get Token ---
	echo " Requesting token..."
	response=$(curl -s -X GET "${TOKEN_URL}?client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&grant_type=${GRANT_TYPE}")
	token=$(echo "$response" | awk -F '"' '{print $10 }')

	if [ -z "$token" ] || [ "$token" == "null" ]; then
        echo " Failed to get token."
        echo "$response"
        exit 1
	else
        echo " Token received."
	fi

	# --- Get Item Info ---
	echo " Getting item info for SN: $SN"
	item_response=$(curl -s -X GET "$ITEM_INFO_URL" \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer $token" \
	-d "{\"serial_number\": \"$SN\"}")

	echo "$item_response" | jq '.' > item_info.json
	echo " Item info saved to item_info.json"

	# --- Get Test Profile ---
	echo " Getting test profile for SN: $SN"
	profile_response=$(curl -s -X GET "$TEST_PROFILE_URL" \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer $token" \
	-d "{\"serial_number\": \"$SN\", \"type\": \"war,sta\"}")

	echo "$profile_response" | jq '.' > test_profile.json
	echo " Test profile saved to test_profile.json"

	# --- Summary Preview (Optional) ---
	echo "-----------------------------"
	echo " Summary:"
	#jq '{bios: .data.bios, part_number: .data.part_number}' item_info.json
	#jq '{process: .list.stf_process, result: .list.test_result}' test_profile.json
	echo "-----------------------------"

	# Side note: jq syntax does not allow regular syntax for keys with numbers, so we have to use brackets to access them
	CURRENT_STATION=$(jq -r '.data.current_stc_name // empty' test_profile.json)
}

# ALL DONE
find_logs() {
    # Attaching the current station to the index it belongs to in the list
    adj_pn="${PN:5:4}"
    GPN="${PN:5:4}"

    if [[ "$adj_pn" == "G506" ]]; then
        adj_pn="${G506[@]}"
    elif [[ "$adj_pn" == "G510" ]]; then
        adj_pn="${G510[@]}"        
    elif [[ "$adj_pn" == "G520" ]]; then
        adj_pn="${G520[@]}"
    elif [[ "$adj_pn" == "G525" ]]; then
        adj_pn="${G525[@]}"
    else
        echo "Unknown PN: $PN"
        exit 1
    fi
    
    # Convert adj_pn string to array if necessary and find the length (so hard for some reason??)
    IFS=' ' read -r -a adj_pn <<< "$adj_pn"

    # Find the current station in the list of stations for the PN
    for ((i=0; i<${#adj_pn[@]}; i++)); do
        if [[ "${adj_pn[$i]}" == "$CURRENT_STATION" ]]; then
            station_index=$i
        fi
    done

    if [[ $station_index -eq -1 ]]; then
        echo -e "${YELLOW}Current station $CURRENT_STATION not found in the list of stations for PN: $PN${NOCOLOR}"

        exit 1
    fi

    # Find logs from all three paths, remove duplicates, and sort them in reverse order
    logs=$(find "${log_path}" "${backup_path}" "${local_path}" -maxdepth 1 -type f -name "*${PN}_${SN}_P*.log" 2>/dev/null | sort -u | sort -r)

    echo -e "Logs: \n${YELLOW}$logs${NOCOLOR}\n"

}

validate_logs() {
    # Create an array of completed stations from adj_pn[0] to adj_pn[station_index]
    completed_stations=("${adj_pn[@]:0:$((station_index+1))}")

    for log_file in $logs; do
        # Extract the filename from the path
        filename=$(basename "$log_file")
        
        # Get the last 23 characters
        last23="${filename: -20}"
        # Remove the last 3 characters to get the timestamp
        timestamp="${last23:0:${#last23}-5}"
        # Remove the 9th and 16th character from timestamp
        timestamp="${timestamp:0:8}${timestamp:9:7}${timestamp:16}"
        
        # Save the 50th-52nd characters from the log_file into the variable 'stn'
        if [[ $GPN == "G525" ]]; then
            stn="${filename:43:3}"
        else
            stn="${filename:49:3}"
        fi
        echo "Station code (stn): $stn"

        # Check if stn is in completed_stations
        stn_found=false
        for completed in "${completed_stations[@]}"; do
            if [[ "$stn" == "$completed" ]]; then
                stn_found=true
                # Remove 'completed' from completed_stations array (optimized)
                for idx in "${!completed_stations[@]}"; do
                    if [[ "${completed_stations[$idx]}" == "$completed" ]]; then
                        unset 'completed_stations[idx]'
                        completed_stations=("${completed_stations[@]}")
                        break
                    fi
                done
                break
            fi
        done



        # Checks if the log file is of the correct station and 
        if [[ "$stn_found" == true ]]; then
            validated_logs+=("$log_file")
            echo -e "${GREEN}Validated: $filename (station: $stn, timestamp: $timestamp)${NOCOLOR}"
        else
            echo -e "${RED}Invalid log: $filename (station: $stn, timestamp: $timestamp)${NOCOLOR}"
        fi
    done
}

# Validating the logs in chronological order, as far as 2 weeks back
# validate_logs() {
#     # Create an array of completed stations from adj_pn[0] to adj_pn[station_index]
#     completed_stations=("${adj_pn[@]:0:$((station_index+1))}")
#     echo "Completed stations: ${completed_stations[@]}"

#     for log_file in $logs; do
#         # Extract the filename from the path
#         filename=$(basename "$log_file")
#         # Get the last 23 characters
#         last23="${filename: -20}"
#         # Remove the last 3 characters to get the timestamp
#         timestamp="${last23:0:${#last23}-5}"
#         # Remove the 9th and 16th character from timestamp
#         timestamp="${timestamp:0:8}${timestamp:9:7}${timestamp:16}"
#         echo "$timestamp"
 
#         # Save the 50th-52nd characters from the log_file into the variable 'stn'
#         stn="${filename:49:3}"
#         echo "Station code (stn): $stn"

#         # Convert timestamps to seconds since epoch for comparison
#         # log_time is the timestamp from the filename (format: YYYYMMDDHHMMSS)
#         log_time_epoch=$(date -u -d "${timestamp:0:4}-${timestamp:4:2}-${timestamp:6:2} ${timestamp:8:2}:${timestamp:10:2}:${timestamp:12:2}" +"%s" 2>/dev/null)
#         # current_time is the current UTC time
#         current_time_epoch=$(date -u +"%s")

#         # Two weeks in seconds
#         two_weeks=$((14 * 24 * 60 * 60 * 2))

#         # Check if stn is in completed_stations
#         stn_found=false
#         for completed in "${completed_stations[@]}"; do
#             if [[ "$stn" == "$completed" ]]; then
#                 stn_found=true
#                 break
#             fi
#         done

#         # Used for debugging purposes
#         # difference=$((current_time_epoch - two_weeks))
#         # echo "Log time: $log_time_epoch"
#         # echo "Current time: $current_time_epoch"
#         # echo "two_weeks: $two_weeks"        
#         # echo "Difference: $difference"

#         if [[ $log_time_epoch -ge $((current_time_epoch - two_weeks)) && "$stn_found" == true ]]; then
#             validated_logs+=("$log_file")
#             echo -e "${GREEN}Validated: $filename (station: $stn, timestamp: $timestamp)${NOCOLOR}"
#         else
#             echo -e "${RED}Invalid log: $filename (station: $stn, timestamp: $timestamp)${NOCOLOR}"
#         fi

#     done
# }

# ALL DONE
download_logs() {
    while [[ "$answer" != "y" && "$answer" != "n" && "$answer" != "Y" && "$answer" != "N" ]]; do
        read -p "Do you want to download the logs you found? (y/n)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            
            for file in "${validated_logs[@]}"; do
                if [ ! -d "$destination_path" ]; then
                    mkdir -p "$destination_path"
                fi
                cp "$file" "$destination_path"
                if [ $? -ne 0 ]; then
                    echo "Failed to copy $file to $destination_path"
                    continue
                fi
                echo "Downloaded: $file"
            done

        elif [[ "$answer" == "n" || "$answer" == "N" ]]; then
            echo "No logs downloaded."
        else
            echo "Invalid input. Please enter 'y' or 'n'."
        fi
    done
}

main() {
    introductory_queries
    if [[ "$manual" == true ]]; then
        read -p "How many units are you searching logs for?: " no_of_units
        i=0
        while [[ $i -lt $no_of_units ]]; do
            read -p "Enter Part Number (PN) for unit $((i+1)): " PN
            read -p "Enter Serial Number (SN) for unit $((i+1)): " SN
            manual_main "$SN" "$PN"
            ((i++))
        done
    else
        if [[ ${counts} -eq 1 ]]; then
            echo -e "${YELLOW}Only one unit detected. Proceeding with automated validation for the single unit...${NOCOLOR}"
            sleep 2
            automated_main "$UNIT_1"
        elif [[ ${counts} -eq 2 ]]; then
            echo -e "${YELLOW}Two units detected. Proceeding with automated validation for both units...${NOCOLOR}"
            sleep 2
            automated_main "$UNIT_1"
            automated_main "$UNIT_2"
        else
            echo -e "${RED}No units detected. Please insert a unit into the tester and try again.${NOCOLOR}"
            exit 1
        fi
    fi
}

main