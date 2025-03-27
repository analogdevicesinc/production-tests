#!/bin/bash

echo 348 > /sys/class/gpio/export;
echo out > /sys/class/gpio/gpio348/direction;

while true
do
echo 1 > /sys/class/gpio/gpio348/value;
sleep 1;
echo 0 > /sys/class/gpio/gpio348/value;
sleep 1;
done
