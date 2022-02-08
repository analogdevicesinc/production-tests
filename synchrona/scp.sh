#!/bin/bash

SRC="$1"
DST="$2"
PASS="$3"

[ -n "$SRC" ] || {
	echo "failed - no src"
	exit 1
}

[ -d "$SRC" ] && {
	echo "Directory copy"
	param="-r"
}

[ -n "$DST" ] || {
	echo "failed - no dst"
	exit 1
}

cmd=

[ -z "$PASS" ] || cmd="$cmd sshpass -p${PASS}"
cmd="$cmd scp $param -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oCheckHostIP=no"

$cmd $SRC $DST &> /tmp/scp_command || {
	echo "failed - scp command: $(cat /tmp/scp_command)"
	rm -f /tmp/scp_command
	exit 1
}
exit 0

