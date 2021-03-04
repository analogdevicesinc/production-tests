#!/bin/bash

sudo apt-get install cups glabels cups-bsd
sudo service cups restart
sudo apt-get install printer-driver-dymo
sudo apt-get install libcups2-dev libcupsimage2-dev
sudo usermod -a -G lpadmin analog

# go to localhost:631 and add printer
# save the ppd file to /usr/share/cups/model

python dymo_install.py
pip install pyudev