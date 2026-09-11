#!/bin/bash
SCRIPT_DIR="$(readlink -f $(dirname $0))"
ScriptLoc="$(readlink -f "$0")"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
        echo_blue "Please enter your choice: "
        options=("System Test" "Power-Off Pi")
        select opt in "${options[@]}"; do
            case $REPLY in
                        1)
                                echo_blue "System Test"
                                production "crr" "$opt" "RPIPLCPSE"
                                break ;;
                        2)
                                enforce_root
                                poweroff
                                break 2 ;;
                        *) echo "invalid option $REPLY";;
            esac
        done
done