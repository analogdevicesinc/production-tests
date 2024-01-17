#!/bin/bash
SCRIPT_DIR="$(readlink -f $(dirname $0))"

# Requirements for this wifi chip flashing: 
# pip install esptool==4.1
# wget https://github.com/amiclaus/linux_noos_guides/releases/download/release/ESP32-WROOM-32-AT-NINA-W102.zip
# unzip ESP32-WROOM-32-AT-NINA-W102.zip -d  "$(basename -s .zip ESP32-WROOM-32-AT-NINA-W102.zip)"
# cd ESP32-WROOM-32-AT-NINA-W102

echo "Enter download mode"
read -p "Connect P47 and R114 to GND and press ENTER when done"
cd $SCRIPT_DIR/ESP-WROOM-32-AT-NINA-W102 &&
esptool.py --chip auto --port /dev/ttyACM0 --baud 115200 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 40m --flash_size 4MB 0x8000 partition_table/partition-table.bin 0x10000 ota_data_initial.bin 0xf000 phy_multiple_init_data.bin 0x1000 bootloader/bootloader.bin 0x100000 esp-at.bin 0x20000 at_customize.bin 0x24000 customized_partitions/server_cert.bin 0x26000 customized_partitions/server_key.bin 0x28000 customized_partitions/server_ca.bin 0x2a000 customized_partitions/client_cert.bin 0x2c000 customized_partitions/client_key.bin 0x2e000 customized_partitions/client_ca.bin 0x37000 customized_partitions/mqtt_cert.bin 0x39000 customized_partitions/mqtt_key.bin 0x3B000 customized_partitions/mqtt_ca.bin 0x30000 customized_partitions/factory_param.bin