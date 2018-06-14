#!/bin/bash

source config.sh

# Generic read/write wrapper for the EEPROM on the board
# Must be called:
#   ./eeprom_rw.sh read <addr> <num-bytes-to-read>
#   ./eeprom_rw.sh write <addr> <string-to-write>

eeprom_rw "$1" "$2" "$3"
