#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh

ret=0
tty=/dev/ttyACM0
#stty -F $tty 115200
#exec 4<$tty 5>$tty
test_names=("[1] UART test" " [2] MAXQ1065 ping" " [3] RAM chip 1" " [4] RAM chip 2" " [5] Flash chip")

while [ "$first_word" != "Running" ]; do
    read -e output < $tty &> /dev/null
    first_word=$(echo "$output" | cut -f1 -d" ")
    test_name=$(echo "$output" | cut -f1 -d":")
  
    	if [[ $test_name == "Serial id" ]]; then
		echo $output
	fi

	if [[ " ${test_names[@]} " =~ " ${test_name} " ]]; then
    	test_result=$(echo "$output" | cut -f2 -d":")
    	echo -n "$test_name: "
		if [ $test_result == "PASSED" ];
		then
			echo_green "PASSED"
			ret=0
		else
			echo_red "FAILED"
			ret=1
		fi
	fi
done

exit $ret;
