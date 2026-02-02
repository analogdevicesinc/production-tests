#!/bin/bash

sudo ip link set can0 down
sudo ip link set can0 type can bitrate 500000
sudo ip link set can0 up

sudo killall -q slcand

sudo gpioset 0 21=0
sleep 0.1
sudo gpioset 0 21=1
sleep 0.5

sudo timeout 1 slcand -o -c -f -t hw -s 6 -S 2000000 /dev/ttyAMA0 slcan0

sudo ip link set slcan0 down
sudo ip link set slcan0 type can bitrate 500000
sudo ip link set slcan0 up
