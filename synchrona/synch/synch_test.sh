
SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

source $SCRIPT_DIR/clk_disable.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/clk_source.sh
answer=$?
proceed_if_ok $answer

echo
source $SCRIPT_DIR/test_i2c_temp.sh
answer=$?
proceed_if_ok $answer

# echo
# source $SCRIPT_DIR/test_clk.sh
# answer=$?
# proceed_if_ok $answer

# echo
# source $SCRIPT_DIR/test_eth.sh
# answer=$?
# proceed_if_ok $answer

# echo
# source $SCRIPT_DIR/test_usb.sh
# answer=$?
# proceed_if_ok $answer
