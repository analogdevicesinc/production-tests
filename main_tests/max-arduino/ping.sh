#!/bin/bash

echo "Ping test in 5s ..."

sleep 5

ping -c3 169.254.97.40
if [ $? -eq 0 ]; then
    RESULT=0;
    exit 0;
else
    RESULT=1;
    exit 1;
fi

