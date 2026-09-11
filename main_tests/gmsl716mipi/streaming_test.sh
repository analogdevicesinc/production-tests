#!/bin/bash
SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh


echo_blue "[4] Test video data stream from sensor connected to GMSL port A/B"
echo_blue "-------------------------------------"

#/home/analog/Workspace/cam_setup.sh
#/home/analog/Workspace/video_cfg.sh
$SCRIPT_DIR/cam_setup.sh
$SCRIPT_DIR/video_cfg.sh
if [ $? -eq 0 ]; then
    echo "video_cfg.sh executed successfully."
else
    echo "video_cfg.sh failed to execute."
    exit 1
fi

# Check video0 and video1 devices
timeout 5 v4l2-ctl --device /dev/video0 --stream-mmap --stream-to=frame1.raw --stream-count=1 &
timeout 5 v4l2-ctl --device /dev/video1 --stream-mmap --stream-to=frame2.raw --stream-count=1
wait
# Check if the frames were captured successfully

for frame in frame1.raw frame2.raw; do
    if [ $(stat -c%s "$frame") -ne 307200 ]; then
        echo "Error: $frame is not the expected size."
        echo_red "FAILED"
        echo "Expected size: 307200 bytes, Actual size: $(stat -c%s "$frame") bytes"
        echo "Please check the video stream from the sensor."
        exit 1
    else
        echo "Video stream test $frame"
        echo_green "PASSED"
    fi
done

rm -f frame1.raw frame2.raw