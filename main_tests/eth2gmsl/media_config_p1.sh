#!/bin/bash
SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/../lib/utils.sh
source $SCRIPT_DIR/test_util.sh

GLOBAL_FAIL=0

TEST_NAME="MEDIA_CONFIG"
echo_blue "Connect the cameras on port 1. Press ENTER when done."
wait_enter

TEST_ID="01"
SHORT_DESC="Configuring set num lines"
CMD='ssh_cmd "/home/analog/Workspace/config_streaming_v2/set_num_lines_ov5640"'
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Set num px p line"
CMD='ssh_cmd "/home/analog/Workspace/config_streaming_v2/set_num_px_p_line_ov5640"'
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="03"
SHORT_DESC="Configuring GMSL port 1"
CMD='ssh_cmd "sudo /home/analog/Workspace/config_streaming_v2/media_cfg_des12_v2_ov5640_p1.sh"'
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="04"
SHORT_DESC="Start streaming"
CMD='ssh_cmd "sudo /home/analog/Workspace/config_streaming_v2/stream_ov5640"'
run_test $TEST_ID "$SHORT_DESC" "$CMD"

if [ -n "$GLOBAL_FAIL" ]; then
    exit 1
else
    exit 0
fi
