#!/bin/bash


populate_label_fields()
{
    SERIAL=$1
    MODEL="AD-SYNCHRONA14-EBZ"
    MAC1=$(ifconfig | grep ether | awk 'NR==1 {print $2}')
    MAC2=$(ifconfig | grep ether | awk 'NR==2 {print $2}')

    rm -rf /tmp/csvfile.csv #remove previous data

    echo $MODEL,$SERIAL,$MAC1,$MAC2> /tmp/csvfile.csv
}


print_label()
{
    rm -rf /tmp/back.pdf

    glabels-3-batch -o /tmp/back.pdf -i /tmp/csvfile.csv ./print/synchrona_back.glabels
    cancel -a -x
    lpr -PLabelWriter-450-Turbo /tmp/back.pdf
}

