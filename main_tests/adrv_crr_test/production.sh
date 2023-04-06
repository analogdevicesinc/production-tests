#!/bin/bash

"ADRV Carrier Test")
                        $SCRIPT_DIR/adrv_crr_test/test_usb_periph.sh &&
                        $SCRIPT_DIR/adrv_crr_test/test_uart.sh &&
                        ssh_cmd "sudo /home/analog/adrv_crr_test/crr_test.sh"
                        if [ $? -ne 0 ]; then
                                handle_error_state "$BOARD_SERIAL"
                        fi