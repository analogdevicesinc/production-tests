#!/bin/bash
SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

gst-launch-1.0 udpsrc caps="application/x-rtp, sampling=YCbCr-4:2:2, depth=(string)8, width=(string)1920, height=(string )1080" port="5008" ! rtpvrawdepay ! videoconvert ! fpsdisplaysink video-sink=xvimagesink text-overlay=true sync=false
gst-launch-1.0 udpsrc caps="application/x-rtp, sampling=YCbCr-4:2:2, depth=(string)8, width=(string)1920, height=(string )1080" port="5009" ! rtpvrawdepay ! videoconvert ! fpsdisplaysink video-sink=xvimagesink text-overlay=true sync=false
gst-launch-1.0 udpsrc caps="application/x-rtp, sampling=YCbCr-4:2:2, depth=(string)8, width=(string)1920, height=(string )1080" port="5010" ! rtpvrawdepay ! videoconvert ! fpsdisplaysink video-sink=xvimagesink text-overlay=true sync=false
gst-launch-1.0 udpsrc caps="application/x-rtp, sampling=YCbCr-4:2:2, depth=(string)8, width=(string)1920, height=(string )1080" port="5011" ! rtpvrawdepay ! videoconvert ! fpsdisplaysink video-sink=xvimagesink text-overlay=true sync=false && exit

check_image_status() {
    echo_blue "[1] Testing the cameras"
    read -n 1 -p "Did all 4 frames look OK? (y/n): " answer
    echo ""

    if [[ "$answer" =~ [yY] ]]; then
        echo_green "PASSED"
    else
        echo_red "FAILED"
        RESULT=1;
        exit 1;
    fi

    sleep 2
}

check_image_status