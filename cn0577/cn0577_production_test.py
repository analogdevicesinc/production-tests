# from asyncore import file_dispatcher
import sys

import adi
import numpy as np
# from scipy import signal

# M2k libraries#
import sine_gen

import sin_params
import matplotlib.pyplot as plt

import eeprom_frudump
import rms_noise
import time

# my_uri = "ip:169.254.92.202"
# my_uri = "ip:analog.local"
my_uri = sys.argv[1] if len(sys.argv) >= 2 else "ip:analog.local"
print("Connecting with CN0577 context at " + str(my_uri))

vref = 4.096
# Program FMC ID EEPROM with serial number.
sn = input("Enter serial number: ")
eeprom_frudump.input_data(sn)

failed_tests = []

my_adc = adi.ltc2387(uri=my_uri)
# Prompt the test operator to short the input to ground
input("\nStarting Production Test! \nConnect ADALM2000 test jig.\nShort both input to ground, press enter to continue...")
# Verify RMS noise less than TBD counts
rms_result = rms_noise.count(sn, my_uri)
if rms_result==0:
    failed_tests.append("Fails RMS test")
    
# Prompt the user to connect an ADALM2000 test jig to analog inputs.
input( "\nRemove short connection of input to ground.\nSwitch attenuation 1:1.\nSwitch ON the M2k input on test jig, press enter to continue...")

#Play back a 90% full-scale sinewave at 20kHz using ADALM2000
ampl= 2.048
offset=2.048
sine_gen.main(ampl, offset)

do_plots = False

# Capture a block of 256k samples per channel.
my_adc.rx_buffer_size = 256000
my_adc.sampling_frequency = 10000000

for n in range(2):
    att=1 # first run, attenuation switch 1:1
    
    if n==1: # second run attenuation switch 100:1
        input("\nSwitch to 100:1 attenuation, press enter to continue...")
        att=100
        
        my_adc = adi.ltc2387(uri=my_uri)
        my_adc.rx_buffer_size = 256000
        my_adc.sampling_frequency = 10000000

    time.sleep(1)
    data = my_adc.rx()

    # to sign extend bit 17
    for i in range(len(data)):
        if data[i] > (2 ** 17)-1:
            data[i] -= 2 ** 18

    # Verify DC component less than 0.1
    x = np.arange(0, len(data))
    voltage = data * 2.0 * vref / (2 ** 18)
    dc = np.average(voltage)  # Extract DC component
    if dc < 0.1:
        print("DC component PASS, DC = ", dc)
    else:
        print("DC component FAIL, DC = ", dc)
        failed_tests.append("Fails DC component test, attenuation setting=" + str(att))
        record = open("error.csv","a")
        record.write(sn + "," + str(att) + "," + "DC component=" + "," + str(dc) + "," + "\n")
        record.close()
    
    if do_plots == True:
        plt.plot(voltage)
        plt.title("Voltage reading")
        plt.show()

    # Subtract DC offset from data record, apply window
    ac = voltage - dc  # Extract AC component

    # Take FFT of data (via sin_params.py functions), verify:
    # window_type= BLACKMAN_HARRIS_92
    fft_data = sin_params.windowed_fft_mag(voltage)

    if do_plots == True:
        plt.plot(fft_data)
        plt.title("FFT")
        plt.xlabel("FFT Bin")
        plt.ylabel("Amplitude")
        plt.show()

    # Verify location of fundamental between bin 510 and 514 (correct bin = 512)
    fund, fund_bin = sin_params.get_max(fft_data)
    if (510 < fund_bin < 514):
        print("Fundamental bin location PASS, location =", fund_bin)
    else:
        print("Fundamental bin location FAIL, location =", fund_bin)
        failed_tests.append("Fails Fundamental bin location test, attenuation setting=" + str(att))
        record = open("error.csv","a")
        record.write(sn + "," + str(att) + "," + "Fundamental bin location=" + "," + str(fund_bin) + "," + "\n")
        record.close()
    
    # Verify fundamental amplitude between lim1 and lim2 (correct fundamental amplitude = 2.048 @ 1:1, 0.0138)
    if att==1:
        fund_lim1= 2
        fund_lim2= 2.8
    else: #att==100
        fund_lim1= 0.012
        fund_lim2= 0.014

    if (fund_lim1 < fund < fund_lim2):
        print("Fundamental amplitude PASS, amplitude =", fund)
    else:
        print("Fundamental amplitude FAIL, amplitude =", fund)
        failed_tests.append("Fails Fundamental amplitude test, attenuation setting=" + str(att))
        record = open("error.csv","a")
        record.write(sn + "," + str(att) + "," + "Fundamental amplitude=" + "," + str(fund) + "," + "\n")
        record.close()


# For 1:1 attenuator:
# Total Harmonic Distortion less than 65 
# SNR better than 50  

# For 100:1 attenuator, same FFT tests:
# Total Harmonic Distortion less than 65 
# SNR better than 35
    parameters = sin_params.sin_params(voltage)
    snr = parameters[1]
    thd = parameters[2]
    sinad = parameters[3]
    enob = parameters[4]
    sfdr = parameters[5]
    floor = parameters[6]

    if att==1:
        snr_lim= 50
    else: #att==100
        snr_lim= 35

    if snr > snr_lim:
        print("SNR PASS, SNR =", snr)
    else:
        print("SNR FAILS, SNR =", snr)
        failed_tests.append("Fails SNR test, attenuation setting=" + str(att))
        record = open("error.csv","a")
        record.write(sn + "," + str(att) + "," + "SNR=" + "," + str(snr) + "," + "\n")
        record.close()

    if thd < -65:
        print("THD PASS, THD =", thd)
    else:
        print("THD FAILS, THD =", thd)
        failed_tests.append("Fails THD test, attenuation setting=" + str(att))
        record = open("error.csv","a")
        record.write(sn + "," + str(att) + "," + "THD=" + "," + str(thd) + "," + "\n")
        record.close()


    record = open("cn0577_report.csv","a")
    record.write("SN, Attenuation, Sampling Frequency, Fundamental Amplitude, Fundamental bin location, DC component, SNR, THD, Floor\n")
    record.write("B"+ sn + "_" + "," + str(att) + "_" + "," + str(my_adc.sampling_frequency) + "," + str(fund)+ "," + str(fund_bin) + "," + str(dc) + "," + str(snr)+ "," + str(thd)+ "," + str(floor)+ "\n")
    record.close()
    del my_adc




if len(failed_tests) == 0:
    print("\n\nBoard PASSES!!")
else:
    print("\n\nBoard FAILED the following tests:")
    for failure in failed_tests:
        print(failure)
    print("\nNote failures and set aside for debug.")


