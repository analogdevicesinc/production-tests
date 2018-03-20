#!/bin/bash

echo_red()   { printf "\033[1;31m$*\033[m\n"; }

#----------------------------------#
# Main section                     #
#----------------------------------#

VERSION_TO_UPDATE="$1"

[ -n "$VERSION_TO_UPDATE" ] || {
	echo_red "No version provided for m2k release"
	exit 1
}

RELEASE_DIR="$(pwd)/release/m2k"

[ -d "$RELEASE_DIR" ] || {
	if ! mkdir -p "$RELEASE_DIR" ; then
		echo_red "Could not create $RELEASE_DIR"
		exit 1
	fi
}

FW_URL="https://github.com/analogdevicesinc/m2k-fw/releases/download/v${VERSION_TO_UPDATE}/m2k-fw-v${VERSION_TO_UPDATE}.zip"
FW_BOOTSTRAP_URL="https://github.com/analogdevicesinc/m2k-fw/releases/download/v${VERSION_TO_UPDATE}/m2k-jtag-bootstrap-v${VERSION_TO_UPDATE}.zip"

./common_update_release.sh "$RELEASE_DIR" "m2k.dfu" "$FW_URL" "$FW_BOOTSTRAP_URL"
