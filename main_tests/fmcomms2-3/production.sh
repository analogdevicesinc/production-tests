#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

MODE="$1"
case $MODE in
                "FMCOMMS2/3 Test")
                $SCRIPT_DIR/rf_test.sh;
                TEST_RESULT=$?
                if [ $TEST_RESULT -ne 0 ]; then
                        handle_error_state "$BOARD_SERIAL"
                        exit 1;
                fi
                ;;

                "DCXO Calibration Test")
                        $SCRIPT_DIR/dcxo_test.sh
					res=$?
                        if [ $res -eq 2 ]; then
                                handle_skipped_state "$BOARD_SERIAL"
			else
			        if [ $res -eq 1 ]; then
					handle_error_state "$BOARD_SERIAL"
					exit 1;
				else
					echo_red "Now please procced with the FMCOMMS2/3 tests (2)"
				fi
                        fi
                ;;
                *) echo "Invalid option $MODE" ;;
esac
