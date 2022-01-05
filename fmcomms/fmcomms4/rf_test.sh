ANSWER=1

SCRIPT_DIR="$(readlink -f $(dirname $0))"

echo
python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_fmcomms4_prod.py --uri="ip:analog.local" --adi-hw-map --hw=fmcomms4
ANSWER=$?
exit $ANSWER
