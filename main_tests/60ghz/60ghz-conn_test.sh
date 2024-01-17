ANSWER=1

SCRIPT_DIR="$(readlink -f $(dirname $0))"

echo
python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_60ghz-conn_prod.py --uri="serial:/dev/ttyACM0,345600,8n1n"  --adi-hw-map --hw=admv9615
ANSWER=$?
exit $ANSWER
