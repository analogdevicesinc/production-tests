#!/bin/bash
SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

echo "[1] Loading device-tree overlay..."
if sudo dtoverlay -l | grep -q "rpi-cn0591-class12"; then
    echo "Overlay already loaded. No action needed."
else
    sudo dtoverlay rpi-cn0591-class12
fi

$SCRIPT_DIR/port_1.sh
echo "[2] Ping test to -ad-apard32690-sl"
sleep 5
ping -c3 192.168.97.50
if [ $? -eq 0 ]; then
    RESULT=0
    echo_green "PASSED"
else
    RESULT=1
    echo_red "FAILED"
fi

$SCRIPT_DIR/port_2.sh
sudo dtoverlay -r rpi-cn0591-class12
sleep 2
if sudo dtoverlay -l | grep -q "rpi-cn0591-class12"; then
    echo "Overlay already loaded. No action needed."
else
    sudo dtoverlay rpi-cn0591-class12
fi

echo "[3] Ping test to swiot"
sleep 3
ping -c3 192.168.97.60
if [ $? -eq 0 ]; then
    RESULT=0
    echo_green "PASSED"
else
    RESULT=1
    echo_red "FAILED"
fi