#!/bin/bash
SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

load_overlay(){
        echo "[1] Loading device-tree overlay..."
        if sudo dtoverlay -l | grep -q "rpi-cn0591-class12"; then
                echo "Overlay already loaded. No action needed"
        else
                sudo dtoverlay rpi-cn0591-class12
        fi
}


ping_function(){
        echo "Ping test..."
        IP="192.168.97.50"
        if ping -c 3 -W 1 "$IP" > /dev/null 2>&1; then
                echo_green "PASSED"
        else
                echo_red "FAILED"
                exit 1;
        fi
}

ping_function