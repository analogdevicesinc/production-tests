#!/bin/bash

echo_red()   { printf "\033[1;31m$*\033[m\n"; }

get_latest_release() {
	curl --silent "https://api.github.com/repos/$1/releases/latest" |
	grep '"tag_name":' |
	sed -E 's/.*"([^"]+)".*/\1/'
}

#----------------------------------#
# Main section                     #
#----------------------------------#

VERSION_TO_UPDATE="$1"

[ -n "$VERSION_TO_UPDATE" ] || {
	VERSION_TO_UPDATE=$(get_latest_release analogdevicesinc/plutosdr-fw)
	echo_red "No version provided for pluto release getting latest $VERSION_TO_UPDATE"
}

RELEASE_DIR="$(pwd)/release/pluto"

[ -d "$RELEASE_DIR" ] || {
	if ! mkdir -p "$RELEASE_DIR" ; then
		echo_red "Could not create $RELEASE_DIR"
		exit 1
	fi
}

FW_URL="https://github.com/analogdevicesinc/plutosdr-fw/releases/download/${VERSION_TO_UPDATE}/plutosdr-fw-${VERSION_TO_UPDATE}.zip"
FW_BOOTSTRAP_URL="https://github.com/analogdevicesinc/plutosdr-fw/releases/download/${VERSION_TO_UPDATE}/plutosdr-jtag-bootstrap-${VERSION_TO_UPDATE}.zip"

./common_update_release.sh "$RELEASE_DIR" "pluto.dfu" "$FW_URL" "$FW_BOOTSTRAP_URL"
