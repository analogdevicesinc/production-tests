SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_util.sh
FAIL_COUNT=0

TEST_NAME="TEST_MISC"

TEST_ID="01"
SHORT_DESC="Test LEDs"
CMD="YES_no 'Are LED STAT1 yellow and LED STAT2 red? '"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Test synchrona fan"
CMD="YES_no 'Is the fan working? '"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Test poweroff. Synchrona will be turned off now."
CMD="sshpass -p analog ssh -q -t -oConnectTimeout=10 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oCheckHostIP=no analog@192.168.2.1 \"sudo poweroff\" ;"
CMD+="YES_no 'Device should be turned off. Check if fan is off, STAT2 is off and STAT1 has turned red'"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

failed_no
answer=$?
exit $answer
