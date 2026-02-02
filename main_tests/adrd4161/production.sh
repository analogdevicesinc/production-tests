#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

echo "This test if for the ADRD4161 board"

MODE="$1"

case $MODE in
    "CAN Test")
        $SCRIPT_DIR/adrd4161_blink_test.sh
	    TEST_RESULT=$?
	    if [ $TEST_RESULT -ne 0 ]; then
		handle_error_state "$BOARD_SERIAL"
		exit 1
	    fi

	    sudo $SCRIPT_DIR/firmware.sh $SCRIPT_DIR/adrd4161_slcan.elf
        $SCRIPT_DIR/can_init.sh

 	    python3 $SCRIPT_DIR/test_can_rx_tx.py
	    TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1
            fi

	    python3 $SCRIPT_DIR/test_can_bus_load.py
	    TEST_RESULT=$?
	    if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1
        fi
        ;;

    "IMU Test")
        $SCRIPT_DIR/imu_test.sh
        TEST_RESULT=$?
        if [ $TEST_RESULT -ne 0 ]; then
            handle_error_state "$BOARD_SERIAL"
            exit 1
        fi
        ;;

    "GPIO Test")
        $SCRIPT_DIR/toggle_led.sh
        TEST_RESULT=$?
        if [ $TEST_RESULT -ne 0 ]; then
            handle_error_state "$BOARD_SERIAL"
            exit 1
        fi
        ;;

    *) echo "Invalid option $MODE" ;;
esac
