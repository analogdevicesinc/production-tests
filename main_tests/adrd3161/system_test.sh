#!/bin/bash

sudo ip link set can0 down
sudo ip link set can0 type can bitrate 500000
sudo ip link set can0 up

docker run -it --network=host --cap-add=NET_ADMIN adrd3161_tests bash -c "colcon build ; colcon test ; colcon test-result --all --verbose"

