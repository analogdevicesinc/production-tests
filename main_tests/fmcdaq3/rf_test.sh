SCRIPT_DIR="$(readlink -f $(dirname $0))"

echo
python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_daq3_prod.py --uri="ip:analog.local" --adi-hw-map --hw=daq3 --snumber="$BOARD_SERIAL"
ANSWER=$?
exit $ANSWER

