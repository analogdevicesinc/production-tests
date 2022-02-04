#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/utils.sh

EEPROM_PATH="/sys/bus/i2c/devices/8-0052/eeprom"
MASTERFILE_PATH="/usr/local/src/fru_tools/masterfiles/AD-FMCXMWBR1-EBZ-FRU.bin"
SERIAL_NUMBER_PREFIX=$(date +"%m%Y")

GPIO_ADDRESS=86000000
SPI1_ADDRESS=84000000
SPI2_ADDRESS=84500000
I2C1_ADDRESS=83000000
I2C2_ADDRESS=83100000

GPIO_FIRST=`ls -l /sys/class/gpio/ | grep " gpiochip" | grep "$GPIO_ADDRESS" | grep -Eo '[0-9]+$'`

SPI1_DEVICE_NR=`ls -l /sys/bus/iio/devices/ | grep "$SPI1_ADDRESS" | grep -Eo '[0-9]+$'`
SPI2_DEVICE_NR=`ls -l /sys/bus/iio/devices/ | grep "$SPI2_ADDRESS" | grep -Eo '[0-9]+$'`
I2C1_DEVICE_NR=`ls -l /sys/bus/iio/devices/ | grep "$I2C1_ADDRESS" | grep -Eo '[0-9]+$'`
I2C2_DEVICE_NR=`ls -l /sys/bus/iio/devices/ | grep "$I2C2_ADDRESS" | grep -Eo '[0-9]+$'`


if [ $(id -u) -ne 0 ] ; then
	echo "Please run as root"
	exit 1
fi

#----------------------------------#
# Function section                 #
#----------------------------------#

console_ascii_passed() {
	echo_green "$(cat $SCRIPT_DIR/lib/passed.ascii)"
}

console_ascii_failed() {
	echo_red "$(cat $SCRIPT_DIR/lib/failed.ascii)"
}

get_board_scan() {
	IS_OKBOARD=1
	while [ $IS_OKBOARD -ne 0 ]; do
		echo "Please use the scanner to scan the QR/Barcode on your carrier"
		read BOARD_SERIAL
		IS_OKBOARD=$?
		BOARD_SERIAL=`echo $BOARD_SERIAL | tr -d ' ' | tr -d '-'`
		echo "QR SCAN: $BOARD_SERIAL"
	done
}

check_req() {
	if [ ! -e $EEPROM_PATH ]
	then
		echo "EEPROM file not found on SYSFS"
		exit 1
	fi

	if [ ! -e $FRU_TOOLS_PATH ]
	then
		echo "FRU TOOLS path not correct or masterfile not available"
		exit 1
	fi
}

write_fru() {
	check_req
	if which fru-dump > /dev/null
	then
		fru-dump -i $MASTERFILE_PATH -o $EEPROM_PATH -d now -s $BOARD_SERIAL
		return 0
	else
		echo "fru-dump command not found. Check if you have it installed."
		exit 1
	fi
}

get_fmcbridge_serial() {
	BOARD_SR_NR=`fru-dump -i /sys/bus/i2c/devices/8-0052/eeprom -b | grep 'Serial Number' | cut -d' ' -f3 | tr -d '[:cntrl:]'`
	echo "Read Serial from EEPROM: $BOARD_SR_NR"
}

gpio_initialization() {
	echo ""
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "~~~~~~~~~Initializing GPIOs~~~~~~~~~"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo ""
	for ((i=$GPIO_FIRST;i<=$GPIO_LAST;i++))
	do
		echo "$i" > /sys/class/gpio/export 2>&1
		echo out > /sys/class/gpio/gpio$i/direction
	done
	echo "GPIO initialization done."
}

gpio_test_spi1() {
	echo ""
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "~~~~~~~~~Start testing SPI1 GPIOS~~~~~~~~~"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo ""
	SPI1_GPIO_FIRST=$(($GPIO_FIRST + 7))
	GPIO_INPUT_SPI1=$(($GPIO_FIRST + 3))

	echo in > /sys/class/gpio/gpio$GPIO_INPUT_SPI1/direction

	GPIO0=$(($GPIO_FIRST))
	GPIO1=$(($GPIO_FIRST+1))
	GPIO2=$(($GPIO_FIRST+2))

	for ((i=1;i<8;i++))
	do
		echo ""

		A0=$((($i>>0) & 1))
		A1=$((($i>>1) & 1))
		A2=$((($i>>2) & 1))

		echo "Testing SPI1_CS${i}"
		echo "A2:${A2} A1:${A1} A0:${A0}"

		echo $A2 > /sys/class/gpio/gpio$GPIO0/value
		echo $A1 > /sys/class/gpio/gpio$GPIO1/value
		echo $A0 > /sys/class/gpio/gpio$GPIO2/value

		SPI1_CS_GPIO=$(($SPI1_GPIO_FIRST + $i))

		echo out > /sys/class/gpio/gpio$SPI1_CS_GPIO/direction

		echo "SPI1_CS${i} set high"
		echo 1 > /sys/class/gpio/gpio$SPI1_CS_GPIO/value

		echo "Reading GPIO INPUT:"
		GPIOIN_VAL=`cat /sys/class/gpio/gpio$GPIO_INPUT_SPI1/value`
		if (( $GPIOIN_VAL == 1 ))
		then
			echo_green "SPI1_CS${i} test PASSED with value $GPIOIN_VAL"
		else
			echo_red "SPI1_CS${i} test FAILED."
			STATUS=1
		fi

		echo "SPI1_CS${i} set low"
		echo 0 > /sys/class/gpio/gpio$SPI1_CS_GPIO/value

		echo "Reading GPIO INPUT:"
		GPIOIN_VAL=`cat /sys/class/gpio/gpio$GPIO_INPUT_SPI1/value`
		if (( $GPIOIN_VAL == 0 ))
		then
			echo_green "SPI1_CS${i} test PASSED with value $GPIOIN_VAL"
		else
			echo_red "SPI1_CS${i} test FAILED."
			STATUS=1
		fi
	done
}

gpio_test_spi2() {
		echo ""
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "~~~~~~~~~Start testing SPI2 GPIOS~~~~~~~~~"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo ""

	SPI2_GPIO_FIRST=$(($SPI1_GPIO_FIRST + 7))
	GPIO_INPUT_SPI2=$(($GPIO_INPUT_SPI1 + 1))

	echo in > /sys/class/gpio/gpio$GPIO_INPUT_SPI2/direction

	GPIO5=$(($GPIO_FIRST+5))
	GPIO6=$(($GPIO_FIRST+6))
	GPIO7=$(($GPIO_FIRST+7))

	for ((i=1;i<8;i++))
	do
		echo ""

		A0=$((($i>>0) & 1))
		A1=$((($i>>1) & 1))
		A2=$((($i>>2) & 1))

		echo "Testing SPI2_CS${i}"
		echo "A2:${A2} A1:${A1} A0:${A0}"

		echo $A2 > /sys/class/gpio/gpio$GPIO5/value
		echo $A1 > /sys/class/gpio/gpio$GPIO6/value
		echo $A0 > /sys/class/gpio/gpio$GPIO7/value

		SPI2_CS_GPIO=$(($SPI2_GPIO_FIRST + $i))

		echo out > /sys/class/gpio/gpio$SPI2_CS_GPIO/direction

		echo "SPI2_CS${i} set high"
		echo 1 > /sys/class/gpio/gpio$SPI2_CS_GPIO/value

		echo "Reading GPIO INPUT"
		GPIOIN_VAL=`cat /sys/class/gpio/gpio$GPIO_INPUT_SPI2/value`
		if (( $GPIOIN_VAL == 1 ))
		then
			echo_green "SPI2_CS${i} test PASSED with value $GPIOIN_VAL"
		else
			echo_red "SPI2_CS${i} test FAILED."
			STATUS=1
		fi

		echo "SPI2_CS${i} set low"
		echo 0 > /sys/class/gpio/gpio$SPI2_CS_GPIO/value

		echo "Reading GPIO INPUT:"
		GPIOIN_VAL=`cat /sys/class/gpio/gpio$GPIO_INPUT_SPI2/value`
		if (( $GPIOIN_VAL == 0 ))
		then
			echo_green "SPI2_CS${i} test PASSED with value $GPIOIN_VAL"
		else
			echo_red "SPI2_CS${i} test FAILED."
			STATUS=1
		fi
	done
}

dac_test_spi1(){
	echo ""
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "~~~~~~~~~Start testing DAC1~~~~~~~~~"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo ""

	echo "Writing raw value 2000 to DAC1"
	echo 2000 > /sys/bus/iio/devices/${SPI1_DEVICE}/out_voltage_raw

	echo "Reading raw value from DAC1:"
	DAC1_VAL=`cat /sys/bus/iio/devices/${SPI1_DEVICE}/out_voltage_raw`

	if (( ($DAC1_VAL < 3000) || ($DAC1_VAL > 3100) ))
	then
		echo_red "DAC1 test FAILED with value: $DAC1_VAL"
		STATUS=1
	else
		echo_green "DAC1 test PASSED with value: $DAC1_VAL"
	fi
}

dac_test_spi2(){
	echo ""
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "~~~~~~~~~Start testing DAC2~~~~~~~~~"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo ""

	echo "Writing raw value 2000 to DAC2"
	echo 2000 > /sys/bus/iio/devices/${SPI2_DEVICE}/out_voltage_raw

	echo "Reading raw value from DAC2:"
	DAC2_VAL=`cat /sys/bus/iio/devices/${SPI2_DEVICE}/out_voltage_raw`
	if (( ($DAC2_VAL < 3000) || ($DAC2_VAL > 3100) ))
	then
		echo_red "DAC1 test FAILED with value: $DAC2_VAL"
		STATUS=1
	else
		echo_green "DAC1 test PASSED with value: $DAC2_VAL"
	fi
}

adc_test_i2c1(){
	echo ""
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "~~~~~~~~~Start testing ADC1~~~~~~~~~"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo ""

	ADC1_RANGES=(700 1000 500 700 1500 2100 1500 2100 2400 3000 400 600 2000 2500)

	for ((i=0;i<=6;i++))
	do
		echo ""
		MIN_VAL=$i*2
		MAX_VAL=$i*2+1
		echo "Reading VIN${i}"
		ADC_VAL=`cat /sys/bus/iio/devices/${I2C1_DEVICE}/in_voltage${i}_raw`
		echo "VIN$1 RANGE: ${ADC1_RANGES[$MIN_VAL]} ${ADC1_RANGES[$MAX_VAL]}"
		if (( ($ADC_VAL > ${ADC1_RANGES[$MIN_VAL]}) && ($ADC_VAL < ${ADC1_RANGES[$MAX_VAL]}) ))
		then
			echo_green "ADC1 VIN$i test PASSED with value:$ADC_VAL"
		else
			echo_red "ADC1 VIN$i test FAILED with value:$ADC_VAL"
			STATUS=1
		fi
	done
}

adc_test_i2c2(){
	echo ""
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "~~~~~~~~~Start testing ADC2~~~~~~~~~"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo ""

	for ((i=0;i<=5;i++))
	do
		echo ""

		GPIO=$(($GPIO_FIRST+$i))
		if (( $i > 2 ))
		then
			GPIO=$(($GPIO + 2))
		fi

		GPIO_INDEX=$(($GPIO - $GPIO_FIRST))

		echo out > /sys/class/gpio/gpio$GPIO/direction

		echo "Set GPIO${GPIO_INDEX} high"
		echo 1 > /sys/class/gpio/gpio$GPIO/value

		echo "Reading VIN${i}"
		ADC_VAL=`cat /sys/bus/iio/devices/${I2C2_DEVICE}/in_voltage${i}_raw`
		if (( $ADC_VAL > 2000 ))
		then
			echo_green "ADC2 test PASSED with value:$ADC_VAL"
		else
			echo_red "ADC2 test FAILED with value:$ADC_VAL"
			STATUS=1
		fi

		echo "Set GPIO${GPIO_INDEX} low"
		echo 0 > /sys/class/gpio/gpio$GPIO/value

		echo "Reading VIN${i}"
		ADC_VAL=`cat /sys/bus/iio/devices/${I2C2_DEVICE}/in_voltage${i}_raw`
		if (( $ADC_VAL < 2000 ))
		then
			echo_green "ADC2 test PASSED with value:$ADC_VAL"
		else
			echo_red "ADC2 test FAILED with value:$ADC_VAL"
			STATUS=1
		fi
	done
}

prepare_logs() {
	LOGDIR=$SCRIPT_DIR/log
	mkdir -p $LOGDIR
	RUN_TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
	LOGFILE="${LOGDIR}/${BOARD_SERIAL}_${RUN_TIMESTAMP}.log"
}

test_fmcbridge() {
	STATUS=0

	echo ""
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "~~~~~~~Device Initialization~~~~~~~~"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo ""

	echo ""
	echo "~~~~~~~~~~~~GPIOs Test~~~~~~~~~~~~~~"
	echo ""
	if [ -z $GPIO_FIRST ]; then
		echo_red "No GPIO node found!"
	else
		echo_green "GPIO initial offset found: $GPIO_FIRST"
		GPIO_LAST=$(($GPIO_FIRST + 21))
		gpio_initialization
		gpio_test_spi1
		gpio_test_spi2
	fi

	echo ""
	echo "~~~~~~~~~SPI1 Device Test~~~~~~~~~~~"
	echo ""
	if [ -z $SPI1_DEVICE_NR ]; then
		echo_red "AD5761_SPI1 not found."
	else
		SPI1_DEVICE="iio:device${SPI1_DEVICE_NR}"
		echo_green "SPI device 1 found: ${SPI1_DEVICE}"
		dac_test_spi1
	fi

	echo ""
	echo "~~~~~~~~~SPI2 Device Test~~~~~~~~~~~"
	echo ""
	if [ -z $SPI2_DEVICE_NR ]; then
		echo_red "AD5761_SPI12 not found."
	else
		SPI2_DEVICE="iio:device${SPI2_DEVICE_NR}"
		echo_green "SPI device 2 found: ${SPI2_DEVICE}"
		dac_test_spi2
	fi

	echo ""
	echo "~~~~~~~~~I2C1 Device Test~~~~~~~~~~~"
	echo ""
	if [ -z $I2C1_DEVICE_NR ]; then
		echo_red "AD7291_I2C1 not found."
	else
		I2C1_DEVICE="iio:device${I2C1_DEVICE_NR}"
		echo_green "I2C device 1 found: ${I2C1_DEVICE}"
		adc_test_i2c1
	fi

	echo ""
	echo "~~~~~~~~~I2C2 Device Test~~~~~~~~~~~"
	echo ""
	if [ -z $I2C2_DEVICE_NR ]; then
		echo_red "AD7291_I2C2 not found."
	else
		I2C2_DEVICE="iio:device${I2C2_DEVICE_NR}"
		echo_green "I2C device 2 found: ${I2C2_DEVICE}"
		adc_test_i2c2
	fi

	if [ "$STATUS" -eq 0 ]
	then
		echo_green "ALL TESTS HAVE PASSED"
		console_ascii_passed
	else
		echo_red "TESTS HAVE FAILED"
		console_ascii_failed
	fi
}


#----------------------------------#
# Main section                     #
#----------------------------------#

/etc/init.d/htpdate restart > /dev/null 2>&1

while true; do

	echo_blue "Please enter your choice: "

	options=("Start FMCBRIDGE Test" "Poweroff Board")
	select opt in "${options[@]}"; do
		case $REPLY in
			1)
				echo_blue "Starting FMCBRIDGE Test"
				get_board_scan
				prepare_logs
				test_fmcbridge | tee "${LOGFILE}"
				write_fru
				get_fmcbridge_serial
				break ;;
			2)
				enforce_root
				poweroff
				break 2 ;;
			*) echo "invalid option $REPLY";;
		esac
	done
done
