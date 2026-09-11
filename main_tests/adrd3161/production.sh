#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

MODE="$1"

case $MODE in
	"TMC Bootstrapping")
		# Prior user checks
		echo
		echo "Please verify that the programmer is connected to header P7, then press Enter"
		read

		echo_blue "Bootstrapping TMC9660"

		$SCRIPT_DIR/tmc_bootstrap.sh || {
			handle_error_state "$BOARD_SERIAL"
			exit 1;
		}

		;;

	"Firmware Flash")
		# Prior user checks
		echo
		echo "Please verify that the programmer is connected to header P6, then press Enter"
		read

		echo_blue "Writing firmware"

		$SCRIPT_DIR/mcu_flash_with_serialno.sh $BOARD_SERIAL || {
			handle_error_state "$BOARD_SERIAL"
			exit 1;
		}

		;;

	"System Test")
		echo_blue "Running system test"
		echo_red "WARNING: THE MOTOR WILL MOVE"

		$SCRIPT_DIR/system_test.sh
		TEST_RESULT=$?
		if [ $TEST_RESULT -ne 0 ]; then
			handle_error_state "$BOARD_SERIAL"
			exit 1;
		fi
		;;

	*)
		echo "Invalid option $MODE"
		exit 1
		;;
esac
