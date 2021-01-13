#!/bin/bash

# sometimes it's in /media/root, sometimes /media/pi, so find it
dev=$(ls -l /dev/disk/by-id/ 2>/dev/null | \
	grep "usb-Linux_File-Stor_Gadget.*-0:0-part1" | \
	awk -F/ '{print $NF}')

if [ "x${dev}" = "x" ] ; then
	echo could not find usb-Linux_File-Stor_Gadget
	echo "/dev/disk/by-id contents:"
	ls /dev/disk/by-id
	exit 1
fi

disk=$(grep ${dev} /proc/mounts | awk  '{print $2}')

if [ ! -f ${disk}/info.html ] ; then
	echo could not find ${disk}
	exit 1
fi

SERIAL=$(grep -A 1 "<td>Serial</td>" ${disk}/info.html | \
	tail -1 | \
	sed -e 's/^.*<td>//' -e 's/<\/td>//')
SERIAL1=$(echo $SERIAL | head -c 13)
SERIAL2=$(echo $SERIAL | sed -e s/^${SERIAL1}//)

TMAC=$(grep -A 1 "<td>MAC Address (M2k)</td>" ${disk}/info.html | \
tail -1 | \
sed -e 's/^.*<td>//' -e 's/<\/td>//' | \
tr [a-z] [A-Z})
HMAC=$(grep -A 1 "<td>MAC Address (HOST)</td>" ${disk}/info.html | \
tail -1 | \
sed -e 's/^.*<td>//' -e 's/<\/td>//' | \
tr [a-z] [A-Z})
MODEL=$(grep -A 1 "<th>Model</th>" ${disk}/info.html | \
tail -1 | \
sed -e 's/^.*<th>//' -e 's/<\/th>//' | \
sed -e 's/Analog Devices //')
REV=$(echo $MODEL | awk '{print $2}')
MODEL=$(echo $MODEL | sed -e s/$REV//)
if [ "x$(echo $MODEL | grep -i m2k)" != "x" ] ; then
	MODEL="ADALM2000"
fi
BAR=$(echo $(date +%Y%b%d-%H:%M:%S-%Z) $MODEL $REV $SERIAL)

if [ "x$TMAC" = "x" ] ; then echo missing Target MAC; exit 1; fi
if [ "x$HMAC" = "x" ] ; then echo missing Host MAC; exit 1; fi
if [ "x$SERIAL" = "x" ] ; then echo missing Serial Number; exit 1; fi
if [ "x$MODEL" = "x" ] ; then echo missing Model number; exit 1; fi
if [ "x$REV" = "x" ] ; then echo missing Revision; exit 1; fi

echo SET,MODEL,REV,SERIAL,SERIAL1,SERIAL2,TMAC,HMAC,BAR > /tmp/csvfile.csv
# change the "A" for the different test platforms, so everything is unique
# make sure that this is the last "echo [A-Z]" in this file.
echo A,$MODEL,$REV,$SERIAL,$SERIAL1,$SERIAL2,$TMAC,$HMAC,$BAR >> /tmp/csvfile.csv
echo -n $MODEL,$REV,$SERIAL,$TMAC,$HMAC, >> ./results.A

echo $MODEL
echo $REV
echo $SERIAL
echo $TMAC
echo $HMAC

rm -rf /tmp/back.pdf

glabels-3-batch -o /tmp/back.pdf -i /tmp/csvfile.csv ./m2k_back.glabels
cancel -a -x
lpr -PDYMO-LabelWriter-450 /tmp/back.pdf
