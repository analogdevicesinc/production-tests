#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source config.sh

#----------------------------------#
# Functions section                #
#----------------------------------#

echo_red()   { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }
echo_blue()  { printf "\033[1;34m$*\033[m\n"; }

check_system_requirements() {
	type wget &> /dev/null || {
                echo_red "You need the 'wget' utility on your system"
		exit 1
	}
	type unzip &> /dev/null || {
		echo_red "You need the 'unzip' utility on your system"
	}
}

download_and_unzip_to() {
	local url="$1"
	local dir="$2"

	local tmp_file="$(mktemp)"

	wget "$url" -O "$tmp_file" || {
		echo_red "Download has failed..."
		rm -f "$tmp_file"
		exit 1
	}

	unzip "$tmp_file" -d "$dir" || {
		echo_red "Unzip has failed..."
		rm -f "$tmp_file"
		echo 1
	}
	rm -f "$tmp_file"

	return 0
}

#----------------------------------#
# Main section                     #
#----------------------------------#

RELEASE_DIR="$1"

# make sure the path is absolute
RELEASE_DIR="$(readlink -f $RELEASE_DIR)"

[ -d "$RELEASE_DIR" ] || {
	echo_red "No valid release dir provided"
	exit 1
}

FIRMWARE_DFU_FILE="$2"

[ -n "$FIRMWARE_DFU_FILE" ] || {
	echo_red "No firmware DFU filename provided"
	exit 1
}

FW_URL="$3"

[ -n "$FW_URL" ] || {
	echo_red "No download URL provided for firmware package"
	exit 1
}

FW_BOOTSTRAP_URL="$4"

[ -n "$FW_BOOTSTRAP_URL" ] || {
	echo_red "No download URL provided for jtag bootstrap package"
	exit 1
}

echo_green "Note: using release dir '$RELEASE_DIR'"
echo_red "Warning: your current release files will be removed from '$RELEASE_DIR'"
echo_red "Press Ctrl + C to quit"
sleep 3

# Sanity check that we have all release files, before going forward
for file in $RELEASE_DIR/* ; do
	rm -f "$file"
done

for url in $FW_URL $FW_BOOTSTRAP_URL ; do
	echo_green "Downloading and unzipping from '$url' to '$RELEASE_DIR'"
	download_and_unzip_to "$url" "$RELEASE_DIR"
done

# Patch ps7_init.tcl
sed -i -e "s/variable PCW_SILICON_VER_1_0/set PCW_SILICON_VER_1_0 \"0x0\"/g" \
	-e "s/variable PCW_SILICON_VER_2_0/set PCW_SILICON_VER_2_0 \"0x1\"/g" \
	-e "s/variable PCW_SILICON_VER_3_0/set PCW_SILICON_VER_3_0 \"0x2\"/g" \
	-e "s/variable APU_FREQ/set APU_FREQ 666666666/g" $RELEASE_DIR/ps7_init.tcl

exit 0
