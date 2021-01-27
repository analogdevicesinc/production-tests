#!/bin/bash

# Wrapper script for updating release files for M2k.
# The script will handle downloading the files from Github and
# making sure everything is properly setup for the flashing script.
#
# Can be called with:  ./update_m1k_release.sh [version]
# If version is unspecified the latest version swill be used

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/update_release.sh

#----------------------------------#
# Main section                     #
#----------------------------------#

VERSION_TO_UPDATE="$1"

[ -n "$VERSION_TO_UPDATE" ] || {
	type curl &> /dev/null || {
		echo_red "You need to install 'curl' on your system"
		exit 1
	}

	VERSION_TO_UPDATE=$(get_latest_release analogdevicesinc/m1k-fw)
	echo_red "No version provided for m1k release getting latest $VERSION_TO_UPDATE"
}

RELEASE_DIR="$SCRIPT_DIR/release/m1k"

[ -d "$RELEASE_DIR" ] || {
	if ! mkdir -p "$RELEASE_DIR" ; then
		echo_red "Could not create $RELEASE_DIR"
		exit 1
	fi
}

FW_URL="https://github.com/analogdevicesinc/m1k-fw/releases/download/${VERSION_TO_UPDATE}/m1000.bin"
update_release "$RELEASE_DIR" "$VERSION_TO_UPDATE" "$FW_URL" "m1000.bin"
