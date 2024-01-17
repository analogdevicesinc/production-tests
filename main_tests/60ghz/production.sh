#!/bin/bash


SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh


MODE="$1"
case $MODE in
     "Provisioning")
        echo_blue "Programming production firmware ..."
        sudo -E $SCRIPT_DIR/firmware_prod.sh &&
        echo_blue "Checking updated version of firmware..."
        sudo $SCRIPT_DIR/check_fw.sh &&
        $SCRIPT_DIR/60ghz-conn_test.sh; 
        TEST_RESULT=$?
        if [ $TEST_RESULT -ne 0 ]; then
            handle_error_state "BOARD_SERIAL"
            exit 1;
        fi
        ;;

    "ADMV96x5 Test")
        echo_blue "Programming final firmware"
        $SCRIPT_DIR/firmware_p.sh &&
        $SCRIPT_DIR/led_test.sh &&
        sudo $SCRIPT_DIR/check_fw.sh &&
        $SCRIPT_DIR/60ghz_attr_test.sh
        TEST_RESULT=$?
        if [ $TEST_RESULT -ne 0 ]; then
            handle_error_state "$BOARD_SERIAL"
            exit 1;
        fi
        ;;
        
        "Networking Test")
        echo_blue "Programming final firmware"
        $SCRIPT_DIR/firmware_p.sh &&
        echo_blue "Checking updated version of firmware..."
        sudo -S $SCRIPT_DIR/check_fw.sh &&
        sudo $SCRIPT_DIR/nets.sh up
        threshold=200
        last_line=$(sudo ip netns exec net1 iperf -c 192.168.1.1 -i1 -t10 | tail -n 1)
        speed=$(echo "$last_line" | awk '{print $(NF-1)}')
        
        echo $speed
        if (( $(echo "$speed >= $threshold" | bc -l) )); then
            echo "Above 200 Mbits/sec"
            RESULT=0;
        else
            echo "Below 200 Mbits/sec"
            RESULT=1;
            
        fi
        if [ $RESULT -ne 0 ]; then
			handle_error_state "$BOARD_SERIAL"
			exit 1;
		fi
			
        sudo $SCRIPT_DIR/nets.sh down

		TEST_RESULT=$?
		if [ $TEST_RESULT -ne 0 ]; then
			handle_error_state "$BOARD_SERIAL"
			exit 1;
		fi
        ;;
        
    *) echo "Invalid option $MODE" ;;

esac
