#!/bin/bash

# Wrapper script for updating release files for Pluto.
# The script will handle downloading the files from Github and
# making sure everything is properly setup for the ./flash_pluto.sk script.
#
# Can be called with:  ./update_pluto_release.sh [version]
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
	VERSION_TO_UPDATE=$(get_latest_release analogdevicesinc/plutosdr-fw)
	echo_red "No version provided for pluto release getting latest $VERSION_TO_UPDATE"
}

RELEASE_DIR="$SCRIPT_DIR/release/pluto"

[ -d "$RELEASE_DIR" ] || {
	if ! mkdir -p "$RELEASE_DIR" ; then
		echo_red "Could not create $RELEASE_DIR"
		exit 1
	fi
}

FW_URL="https://github.com/analogdevicesinc/plutosdr-fw/releases/download/${VERSION_TO_UPDATE}/plutosdr-fw-${VERSION_TO_UPDATE}.zip"
FW_BOOTSTRAP_URL="https://github.com/analogdevicesinc/plutosdr-fw/releases/download/${VERSION_TO_UPDATE}/plutosdr-jtag-bootstrap-${VERSION_TO_UPDATE}.zip"


update_release "$RELEASE_DIR" "$VERSION_TO_UPDATE" "$FW_URL" "$FW_BOOTSTRAP_URL"
