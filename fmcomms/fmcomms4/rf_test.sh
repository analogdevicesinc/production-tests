ANSWER=1

sudo fru-dump -i /sys/devices/soc0/fpga-axi@0/41600000.i2c/i2c-0/i2c-7/7-0050/eeprom -b | grep 'Tuning' | cut -d' ' -f4 | tr -d '[:cntrl:]'
CALIB_DONE=$?

if [ $CALIB_DONE -ne 0 ]; then
    printf "\033[1;31mPlease run calibration first\033[m\n"
    exit 1
fi

echo
python3 -m pytest --color yes -vs /home/analog/pyadi-iio/test/test_fmcomms4_prod.py --uri="ip:127.0.0.1" --adi-hw-map --hw=fmcomms4
ANSWER=$?
exit $ANSWER
