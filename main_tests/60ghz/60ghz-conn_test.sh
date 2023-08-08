ANSWER=1

SCRIPT_DIR="$(readlink -f $(dirname $0))"

echo
python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_60ghz-conn_prod.py --uri="serial:/dev/ttyACM0,115200,8n2n"  --adi-hw-map --hw=admv9625
ANSWER=$?
exit $ANSWER