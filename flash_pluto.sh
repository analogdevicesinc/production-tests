#!/bin/bash

#----------------------------------#
# Main section                     #
#----------------------------------#

# Prefer dir from CLI arg ; we could be getting this as an env var
[ -z "$1" ] || RELEASE_DIR="$1"

# If empty use default/current script path
[ -n "$RELEASE_DIR" ] || \
	RELEASE_DIR="$(pwd)/release/pluto"

# make sure the path is absolute
RELEASE_DIR="$(readlink -f $RELEASE_DIR)"

[ -d "$RELEASE_DIR" ] || {
	echo_red "No valid release dir provided"
	exit 1
}

./common_flash.sh "$RELEASE_DIR" "pluto.dfu"
