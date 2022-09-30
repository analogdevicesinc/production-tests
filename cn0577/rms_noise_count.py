import sys

import adi
import numpy as np
from scipy import signal
import sin

#M2k libraries#
import libm2k
import time
##########

# importing os module 
import os


# Optionally pass URI as command line argument,
# else use default context manager search
my_uri = sys.argv[1] if len(sys.argv) >= 2 else "ip:analog.local"
print("Connecting with CN0577 context at " + str(my_uri))

device_name = "ltc2387"
vref = 4.096
board = input("B#: ")

for j in range(3):
    my_adc = adi.ltc2387(uri=my_uri)
    # my_adc.rx_buffer_size = 131072
    my_adc.rx_buffer_size = 1000
    my_adc.sampling_frequency = 5* (3-j) *1000000


    data = my_adc.rx()
    x = np.arange(0, len(data))
    voltage = data * 2.0 * vref / (2 ** 18)
    dc = np.average(voltage)  # Extract DC component
    ac = voltage - dc  # Extract AC component

    rms= np.std(voltage)
    print("RMS= ", rms)


    record = open("rms_data.csv","a")
    record.write("B"+ board + "," + str(my_adc.sampling_frequency) + "," + str(rms) + "," + "\n")
    record.close()

    del my_adc
