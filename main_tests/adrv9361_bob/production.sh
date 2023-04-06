#!/bin/bash
"ADRV9361 Test")
						# ssh_cmd "sudo fru-dump -i /sys/devices/soc0/fpga-axi@0/41600000.i2c/i2c-0/i2c-7/7-0050/eeprom -b | grep 'Tuning' | cut -d' ' -f4 | tr -d '[:cntrl:]'"
						# CALIB_DONE=$?

						# if [ $CALIB_DONE -ne 0 ]; then
						# 	printf "\033[1;31mPlease run calibration first\033[m\n"
						# 	handle_error_state "$BOARD_SERIAL"
						# fi
                        $SCRIPT_DIR/adrv9361_bob/rf_test.sh
						FAILED_TESTS=$?
						if [ $FAILED_TESTS -ne 255 ]; then
							$SCRIPT_DIR/adrv9361_bob/test_uart.sh
							FAILED_UART=$?
							if [ $FAILED_UART -ne 255 ]; then
								ssh_cmd "sudo /home/analog/adrv9361_bob/breakout_test.sh"
								FAILED_MISC=$?
							fi
						fi
                        if [ $FAILED_TESTS -ne 0 ] || [ $FAILED_UART -ne 0 ] || [ $FAILED_MISC -ne 0 ]; then
								handle_error_state "$BOARD_SERIAL"
						fi