#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source "$SCRIPT_DIR/../lib/utils.sh"

MODE="$1"
case $MODE in
	"FMCDAQ3 Test")
		"$SCRIPT_DIR/rf_test.sh";
		TEST_RESULT=$?
		if [ $TEST_RESULT -ne 0 ]; then
			handle_error_state "$BOARD_SERIAL"
			exit 1;
		fi
		;;

	*) echo "Invalid option $MODE" ;;
esac

