#!/bin/bash
SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh
RESULT=0

# Connect to serial
#stty -F $tty 115200
#exec 4<$tty 5>$tty
#RX=4
#TX=5

coproc picocom (picocom -b 115200 "$tty")
RX=${picocom[0]}
TX=${picocom[1]}

# echo RX=$RX TX=$TX PID=${picocom_PID}

recvuntil(){
	local timeout=30
	while [[ $timeout -ge 0 ]]; do
		read -u $RX -t 1
		if [[ $? -ne 0 ]]; then
			timeout=$((timeout-1))
		fi
		# echo "got: >$REPLY<"
		if [[ "$REPLY" =~ $1 ]]; then
			return 0
		fi
	done
	echo_red "FAILED (Timeout)"
	RESULT=1
	return 1
}

recvuntil_test_result(){
	local timeout=30
	while [[ $timeout -ge 0 ]]; do
		read -u $RX -t 1
		if [[ $? -ne 0 ]]; then
			timeout=$((timeout-1))
		fi
		if [[ $REPLY =~ "$1" ]]; then
			# echo "got: >$REPLY<"
			if [[ "$REPLY" =~ Passed ]]; then
				echo_green 'PASSED'
				return 0
			elif [[ $REPLY =~ Failed ]]; then
				echo_red 'FAILED'
				RESULT=1
				return 1
			fi
		fi
	done
	echo_red 'FAILED (Timeout)'
	RESULT=1
	return 1
}

forward_yesno(){
	while
		read -p "$1" -n 1 REPLY
	do
		echo;
		if [[ "$REPLY" =~ [Yy] ]]; then
			echo -n y >&$TX
			break
		elif [[ "$REPLY" =~ [Nn] ]]; then
			echo -n n >&$TX
			break
		else
			continue # Not y,Y,n,N, repeat
		fi
	done
}

# Send break over serial -> DAPLink will reset the target board
echo_blue 'Reseting DUT'
python3 -c 'import termios; termios.tcsendbreak(3, 0)' 3>$tty

echo '[01] UART Test'
recvuntil_test_result 'UART test'

recvuntil 'Testing RAM'
echo '[02] RAM Test'
recvuntil_test_result 'RAM test'

recvuntil 'Testing LCD'
echo '[03] LCD test'
recvuntil 'Is display working?'
forward_yesno 'Is display working (y/n)? '
recvuntil_test_result "LCD test"

recvuntil 'Testing RTC'
echo '[04] RTC Test'
recvuntil_test_result 'RTC test'

recvuntil 'Testing SD card'
echo '[05] SD card Test'
recvuntil_test_result 'SD card test'

recvuntil 'Testing LEDs and buttons'
echo '[06] LED & Button Test'
test_led(){
	recvuntil "Is LED DS|tests Failed"
	if [[ $REPLY =~ 'LED & BUTTON tests Failed...' ]]; then
		echo_red FAILED
		RESULT=1
		return 1
	fi

	if [[ $1 == 4 ]]; then
		echo "Note: LED DS4 is also connected to the JTAG interface and may not work while the programmer is connected!"
	fi
	forward_yesno "Is LED DS$1 ON (y/n)? "
}

fake_test_led4(){
	recvuntil "Is LED DS|tests Failed"
	if [[ $REPLY =~ 'LED & BUTTON tests Failed...' ]]; then
		echo_red FAILED
		RESULT=1
		return 1
	fi

	echo -n y >&$TX
}

test_button(){
	recvuntil "Press button S|tests Failed"
	if [[ $REPLY =~ 'LED & BUTTON tests Failed...' ]]; then
		echo_red FAILED
		RESULT=1
		return 1
	fi

	echo "Press button S$1! (5 second timeout)"
}

test_led 1 &&
test_led 2 &&
test_led 3 &&
fake_test_led4 &&
test_button 1 &&
test_button 2 &&
test_button 3 &&
recvuntil_test_result 'LED & BUTTON tests'

recvuntil 'Testing FLASH'
echo '[07] FLASH Test'
recvuntil_test_result "FLASH test"

recvuntil 'Testing T1L'
echo '[08] T1L Test'
recvuntil_test_result 'T1L tests'

recvuntil 'Testing WIZ ETH'
echo '[09] WIZ ETH Test'
recvuntil_test_result 'WIZ ETH tests'

recvuntil 'Testing ADE9430'
echo '[10] ADE9430 Test'
recvuntil_test_result 'ADE9430 tests'

recvuntil 'Testing T1L SOCKET'
echo '[11] T1L SOCKET Test'
recvuntil 'IP address: '
ip=$(echo $REPLY | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
echo IP: $ip

sudo ip link set eth1 down
sudo ip link set eth1 up
sudo ip route add $ip dev eth1 && {
	echo_green 'Added route'
} || {
	echo_red 'Could not add route'
}

for attempt in {1..10}; do
	(ip link show eth1 | grep -q 'state UP') || {
		echo "Waiting for T1L link ($attempt/10)"
		sleep 1
		continue
	}

	ping -r -I eth1 -w 1 $ip >/dev/null 2>/dev/null || {
		echo "Waiting for ping ($attempt/10)"
		sleep 1
		continue
	}

	echo_green "PASSED"
	exit $RESULT
done

echo_red "FAILED"
RESULT=1
exit $RESULT
