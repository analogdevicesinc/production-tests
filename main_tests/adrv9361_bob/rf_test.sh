ANSWER=1

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_RF"

TEST_ID="01"
SHORT_DESC="DCXO_TESTING - Make sure the frequency counter is connected and powered."
CMD="wait_enter ;"
CMD+="$SCRIPT_DIR/dcxo_test.sh ;"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="RF_TESTING - Make sure loopback cables are connected."
CMD="wait_enter ;"
CMD+="python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_adrv9361_prod.py --uri=\"ip:analog.local\" --adi-hw-map --hw=adrv9361 ;"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

