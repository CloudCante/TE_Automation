#! /bin/bash
# ***************************************************
# **                                               **
# **  Download Shell for DGX Station A100          **
# **  NVIDIA Test System.                          **
# **  Author :Winter Liu                           **
# **  Rev By : Rick Stingel       Rev:2025-01-27   **
# **                                               **
# ***************************************************
Version=1.1.0

####################################################################################################
######## Preconditions ########
####################################################################################################
sudo timedatectl set-timezone America/New_York
[ -d /var/diags/test/ ] || sudo mkdir -p /var/diags/test/ && sudo chmod -R 777 /var/diags/test
[ -d /var/diags/back/ ] || sudo mkdir -p /var/diags/back/ && sudo chmod -R 777 /var/diags/back
[ -d /var/diags/diagpath ] || sudo mkdir -p /var/diags/diagpath && sudo chmod -R 777 /var/diags/diagpath
[ -d /var/diags/download/ ] || sudo mkdir -p /var/diags/download && sudo chmod -R 777 /var/diags/download

####################################################################################################
######## Define Global Variables ########
####################################################################################################
export download="/var/diags/download/"
export mods="/var/diags/diagpath"

####################################################################################################
######## Functions ########
####################################################################################################

#####################################################################
#                                                                   #
# Get Heaven                                                        #
#                                                                   #
# Purpose: Check the HEAVEN config file exists                      #
#####################################################################
get_heaven()
{
    echo $(cat /mnt/nv/mods/HEAVEN.cfg | grep "^${1}" | awk -F '\"' '{print$2}')
    if [ 0 -ne $? ] ; then
        echo "${1} config not found.(${CFGFILE})" | tee -a $LOGFILE/log.txt
        show_fail_message "Config Not Found" && exit 1
    fi
}

#####################################################################
#                                                                   #
# Pause                                                             #
#                                                                   #
# Purpose: Wait for the user to acknowledge                         #
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
# Run Test                                                          #
#                                                                   #
# Purpose: Run the test after download completed                    #
#####################################################################
run_test()
{
    echo -e "\e[32m"
    echo "     ******************************************************"
    echo "     **                                                  **"
    echo "     ** The Diags Download OK                            **"
    echo "     ** Please press any key to start function test      **"
    echo "     **                                                  **"
    echo "     ******************************************************"
    echo -e "\e[0m"
    pause
    cd $mods
    sudo ./flow_ft.sh
    pwd
    exit 0
}

#############################################################################################################
######## Main ########
#############################################################################################################
# Check if the script is run with sudo privileges
# If not, re-run the script with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "\033[93mThis script requires sudo privileges. Re-running with sudo...\033[0m"
    exec sudo bash "$0"
    # Exit after, since we have recursively called the script with sudo
    exit 0
fi

cd $mods
status=0
flg=0

if ! mountpoint -q $download || ! mount | grep -q "//192.168.102.21/e/current"; then
    sudo umount $download >/dev/null 2>&1
    sudo mount -t cifs -o username="Administrator",password="TJ77921~" //192.168.102.21/e/current $download >/dev/null 2>&1
    if [ $? -ne 0 ];then
        echo -e  "\033[0;31m Mounting Diag server fail. \033[0m"
        exit 1
    fi
fi

#if we are already running the script on the diag server, do not compare the scripts
if [ $0 == "${download}$(basename $0)" ]; then
    continue
elif ! grep -q "Version=$Version" "${download}$(basename $0)"; then
    echo -e "\033[93mVersion mismatch detected...\033[0m"
    echo -e "\033[93mPlease contact a TE to update the PXE image...\033[0m"
    pause
    echo -e "\033[93mRunning $(basename $0) from diag...\033[0m"
    sleep 3
    exec sudo bash "$0"
    exit 0
fi

while [ $status = 0 ]; do
    if [ $flg = 1 ]; then
        echo -e "\e[31m" 
        echo -n "P/N Input Error,Please Input Again:" 
        echo -en "\e[0m"
        read -p "" pn
    else
        clear
        echo -e "\e[32m" 
        read -p "Please Input Board PN:" pn
        echo -en "\e[0m"
    fi

    #convert the part number to upper case
    pn=$(echo "$pn" | tr '[:lower:]' '[:upper:]')

    a=`echo $pn |wc -c`
    if [ "$a" -eq 19 ] || [ "$a" -eq 11 ] || [ "$a" -eq 21 ]; then
        status=1
    else
        flg=1
    fi
done

if [ -d "/var/diags/diagpath/$pn" ]; then
    run_test

elif [ -d "/var/diags/download/$pn" ]; then
    sudo rm -rf $mods/*
    echo "Diags downloading,Please wait a second..."
    echo y | sudo cp -fr $download/$pn/*MFG*/* $mods
    sudo tar xf *.tar.gz
    cd $mods/FW
    sudo tar xf *.tar.gz
    run_test

else
    echo "\e[31m"
    echo "     Diags Download Fail..."
    echo "     ********************************************************"
    echo "     *                                                      *"
    echo "     *   The Diags for $pn not found         *"
    echo "     *   It's must be a new part number                     *"
    echo "     *   Please call Engineer to check...                   *"
    echo "     *                                                      *"
    echo "     ********************************************************"
    echo "\e[0m"

fi  

