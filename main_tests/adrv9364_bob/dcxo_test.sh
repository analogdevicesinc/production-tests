
SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_ID="01"
SHORT_DESC="Testing crystal frequency"
CMD="python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_dcxo.py --uri=\"ip:192.168.0.112\" --adi-hw-map --hw=adrv9364 | tee calib.txt;"
CMD+="cat calib.txt | grep \"1 passed\""
run_test $TEST_ID "$SHORT_DESC" "$CMD"


