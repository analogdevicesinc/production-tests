#!/bin/bash
# Wrapper script for doing a production cycle/routine for Power Quality 
# Monitor

# Can be called with:  ./production_PQM.sh

SCRIPT_DIR="$(readlink -f $(dirname $0))"
ScriptLoc="$(readlink -f "$0")"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
    echo_red "Please make sure the Raspberry Pi is connected to Wi-fi"
    echo_blue "Please enter your choice: "
    options=("System Test" "Power-off Pi")
    select opt in "${options[@]}"; do
        case $REPLY in
        1)
            echo_blue "Starting system test"
            production "crr" "$opt" "PQM"
            break ;;
        2) 
            enforce_root
            poweroff
            break 2;;

        *) echo "Invalid option $REPLY";;

        esac

    done
done