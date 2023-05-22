ANSWER=1

SCRIPT_DIR="$(readlink -f $(dirname $0))"

SERIAL_NUM=$1

echo
python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_fmcomms5_prod.py --uri="ip:analogdut.local" --adi-hw-map --hw=fmcomms5 --snumber="$SERIAL_NUM"
ANSWER=$?
exit $ANSWER
