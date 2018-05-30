#!/bin/bash

source config.sh

self_test || {
	echo_red "Self test failed"
	exit 1
}
exit 0
