#!/bin/sh -e

gen_ff_seq() {
	local len="$1"
	local file="$2"
	for _ in $(seq 1 $len) ; do
		echo -n $'\xff' >> "$file"
	done
}

# crc32 can be obtained from gzip with some shell magic
checksum_raw() {
	cat "$1" | gzip -1 | tail -c 8 | head -c 4
}

save_env() {
	local mtd_data_file="$1"
	shift

	local tmp_data_file="$(mktemp)"
	local len

	len=0
	while [ -n "$1" ] ; do
		str="$1"
		echo -n "$str" >> "$tmp_data_file"
		head -c 1 /dev/zero >> "$tmp_data_file"

		len=$((len + ${#str} + 1))

		shift
	done
	head -c 1 /dev/zero >> "$tmp_data_file"
	len=$((len + 1))

	# fill rest with 0xff
	# extra-env size of 4096 bytes, but we need to compute
	# crc32 for the actual data
	# we need to subtract the first 4 bytes for crc32 (in the 4096 bytes)
	len=$((4096 - len - 4))

	gen_ff_seq "$len" "$tmp_data_file"

	local crc32=$(checksum_raw "$tmp_data_file")
	# clear the final file for mtd
	echo -n > "$mtd_data_file"

	# 0xf000 offset
	gen_ff_seq "61440" "$mtd_data_file"

	# write the CRC first
	checksum_raw "$tmp_data_file" >> "$mtd_data_file"

	cat "$tmp_data_file" >> "$mtd_data_file"

	# fill the rest with 0xff
	#gen_ff_seq "$len" "$mtd_data_file"

	rm "$tmp_data_file"
}

serial=$(cat /etc/serial)
pkey=$(cat /etc/serial | xargs echo PlutoSDR_by_Analog_Devices_Inc! | sha1sum | cut -f1 -d ' ')
xo_corr=$(iio_attr -d ad9361-phy xo_correction)

MTD_DATA_FILE="/tmp/mtd_storage0"

string_list="serial=$serial"
string_list="$string_list productkey=$pkey"
string_list="$string_list ad936x_ext_refclk=<$xo_corr>"

save_env "$MTD_DATA_FILE" $string_list

mtd_debug erase /dev/mtd0 0xF0000 0x10000
mtd_debug write /dev/mtd0 0xF0000 0x10000 "$MTD_DATA_FILE"

echo /dev/mtd0 0xff000 0x1000 0x1000 1 > /tmp/fw_env.conf

fw_printenv -c /tmp/fw_env.conf
