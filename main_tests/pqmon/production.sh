#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

MODE="$1"
case $MODE in
    "System Test")
        # Upload and run test firmware
    	$SCRIPT_DIR/firmware_test.sh && {
    		echo_blue "Testing firmware upload successful!"
    	} || {
    		echo_red "Error uploading testing firmware!"
    		echo_blue "Note: Try power cycling the DUT by disconnecting and reconnecting the USB type C cable, then attempting the test again."
    		exit 1
    	}

        # Run tests
        export tty=/dev/ttyACM0
        echo_blue "Serial self-test starting..."
        $SCRIPT_DIR/system_test.sh || {
            handle_error_state "$BOARD_SERIAL"
            exit 1
        }

        echo_blue "Tests passed, uploading final production firmware..."
        $SCRIPT_DIR/firmware_final.sh && {
            echo_blue "Final production firmware upload successful!"
        } || {
            echo_red "Error uploading final production firmware!"
            echo_blue "Note: Try power cycling the DUT by disconnecting and reconnecting the USB type C cable, then attempting the test again."
            exit 1
        }
        ;;

    *) echo "Invalid option $MODE"
       exit 1
       ;;

esac