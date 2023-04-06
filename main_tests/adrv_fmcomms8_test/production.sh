#!/bin/bash

"ADRV FMCOMMS8 RF test")
                        ssh_cmd "sudo /home/analog/adrv_fmcomms8_test/fmcomms8_test.sh"
						RESULT=$?
						get_fmcomms_serial
						python3 -m pytest --color yes $SCRIPT_DIR/work/pyadi-iio/test/test_adrv9009_zu11eg_fmcomms8.py -v
                        if [ $? -ne 0 ] || [ $RESULT -ne 0 ]; then
                                handle_error_state "$BOARD_SERIAL"
                        fi
                        