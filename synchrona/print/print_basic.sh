#!/bin/bash


populate_label_fields()
{
    SERIAL=$1
    MODEL="AD-SYNCHRONA14-EBZ"
    ifconfig | grep ether | awk 'NR==1 {print $2}'
    MAC=$?

    rm -rf /tmp/csvfile.csv #remove previous data

    echo $MODEL,$SERIAL,$MAC> /tmp/csvfile.csv
}


print_label()
{
    rm -rf /tmp/back.pdf

    glabels-3 -o /tmp/back.pdf -i /tmp/csvfile.csv ./synchrona_back.glabels
    cancel -a -x
    lpr -PLabelWriter-450-Turbo /tmp/back.pdf
}

