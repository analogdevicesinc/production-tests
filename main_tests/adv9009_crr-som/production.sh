#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh

MODE="$1"
case $MODE in 
        "ADRV Carrier Test")
                $SCRIPT_DIR/test_usb_periph.sh &&
                $SCRIPT_DIR//test_uart.sh &&
                ssh_cmd "sudo /home/analog/adrv_crr_test/crr_test.sh"
                if [ $? -ne 0 ]; then
                        handle_error_state "$BOARD_SERIAL"
                        exit 1;
                fi
                ;;
        
        "ADRV Carrier Test-SOM")
                $SCRIPT_DIR/test_usb_periph.sh &&
                $SCRIPT_DIR/test_uart.sh &&
                ssh_cmd "sudo /home/analog/adrv_crr_test/crr_test.sh"
                if [ $? -ne 0 ]; then
                        handle_error_state "$BOARD_SERIAL"
                        exit 1;
                fi
                ;;
        
        "ADRV SOM Test")
                ssh_cmd "sudo /home/analog/adrv_som_test/som_test.sh"
                if [ $? -ne 0 ]; then
                        handle_error_state "$BOARD_SERIAL"
                        exit 1;
                fi
                ;;
        
        "ADRV FMCOMMS8 RF test")
		$SCRIPT_DIR/adrv_fmcomms8_test/fmcomms8_test.sh;
		TEST_RESULT=$?
                if [ $TEST_RESULT -ne 0 ]; then
                        handle_error_state "$BOARD_SERIAL"
                fi
		ssh_cmd "sudo fru-dump -i /usr/local/src/fru_tools/masterfiles/AD-FMCOMMS8-EBZ-FRU.bin -o /sys/devices/platform/axi/ff030000.i2c/i2c-1/i2c-8/8-0052/eeprom -s $BOARD_SERIAL -d now";
                ;;

        "ADRV SOM RF test")
		$SCRIPT_DIR/../adrv_som_test/test_rf.sh
                if [ $? -ne 0 ]; then
                        handle_error_state "$BOARD_SERIAL"
                        exit 1;
                fi     
                ;;

        *) echo "invalid option $MODE" ;;

esac


