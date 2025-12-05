#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

touch /tmp/erase.act
daplink_upload /tmp/erase.act
