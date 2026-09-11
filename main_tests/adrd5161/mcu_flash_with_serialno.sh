#!/usr/bin/env bash

# Usage: ./flash_with_serialno.sh 1234
#
# Patch elf image OD_PERSIST_COMM.x1018_identity.serialNumber field and upload via openocd DAP.

SCRIPT_DIR=$(dirname $(readlink -f $0))

TOOLCHAIN=$SCRIPT_DIR/../work/arm-zephyr-eabi/bin/arm-zephyr-eabi-

SERIALNUM=$1

if [[ -z "$SERIALNUM" ]]; then
        echo "ERROR: Serial num not provided!"
        exit 1
fi

if [[ ( "$SERIALNUM" -lt 0 ) || ( "$SERIALNUM" -gt 4294967295 ) ]]; then
        echo "WARNING: Serial num out of uint32 bounds, will be truncated"
fi

# Modify .elf with new serial number
${TOOLCHAIN}gdb --write $SCRIPT_DIR/adrd5161_fw/zephyr.elf -ex "set OD_PERSIST_COMM.x1018_identity.serialNumber = ${SERIALNUM}" -ex "q"

# Flash modified .elf to target
openocd \
        -f interface/cmsis-dap.cfg \
        -f target/max32662.cfg \
        -c 'init' \
        -c 'targets' \
        -c 'reset init' \
        -c "flash write_image erase \"$SCRIPT_DIR/adrd5161_fw/zephyr.elf\"" \
        -c 'reset run' \
        -c 'shutdown'
