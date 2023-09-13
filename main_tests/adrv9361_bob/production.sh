#!/bin/bash

# ssh_cmd "sudo fru-dump -i /sys/devices/soc0/fpga-axi@0/41600000.i2c/i2c-0/i2c-7/7-0050/eeprom -b | grep 'Tuning' | cut -d' ' -f4 | tr -d '[:cntrl:]'"
# CALIB_DONE=$?

# if [ $CALIB_DONE -ne 0 ]; then
# 	printf "\033[1;31mPlease run calibration first\033[m\n"
# 	handle_error_state "$BOARD_SERIAL"
# fi

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh

$SCRIPT_DIR/rf_test.sh || {
	handle_error_state "$BOARD_SERIAL"
	exit 1
}

$SCRIPT_DIR/test_uart.sh || {
	handle_error_state "$BOARD_SERIAL"
	exit 1
}

ssh_cmd "sudo /home/analog/adrv9361_bob/breakout_test.sh" || {
	handle_error_state "$BOARD_SERIAL"
	exit 1
}
