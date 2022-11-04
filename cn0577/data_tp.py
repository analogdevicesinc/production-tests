#This script aims to capture data set to verify data limits for SNR, THD, fundamental amplitude and fundamental bin location
#This script uses m2k as input using sine_gen.py from libm2k tools
#Test jig was used to connect ADALM2000 and CN0577

# from asyncore import file_dispatcher
import sys

import adi
import numpy as np
# from scipy import signal

# M2k libraries#
import libm2k
import time
import sine_gen
import sin_params
import matplotlib.pyplot as plt

# importing os module 
import os

# my_uri = "ip:169.254.92.202"
my_uri = "ip:analog.local"
#my_uri = sys.argv[1] if len(sys.argv) >= 2 else "ip:analog.local"
print("Connecting with CN0577 context at " + str(my_uri))

device_name = "ltc2387"
vref = 4.096
sn = input("B#: ")

# Prompt the user to connect an ADALM2000 test jig to analog inputs.
input( " Connect ADALM2000 test jig ")

ampl= 2.048
offset=2.048
sine_gen.main(ampl, offset)
print("ADALM2000 runs successfully")

for n in range(1):
    # print("B",sn,"_",n+1)
    # capture a block of 8192 (actually let's bump this to 256k, 2**18 )samples per channel -is this sampling freq or buffer size?
    my_adc = adi.ltc2387(uri=my_uri)
    # my_adc.rx_buffer_size = 131072
    my_adc.rx_buffer_size = 256000
    my_adc.sampling_frequency = 10000000

    data = my_adc.rx()

    # Figure out how to do this correctly - need to sign extend bit 17
    for i in range(len(data)):
        if data[i] > (2 ** 17)-1:
            data[i] -= 2 ** 18

    x2 = np.arange(0, len(data))
    plt.figure(1)
    plt.clf()
    plt.plot(x2, data)
    plt.xlabel("frequency [Hz]")
    plt.ylabel("ADC data")
    plt.show()
    

    # Verify DC offset (average of all samples) less than TBD
    x = np.arange(0, len(data))
    voltage = data * 2.0 * vref / (2 ** 18)
    dc = np.average(voltage)  # Extract DC component
    plt.plot(voltage)
    plt.title("Voltage reading")
    plt.show()
    print("DC component=", dc)

    # Subtract DC offset from data record, apply window (what type of window?)
    ac = voltage - dc  # Extract AC component
    print("AC component=", ac)

    # Record ADC code data
    # filename = str(sn)+ "_" + str(n+1) +"_ampl_" + str(ampl) +"_offset_" + str(offset) +".csv"
    filename = str(sn) +"_ampl_" + str(ampl) +"_offset_" + str(offset) +".csv"
    data_record = open(filename,"w")
    data_record.write("Data point,ADC data\n")

    for l in range(len(data)):
        data_record.write(str(x[l])+","+str(data[l])+"\n")
    data_record.close()

    # Take FFT of data (via sin_params.py functions), verify:
    # window_type= BLACKMAN_HARRIS_92
    fft_data = sin_params.windowed_fft_mag(voltage)
    plt.plot(fft_data)
    plt.title("FFT")
    plt.xlabel("FFT Bin")
    plt.ylabel("Amplitude")
    # plt.ylim(-2, 2.5)
    plt.show()

    # filename1 = str(sn) +"_FFT_data" +".csv"
    # data_record = open(filename1,"w")
    # data_record.write("Data point,ADC data\n")

    # for l in range(len(data)):
    #     data_record.write(str(x[l])+","+str(data[l])+"\n")
    # data_record.close()

    # Location of fundamental in the correct bin! (Helps to weed out severely distorted waveforms, misaligned data, etc.) 
    # fundamental amplitude between TBD and TBD
    # max_harms=1
    # harm_bins, harms, harm_bws = sin_params.find_harmonics(fft_data, max_harms)
    fund, fund_bin = sin_params.get_max(fft_data)
    print("Fundamental amplitude =", fund)
    print("Fundamental location =", fund_bin)



    # Total Harmonic Distortion less than TBD (probably 50-60dB, limited by the ADALM2000).
    # SNR better than 50-60dB, limited by ADALM2000

    parameters = sin_params.sin_params(voltage)
    snr = parameters[1]
    thd = parameters[2]
    sinad = parameters[3]
    enob = parameters[4]
    sfdr = parameters[5]
    floor = parameters[6]


    if thd < -45:
        print("THD pass, THD =", thd)
    else:
        print("THD fail, THD =", thd)


    if snr > 43:
        print("SNR pass, SNR =", snr)
    else:
        print("SNR fail, SNR =", snr)

    print("Floor =", floor)
    print(" dBc")

    record = open("fund_data.csv","a")
    # record.write("SN, Sampling Frequency, Fundamental Amplitude, Fundamental bin location, DC component, m2k_amp, m2k_offset, SNR, THD, Floor\n")
    record.write("B"+ sn + "_" + str(n+1)+ "," + str(my_adc.sampling_frequency) + "," + str(fund)+ "," + str(fund_bin) + "," + str(dc) + "," +  str(ampl) + "," + str(offset) + "," + str(snr)+ "," + str(thd)+ "," + str(floor)+ "\n")
    record.close()

    # Switch in a 1000:1 attenuator, same FFT tests. THD and SNR should actually be about the same, since the ADC resolution is very high.




    del my_adc


