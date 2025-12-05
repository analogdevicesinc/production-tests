#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

source $SCRIPT_DIR/../work/.venv/bin/activate
trap "deactivate" EXIT

pushd $SCRIPT_DIR

PORT=/dev/ttyACM0

echo_blue "1. Checking connection to TMC9660"

ublcli --port $PORT inspect chip | grep TMC9660 && echo "OK" || {
	echo_red "Couldn't connect to TMC9660!"
	echo_red "Possible causes:"
	echo_red " * Debug probe is not attached to header P7"
	echo_red " * ADRD3161 board is not powered"
	echo_red " * Board is already bootstrapped (no problem!)"
	echo

	exit 1
}

echo_blue "2. Checking if config is already present"

chip_config=$(ublcli --port $PORT inspect config)

needs_bootstrap=0
echo "$chip_config" | grep -qE 'vext1_voltage\s+= 3.3' || needs_bootstrap=1
echo "$chip_config" | grep -qE 'vext2_voltage\s+= 5.0' || needs_bootstrap=1

if [ $needs_bootstrap == 0 ]; then
	echo_green "Already bootstrapped!"

	# Start parameter mode
	ublcli --port $PORT start

	exit 0 # Success
fi

echo "3. Bootstrap"

ublcli --port $PORT write config --burn-otp --boot ioconfig_adrd3161.toml && {
	echo_green "Bootstrapping done!"
	exit # Success
} || {
	echo_red "Failed to bootstrap!!!"
	exit 1
}
