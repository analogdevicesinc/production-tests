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
	type curl &> /dev/null || {
		echo_red "You need to install 'curl' on your system"
		exit 1
	}
	VERSION_TO_UPDATE=$(get_latest_release analogdevicesinc/m2k-fw)
	echo_red "No version provided for m2k release getting latest $VERSION_TO_UPDATE"
}

RELEASE_DIR="$(pwd)/release/m2k"

[ -d "$RELEASE_DIR" ] || {
	if ! mkdir -p "$RELEASE_DIR" ; then
		echo_red "Could not create $RELEASE_DIR"
		exit 1
	fi
}

FW_URL="https://github.com/analogdevicesinc/m2k-fw/releases/download/${VERSION_TO_UPDATE}/m2k-fw-${VERSION_TO_UPDATE}.zip"
FW_BOOTSTRAP_URL="https://github.com/analogdevicesinc/m2k-fw/releases/download/${VERSION_TO_UPDATE}/m2k-jtag-bootstrap-${VERSION_TO_UPDATE}.zip"

./common_update_release.sh "$RELEASE_DIR" "m2k.dfu" "$FW_URL" "$FW_BOOTSTRAP_URL"
