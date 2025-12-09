#!/usr/bin/env bash


SCRIPT_DIR=$(dirname $(readlink -f $0))

TOOLCHAIN=$SCRIPT_DIR/../work/arm-zephyr-eabi/bin/arm-zephyr-eabi-


# Flash .elf to target
openocd \
        -f interface/cmsis-dap.cfg \
        -f target/max32662.cfg \
        -c 'init' \
        -c 'targets' \
        -c 'reset init' \
        -c "flash write_image erase \"$SCRIPT_DIR/max17320_ini/zephyr.hex\"" \
        -c 'reset run' \
        -c 'shutdown'
