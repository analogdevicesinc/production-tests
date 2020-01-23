#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_powersupply.sh
answer=$?
proceed_if_ok $answer

echo
