#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh
source $SCRIPT_DIR/test_util.sh

MODE="$1"
case $MODE in
            
            "System Test")
            $SCRIPT_DIR/test_uart.sh;
	    echo_blue "Insert the GPIO loopback"
            wait_enter
            ssh_cmd "sudo ~/production-tests/main_tests/eth2gmsl/test_periph.sh"
            echo_blue "Connect wire between UART Rx and Tx. Press ENTER when ready"
            wait_enter
	    echo "Starting UART pins test"
            ssh_cmd "sudo ~/production-tests/main_tests/eth2gmsl/uart_pins.sh"
            TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi
            ;;
            "GMSL P2 Cameras Test")
            ssh_cmd "/home/analog/Workspace/config_streaming_v2/set_p2.sh"
            echo "[DEVICE-TREE] Loading..."
            ssh_cmd "sudo reboot"
            sleep 1;
            wait_for_board_online
            $SCRIPT_DIR/media_config_p2.sh;
            echo_blue "Visually inspect camera frames and close the window after."
            sleep 2;
            $SCRIPT_DIR/open_frame_p2.sh
            TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi
            ;;

            "GMSL P1 Cameras Test")
		    ssh_cmd "/home/analog/Workspace/config_streaming_v2/set_p1_p2.sh"
            echo "[DEVICE-TREE] Loading..."
            ssh_cmd "sudo reboot"
            sleep 1;
            wait_for_board_online
            $SCRIPT_DIR/media_config_p1.sh;
            echo_blue "Visually inspect camera frames and close the window after."
            sleep 2;
            $SCRIPT_DIR/open_frame_p1.sh
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
