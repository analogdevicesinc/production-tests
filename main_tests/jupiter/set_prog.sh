#!/bin/bash

echo 478 > /sys/class/gpio/export;
echo out > /sys/class/gpio/gpio478/direction;
echo 0 > /sys/class/gpio/gpio478/value;
