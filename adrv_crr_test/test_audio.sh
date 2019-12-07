#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/test_util.sh

TEST_NAME="TEST_AUDIO"

audio_test()
{
	local fifo audio_tmp1
	local FREQ=1500 freq1 freq2 freq1diff
	local ret1=0

	# fix levels for output/input
	alsactl store -c 0 -f $SCRIPT_DIR/adau1761.state &>/dev/null
	if [[ $? -ne 0 ]]; then
		echo "Failed saving alsa device state"
	fi

	fifo=$(mktemp --suffix=.fifo)
	rm -f "${fifo}" && mkfifo "${fifo}"
	audio_tmp1=$(mktemp --suffix=tmp1.wav)

	# record from the lineout jack to mic in (lower right to lower left)
	amixer set -q Headphone 70 unmute;  amixer set -q Capture 70 cap; amixer -q set Digital 255; amixer -q set 'PGA Boost' 1;
	play -V0 -q -c 2 -r 48000 -b 16 -n synth 3 sine ${FREQ} > "${fifo}" &>/dev/null &
	cat "${fifo}" | rec -q -c 1 "${audio_tmp1}" trim 0 2 &>/dev/null

	# pull the frequencies from the recorded tones and compare them
	freq1=$($SCRIPT_DIR/wav_tone_freq "${audio_tmp1}")
	freq1diff=$(( FREQ - freq1 ))
	if [[ ${freq1diff#-} -gt 2 ]]; then
		ret1=1
	fi
	# clean up
	# rm -f "${fifo}" "${audio_tmp1}"
	# restore levels for output/input
	alsactl restore -c 0 -f $SCRIPT_DIR/adau1761.state &>/dev/null

	return $(( ret1 ))
}

TEST_ID="01"
SHORT_DESC="Audio loopback test - loopback jack should be connected. Headphones <-> Stereo Single-ended input"
CMD="wait_enter && audio_test"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

TEST_ID="02"
SHORT_DESC="Audio loopback test - loopback jack should be connected. Stereo Single-ended output <-> Differential input"
CMD="wait_enter && audio_test"
run_test $TEST_ID "$SHORT_DESC" "$CMD"

: #if reached this point, ensure exit code 0
