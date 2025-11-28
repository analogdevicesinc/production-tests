#!/bin/bash
# Wrapper script for doing a production cycle/routine for 60ghz-connecter

# Can be called with:  ./production_60GHZ.sh

SCRIPT_DIR="$(readlink -f $(dirname $0))"
ScriptLoc="$(readlink -f "$0")"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
    echo_red "Please make sure the Raspberry Pi is connected to Wi-fi"
    echo_blue "Please enter your choice: "
    options=("Provisioning" "ADMV96x5 Test" "Networking Test" "Power-off Pi")
    select opt in "${options[@]}"; do
        case $REPLY in

        1)
			echo_blue "Starting Provisioning"
			production "crr" "$opt" "60GHZ"
			break ;;
        
        2)  
            echo_blue "Starting ADMV96x5 Test"
			production "crr" "$opt" "60GHZ"
			break ;;
        3)  
            echo_blue "Starting Networking Test"
			production "crr" "$opt" "60GHZ"
			break ;;
        
        4) 
            enforce_root
            poweroff
            break 2;;

        *) echo "Invalid option $REPLY";;

        esac

    done
done
