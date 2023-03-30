#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh
source $SCRIPT_DIR/mac_write.sh

TEST_ID="01"
SHORT_DESC="Write MAC addresses on ENV partition"
CMD="TTY_PORT=\"/dev/\$(dmesg | grep tty | grep \"cp210x converter now attached to\" | awk '{print \$10}')\";"
CMD+="\$(get_mac);"
CMD+="MAC_ADDR=\$(cat mac_file.txt);"
CMD+="echo \"\$TTY_PORT\";"
CMD+="echo \"\$MAC_ADDR\";"
CMD+="\$SCRIPT_DIR/write_mac_uboot.expect \$TTY_PORT \$MAC_ADDR"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Reset device"
CMD="TTY_PORT=\"/dev/\$(dmesg | grep tty | grep \"cp210x converter now attached to\" | awk '{print \$10}')\" ;"
CMD+="sleep 2;"
CMD+="$SCRIPT_DIR/reset_device.expect \$TTY_PORT"
run_test $TEST_ID "$SHORT_DESC" "$CMD"
