#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

MODE="$1"

case $MODE in
        "MAX17320 Ini Flash")
                # Prior user checks
                echo
                echo "Please verify that the programmer is connected to header P7, then press Enter"
                read

                echo_blue "Writing firmware"

                $SCRIPT_DIR/mcu_flash_max17320.sh

                ;;
        "Firmware Flash")
                # Prior user checks
                echo
                echo "Please verify that the programmer is connected to header P7, then press Enter"
                read

                echo_blue "Writing firmware"

                $SCRIPT_DIR/mcu_flash_with_serialno.sh $BOARD_SERIAL || {
                        handle_error_state "$BOARD_SERIAL"
                        exit 1;
                }

                ;;

        "System Test")
                echo_blue "Running system test"

                $SCRIPT_DIR/system_test.sh
                TEST_RESULT=$?
                if [ $TEST_RESULT -ne 0 ]; then
                        handle_error_state "$BOARD_SERIAL"
                        exit 1;
                fi

                read -p "PLEASE REMOVE USB C charger from board. Press ENTER when done."
                echo_blue "Running LED and current check"
                $SCRIPT_DIR/system_check.sh || {
                        echo_red "FAILED"
                        handle_error_state "$BOARD_SERIAL"
                        exit 1
                }
                ;;

        *)
                echo "Invalid option $MODE"
                exit 1
                ;;
esac