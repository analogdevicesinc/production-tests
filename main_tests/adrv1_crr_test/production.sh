#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

MODE="$1"
case $MODE in
            "System Test")
            echo_blue "Running system test"
            $SCRIPT_DIR/test_usb_periph.sh 
            FAILED_USB=$?
            if [ $FAILED_USB -ne 255 ]; then
                $SCRIPT_DIR/test_uart.sh
                FAILED_UART=$?
                if [ $FAILED_UART -ne 255 ]; then
                    ssh_cmd "sudo /home/analog/adrv1_crr_test/crr_test.sh"
                fi
            fi
            FAILED_TESTS=$?
            if [ $FAILED_TESTS -ne 0 ] || [ $FAILED_USB -ne 0 ] || [ $FAILED_UART -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
            fi
            ;;
            *) echo "Invalid option $MODE" 
               exit 1
            ;;
esac    




