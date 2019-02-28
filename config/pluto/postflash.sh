#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source $SCRIPT_DIR/config.sh

#----------------------------------#
# Functions section                #
#----------------------------------#

wait_for_board() {
	local serial
	for iter in $(seq $BOARD_ONLINE_TIMEOUT) ; do
		serial=$(iio_attr -C $IIO_URI_MODE hw_serial 2> /dev/null | cut -d ' ' -f2)
		[ -z "$serial" ] || return 0
		sleep 1
	done
	return 1
}

powercycle_board() {
	force_terminate_programs
	disable_all_usb_ports
	power_cycle_sleep
	enable_all_usb_ports
	power_cycle_sleep
}

powercycle_board_wait() {
	powercycle_board
	wait_for_board
}

xo_calibration() {
	local xo
	./cal_ad9361 $IIO_URI_MODE -s 1048576 -b 1048576 -e 2000000000 || return 1

	# Check that we can read the XO correction attr
	iio_attr -q $IIO_URI_MODE -d ad9361-phy xo_correction &> /dev/null
}

tx_margin() {
	# This is the cal freq, check the rssi
	echo_green "    Calibration frequency is " \
		$(iio_attr $IIO_URI_MODE -q -c ad9361-phy RX_LO frequency 3500000000)

	local rssi_rx=$(iio_attr $IIO_URI_MODE -q  -i -c ad9361-phy voltage0 rssi)
	echo_green "    rssi_rx is ${rssi_rx}"

	echo_green "    setting TX_LO frequency to " \
		$(iio_attr $IIO_URI_MODE -q -c ad9361-phy TX_LO frequency 3700000000)
	echo_green "    setting DDS amplitude to frequency to " \
		$(iio_attr $IIO_URI_MODE -q -c cf-ad9361-dds-core-lpc TX1_I_F1 scale 0.0) \
		$(iio_attr $IIO_URI_MODE -q -c cf-ad9361-dds-core-lpc TX1_Q_F1 scale 0.0)

	echo_green "    setting DDS amplitude to frequency to " \
		$(iio_attr $IIO_URI_MODE -q -c cf-ad9361-dds-core-lpc TX1_I_F2 scale 0.0) \
		$(iio_attr $IIO_URI_MODE -q -c cf-ad9361-dds-core-lpc TX1_Q_F2 scale 0.0)

	# find an LO, and then see what is there
	# RANDOM = random integer between 0 and 32767
	# this sould provide value between 1G and 3G
	local tx_lo=$(expr $RANDOM \* 61037 + $RANDOM + 1000000000)

	echo_green "    setting RX_LO frequency to " \
		$(iio_attr $IIO_URI_MODE -q -c ad9361-phy RX_LO frequency ${tx_lo})
	sleep 1

	local rssi_rx_random=$(iio_attr $IIO_URI_MODE -q  -i -c ad9361-phy voltage0 rssi)
	echo_green "    rssi at ${tx_lo} is $rssi_rx_random"
	echo_green "    setting TX_LO frequency to " \
		$(iio_attr $IIO_URI_MODE -q -c ad9361-phy TX_LO frequency ${tx_lo})

	echo_green "    setting DDS amplitude to frequency to " \
		$(iio_attr $IIO_URI_MODE -q -c cf-ad9361-dds-core-lpc TX1_I_F1 scale 0.9) \
		$(iio_attr $IIO_URI_MODE -q -c cf-ad9361-dds-core-lpc TX1_Q_F1 scale 0.9)
	sleep 1

	local rssi_tx=$(iio_attr $IIO_URI_MODE -q  -i -c ad9361-phy voltage0 rssi)
	echo_green "    rssi at ${tx_lo} is $rssi_tx"

        local tx_margin=$(echo $rssi_rx_random $rssi_tx | awk '{printf "%2.2f", $1 - $3}')

	if [ "$(expr ${tx_margin} '<' 10.0)" = "1" ] ; then
		echo_red "    tx_margin $tx_margin"
		return 1
	else
                echo_green "    tx_margin $tx_margin"
		return 0
	fi
}

#----------------------------------#
# Main section                     #
#----------------------------------#

post_flash() {
	force_terminate_programs

	echo_green "0. Enabling USB data port"
	enable_usb_data_port

	echo_green "1. Waiting for board to come online (timeout $BOARD_ONLINE_TIMEOUT seconds)"
	wait_for_board || {
		echo_red "Board did not come online"
		return 1
	}

	BOARD_SERIAL=$(get_hwserial 20)
	[ -n "$BOARD_SERIAL" ] || {
		echo_red "Could not get device serial number"
		return 1
	}
	export BOARD_SERIAL

	echo_green "2. XO Calibration"
	retry 4 xo_calibration || {
		echo_red "  XO Calibration failed"
		return 1
	}

	echo_green "3. Testing TX Margin"
	retry 4 tx_margin || {
		echo_red "  TX Margin test failed"
		return 1
	}

	echo_green "4. Testing Linux"
	retry 4 expect $SCRIPT_DIR/config/pluto/linux.exp || {
		echo
		echo_red "   Linux test failed"
		return 1
	}

	echo_green "5. Locking flash"
	retry_and_run_on_fail 4 powercycle_board_wait \
		expect $SCRIPT_DIR/lib/lockflash.exp "$TTYUSB" "Pluto>" "pluto login:" || {
		echo
		echo_red "   Locking flash failed"
		return 1
	}

	force_terminate_programs

	echo
	echo_green "PASSED ALL TESTS"
	return 0
}
