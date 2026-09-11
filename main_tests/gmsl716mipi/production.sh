#!/bin//bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh

MODE="$1"

case $MODE in
            "Communication Test")
            $SCRIPT_DIR/test_voltage_supply.sh
            $SCRIPT_DIR/driver_comm.sh
            TEST_RESULT=$?
            echo $TEST_RESULT
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi
            ;;

            "Data streaming Test")
            $SCRIPT_DIR/streaming_test.sh
                TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi
            ;;

            *) echo "Invalid option $MODE" 
               exit 1
            ;;

esac