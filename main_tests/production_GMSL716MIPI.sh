#!/bin/bash

# Wrapper script for doing a production cycle/routine for a GMSL716MIPI.

SCRIPT_DIR="$(readlink -f $(dirname $0))"
ScriptLoc="$(readlink -f "$0")"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
        echo_blue "Please enter your choice: "
        options=("Communication Test" "Data streaming Test")
        select opt in "${options[@]}"; do
                case $REPLY in
                        1)
                                echo_blue "Starting Communication Test"
                                production "crr" "$opt" "GMSL716MIPI"
                                break ;;

                        2)
                                echo_blue "Starting Data streaming Test"
                                production "crr" "$opt" "GMSL716MIPI"
                                break ;;

                        *) echo "invalid option $REPLY";;
                esac
        done
done