#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh

case $MODE in
                "FMCOMMS4 Test")
						ssh_cmd "sudo fru-dump -i /sys/devices/soc0/fpga-axi@0/41600000.i2c/i2c-0/i2c-7/7-0050/eeprom -b | grep 'Tuning' | cut -d' ' -f4 | tr -d '[:cntrl:]'"
						CALIB_DONE=$?

						if [ $CALIB_DONE -ne 0 ]; then
							printf "\033[1;31mPlease run calibration first\033[m\n"
							handle_error_state "$BOARD_SERIAL"
						fi
                        $SCRIPT_DIR/rf_test.sh
                        if [ $? -ne 0 ]; then
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
															echo_red "Now please procced with the FMCOMMS4 tests (2)"
														fi
                        fi
                        ;;
				*) echo "Invalid option $MODE" ;;

esac	