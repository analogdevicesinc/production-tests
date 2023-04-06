#!/bin/bash

"Synchrona Production Test")

ssh_cmd "sudo /home/analog/synch/synch_test.sh $BOARD_SERIAL"
						FAILED_TESTS=$?
						if [ $FAILED_TESTS -ne 255 ]; then
							$SCRIPT_DIR/synch/uart_test.sh 
							FAILED_UART=$?
							if [ $FAILED_UART -ne 255 ]; then
								$SCRIPT_DIR/synch/spi_test.sh
								FAILED_SPI=$?
								if [ $FAILED_SPI -ne 255 ]; then
									$SCRIPT_DIR/synch/misc_test.sh
									FAILED_MISC=$?
								fi
							fi
						fi
						if [ $FAILED_TESTS -ne 0 ] || [ $FAILED_UART -ne 0 ] || [ $FAILED_SPI -ne 0 ] || [ $FAILED_MISC -ne 0 ]; then
								handle_error_state "$BOARD_SERIAL"
						fi

						BIN_PATH="/lib/firmware/raspberrypi/bootloader/stable/pieeprom-2021-07-06.bin" #latest rpi stable image
						;;