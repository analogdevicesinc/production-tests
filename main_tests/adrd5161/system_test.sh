#!/bin/bash

sudo ip link set can0 down
sudo ip link set can0 type can bitrate 500000
sudo ip link set can0 up

python3 ./adrd5161/test_adrd5161.py
