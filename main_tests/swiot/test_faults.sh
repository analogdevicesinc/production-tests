ANSWER=1

SCRIPT_DIR="$(readlink -f $(dirname $0))"

echo
python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/examples/swiot/test_switch/test_faults.py --uri="ip:169.254.97.40" --adi-hw-map --hw=swiot
ANSWER=$?
exit $ANSWER
