#!/bin/bash

# Uploads final production firmware, ready for use by the end user.
# Assumes the board was tested beforehand using the test firmware (./firmware_test.sh)

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

RELEASE_FW=https://swdownloads.analog.com/cse/prod_test_rel/pqm_fw/pqm_final.zip
FW_DOWNLOAD_PATH=/home/analog/production-tests/main_tests/pqm

wget -T 5 $RELEASE_FW -O $FW_DOWNLOAD_PATH/pqm_final.zip
unzip -o $FW_DOWNLOAD_PATH/pqm_final.zip -d $FW_DOWNLOAD_PATH # Will extract pqm_final.hex
ret=$?

if [ $ret == 0 ];then
    echo "wget success, using downloaded firmware"
    daplink_upload $FW_DOWNLOAD_PATH/pqm_final.hex
else
    echo "wget error, using fallback local firmware"
    daplink_upload /home/analog/production-tests/main_tests/pqm/pqm_final.hex
fi