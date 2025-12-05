#!/bin/bash

# Uploads testing firmware.
# SHOULD be later overwritten by final production firmware (./firmware_final.sh) after tests pass.

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

RELEASE_FW=https://swdownloads.analog.com/cse/prod_test_rel/pqm_fw/pqm_prod_test_f9f2c18.zip
FW_DOWNLOAD_PATH=/home/analog/production-tests/main_tests/pqm

wget -T 5 $RELEASE_FW -O $FW_DOWNLOAD_PATH/pqm_prod_test_f9f2c18.zip
unzip -o $FW_DOWNLOAD_PATH/pqm_prod_test_f9f2c18.zip -d $FW_DOWNLOAD_PATH # Will extract pqm_prod_test_f9f2c18.hex
ret=$?

if [ $ret == 0 ];then
    echo "wget success, using downloaded firmware"
    daplink_upload $FW_DOWNLOAD_PATH/pqm_prod_test_f9f2c18.hex
else
    echo "wget error, using fallback local firmware"
    daplink_upload /home/analog/production-tests/main_tests/pqm/pqm_prod_test.hex
fi