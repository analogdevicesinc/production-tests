#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

##### ensure flash partitions are not locked ####
flash_unlock -u /dev/mtd0
flash_unlock -u /dev/mtd1
flash_unlock -u /dev/mtd2
flash_unlock -u /dev/mtd3
flash_unlock -u /dev/mtd4
flash_unlock -u /dev/mtd5

######## erase the ones we use ##############
flash_erase /dev/mtd0 0 0
flash_erase /dev/mtd1 0 0
flash_erase /dev/mtd2 0 0

################## write flash with defaults using mkenv
echo
source $SCRIPT_DIR/rewrite_qspi.sh
