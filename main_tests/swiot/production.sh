#!/bin//bash 

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh

sudo ip route add 169.254.0.0/16 dev eth1
export PYTHONPATH=$PYTHONPATH:/home/analog/production-tests/main_tests/work/pyadi-iio

MODE="$1"

case $MODE in
            "Memory/MAXQ1065 tests")
            echo_blue "Programming production test firmware..."

	    $SCRIPT_DIR/firmware_prod.sh
	    TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi 
	    
	    #$SCRIPT_DIR/check_fw.sh "169.254.97.40"
	    #TEST_RESULT=$?
            #if [ $TEST_RESULT -ne 0 ]; then
            #    handle_error_state "$BOARD_SERIAL"
            #    exit 1;
            #fi             
	    tty=/dev/ttyACM0
	    stty -F $tty 115200
	    exec 4<$tty 5>$tty 
	    read -p "Press the reset button on the board then press ENTER" 
	    timeout 10s $SCRIPT_DIR/memory_test.sh
            TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi

	    $SCRIPT_DIR/led_test.sh
	    TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi 

	    $SCRIPT_DIR/ping.sh
	    TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi 
            ;;

	    "AD74413R/MAX14906 tests")
            $SCRIPT_DIR/test_faults.sh &&
            $SCRIPT_DIR/faults_led.sh &&
            TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi 
	    echo_blue "Please connect the terminal block right now. Press ENTER when done"
            read -r
            $SCRIPT_DIR/loopback_test.sh
            TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi 

            ;;

            "Program final firmware")
            $SCRIPT_DIR/firmware_p.sh
	    TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi 
	    
            $SCRIPT_DIR/check_fw.sh "169.254.97.40"
	    TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi

	    echo_blue "Please power the board using the T1L cable. Press ENTER when done"
            read -r
            $SCRIPT_DIR/t1l_power_led_test.sh
            TEST_RESULT=$?
            if [ $TEST_RESULT -ne 0 ]; then
                handle_error_state "$BOARD_SERIAL"
                exit 1;
            fi 
            ;;

            *) echo "Invalid option $MODE" ;;

esac
