import sys

import adi
import numpy as np
from scipy import signal
import sin_params

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
input( " Short input to ground ")

for j in range(5):
    my_adc = adi.ltc2387(uri=my_uri)
    # my_adc.rx_buffer_size = 131072
    my_adc.rx_buffer_size = 8000
    # my_adc.sampling_frequency = 5* (3-j) *1000000
    my_adc.sampling_frequency = 10000000


    data = my_adc.rx()
    x = np.arange(0, len(data))

    # Figure out how to do this correctly - need to sign extend bit 17
    for i in range(len(data)):
        if data[i] > (2 ** 17)-1:
            data[i] -= 2 ** 18

    # Record ADC code data
    filename = str(board)+"_"+ str(j+1)+ "_RMS_count_"+str(my_adc.sampling_frequency)+".csv"
    data_record = open(filename,"w")
    data_record.write("Data point,ADC data\n")

    for l in range(len(data)):
        data_record.write(str(x[l])+","+str(data[l])+"\n")
    data_record.close()


    voltage = data * 2.0 * vref / (2 ** 18)
    dc = np.average(voltage)  # Extract DC component
    ac = voltage - dc  # Extract AC component

    rms= np.std(voltage)
    print("RMS= ", rms)


    record = open("rms_data.csv","a")
    # record.write("SN, Sampling Frequency, RMS\n")
    record.write("B"+ board +"_"+ str(j+1)+ "," + str(my_adc.sampling_frequency) + "," + str(rms) + "," + "\n")
    record.close()

    del my_adc