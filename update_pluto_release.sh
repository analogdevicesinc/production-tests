#!/bin/bash

echo_red()   { printf "\033[1;31m$*\033[m\n"; }

#----------------------------------#
# Main section                     #
#----------------------------------#

VERSION_TO_UPDATE="$1"

[ -n "$VERSION_TO_UPDATE" ] || {
	echo_red "No version provided for pluto release"
	exit 1
}

RELEASE_DIR="$(pwd)/release/pluto"

FW_URL="https://github.com/analogdevicesinc/plutosdr-fw/releases/download/v${VERSION_TO_UPDATE}/plutosdr-fw-v${VERSION_TO_UPDATE}.zip"
FW_BOOTSTRAP_URL="https://github.com/analogdevicesinc/plutosdr-fw/releases/download/v${VERSION_TO_UPDATE}/plutosdr-jtag-bootstrap-v${VERSION_TO_UPDATE}.zip"

./common_update_release.sh "$RELEASE_DIR" "pluto.dfu" "$FW_URL" "$FW_BOOTSTRAP_URL"
