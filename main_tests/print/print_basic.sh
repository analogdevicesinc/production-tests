#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

populate_label_fields()
{
    SERIAL=$1
    DATE=$(date +"%Y-%m-%d" )
    MODEL="AD-SYNCHRONA14-EBZ"
    MAC1=$(ifconfig | grep ether | awk 'NR==1 {print $2}')
    MAC2=$(ifconfig | grep ether | awk 'NR==2 {print $2}')

    rm -rf /tmp/csvfile.csv #remove previous data

    echo $MODEL,$SERIAL,$MAC1,$MAC2,$DATE > /tmp/csvfile.csv
}


populate_label_fields_jupiter()
{
    SERIAL=$(ssh_cmd "sudo fru-dump -i /sys/bus/i2c/devices/0-0050/eeprom -b -u | grep Serial | awk 'NR==1 {print \$4}'");
    DATE=$(ssh_cmd "sudo fru-dump -i /sys/bus/i2c/devices/0-0050/eeprom -b -u | grep Date | awk 'NR==1 {print \$9 \$6 \$7}'");
    MODEL="AD-Jupiter-EBZ"
    MAC1=$(ssh_cmd "sudo fru-dump -i /sys/bus/i2c/devices/0-0050/eeprom -b -u | grep Internal | awk 'NR==1 {print \$4}'");

    lsusb | grep "Dymo"
    if [ $? -ne 0 ]; then
        echo "ERROR: LABEL PRINTER NOT CONNECTED. PLEASE CONNECT PRINTER USB TO RASPBERRY TO PRINT LABEL!!"
        return 255;
    fi

    #if [ $SERIAL = "00000" ]; then
    #    return 255;
    #fi

    #if [ ${MAC1:0:11} != "00:05:f7:80" ]; then
    #    return 255;
    #fi
    rm -rf /tmp/csvfile.csv #remove previous data

    echo "${MODEL//[$'\t\r\n']},${SERIAL//[$'\t\r\n']},${MAC1//[$'\t\r\n']},${DATE//[$'\t\r\n']}" > /tmp/csvfile.csv
    return $?
}


print_label()
{
    rm -rf /tmp/back.pdf

    glabels-3-batch -o /tmp/back.pdf -i /tmp/csvfile.csv /home/analog/production-tests/main_tests/print/jupiter_back1.glabels
    cancel -a -x
    PRINTER=$(lpstat -t | grep "printer dymo" | awk '{print $2}')
    lpr -P$PRINTER /tmp/back.pdf
}

print_label_test()
{
    rm -rf /tmp/back.pdf

    SERIAL="2024050600012";
    DATE="2024-05-06";
    MODEL="AD-Jupiter-EBZ"
    MAC1="00:05:f7:80:bd:a9";

    lsusb | grep "Dymo"
    if [ $? -ne 0 ]; then
        echo "ERROR: LABEL PRINTER NOT CONNECTED. PLEASE CONNECT PRINTER USB TO RASPBERRY TO PRINT LABEL!!"
        return 255;
    fi

    rm -rf /tmp/csvfile.csv #remove previous data

    echo "${MODEL//[$'\t\r\n']},${SERIAL//[$'\t\r\n']},"00:05:f7:80:55:53",${DATE//[$'\t\r\n']}" > /tmp/csvfile.csv

    glabels-3-batch -o /tmp/back.pdf -i /tmp/csvfile.csv /home/analog/production-tests/main_tests/print/jupiter_back1.glabels
    cancel -a -x
    PRINTER=$(lpstat -t | grep "printer dymo" | awk '{print $2}')
    lpr -P$PRINTER /tmp/back.pdf
}

