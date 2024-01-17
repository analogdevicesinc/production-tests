#!/bin/bash

$SCRIPT_DIR/adrv1_crr_test/test_usb_periph.sh
FAILED_USB=$?
if [ $FAILED_USB -ne 255 ]; then
    $SCRIPT_DIR/adrv1_crr_test/test_uart.sh
    FAILED_UART=$?
    if [ $FAILED_UART -ne 255]; then
        ssh_cmd "sudo /home/analog/adrv1_crr_test/crr_test.sh"
    fi
fi
FAILED_TESTS=$?
if [ $FAILED_TESTS -ne 0 ] || [ $FAILED_USB -ne 0 ] || [ $FAILED_UART -ne 0 ]; then
    handle_error_state "BOARD_SERIAL"
fi