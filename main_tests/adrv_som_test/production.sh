#!/bin/bash

ssh_cmd "sudo /home/analog/adrv_som_test/som_test.sh"
if [$? -ne 0]; then
    handle_error_state "$BOARD_SERIAL"
fi