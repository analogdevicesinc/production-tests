#!/bin/bash
SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh

ifconfig eth1 up
ip addr add 169.254.97.30/24 dev eth1 || true
sleep 2

ping_output=$(ping -c3 169.254.97.40 || true)
if echo "$ping_output" | grep -q "100% packet loss"; then
    echo_red "Host is unreachable."
    echo $ping_output
    ifconfig eth1 down
    exit 1
else
    echo $ping_output
    ifconfig eth1 down
    exit 0
fi


