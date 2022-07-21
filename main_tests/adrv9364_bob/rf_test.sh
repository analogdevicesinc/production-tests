ANSWER=1

SCRIPT_DIR="$(readlink -f $(dirname $0))"

echo
python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_fmcomms4_prod.py --uri="ip:192.168.0.112" --adi-hw-map --hw=adrv9364
ANSWER=$?
exit $ANSWER
