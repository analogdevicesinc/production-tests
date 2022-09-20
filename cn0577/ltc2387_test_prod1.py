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



#dumping EEPROM information to board
sn= input("Enter serial number: ")
path_EEPROM ="/sys/devices/soc0/fpga-axi@0/41620000.i2c/i2c-1/1-0050/eeprom"
path_masterfile = "cn0577master.bin"
os.system('fru-dump -i '+ path_masterfile + " -o " + path_EEPROM + " -s " + sn)


for i in range(3):
    
    #Connect to M2k#
    ctx=libm2k.m2kOpen()
    if ctx is None:
        print("Connection Error: No ADALM2000 device available/connected to your PC.")
        exit(1)
    ###########

    #Initialize M2k#
    ain=ctx.getAnalogIn()
    aout=ctx.getAnalogOut()
    trig=ain.getTrigger()

    # Prevent bad initial config for ADC and DAC
    ain.reset()
    aout.reset()

    ctx.calibrateADC()
    ctx.calibrateDAC()

    ain.enableChannel(0,True)
    ain.enableChannel(1,True)
    ain.setSampleRate(100000)
    ain.setRange(0,-10,10)

    aout.setSampleRate(0, 750000)
    aout.setSampleRate(1, 750000)
    aout.enableChannel(0, True)
    aout.enableChannel(1, True)

    #Set the output of M2k +/-AWG#
    x=np.linspace(-np.pi,np.pi,1024)

    print("Differential Input Vpp =", i+1)
    buffer1=(np.sin(x))*(i+1)
    buffer2=(-np.sin(x))*(i+1)


    buffer = [buffer1, buffer2]

    aout.setCyclic(True)
    aout.push(buffer)


    ##########

    device_name = "ltc2387"
    vref = 4.096


    my_adc = adi.ltc2387(uri=my_uri)
    my_adc.rx_buffer_size = 131072
    my_adc.sampling_frequency = 10000000
    

    data = my_adc.rx()
    x = np.arange(0, len(data))
    voltage = data * 2.0 * vref / (2 ** 18)
    dc = np.average(voltage)  # Extract DC component
    ac = voltage - dc  # Extract AC component

    parameters = sin.sin_params(voltage)
    snr = parameters[1]
    thd = parameters[2]
    sinad = parameters[3]
    enob = parameters[4]
    sfdr = parameters[5]
    floor = parameters[6]
    
    print("SNR = ", snr)
    if snr > 43:
        print("SNR pass")
    else:
        print("SNR fail")
    
    print("THD = ", thd)
    if thd < -45:
        print("THD pass")
    else:
        print("THD fail")
    
    print("SINAD = ", sinad)
    if sinad > 42:
        print("SINAD pass")
    else:
        print("SINAD fail")

    del my_adc
