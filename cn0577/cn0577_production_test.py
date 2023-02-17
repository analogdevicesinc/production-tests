# Copyright (C) 2023 Analog Devices, Inc.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#     - Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     - Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#     - Neither the name of Analog Devices, Inc. nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#     - The use of this software may or may not infringe the patent rights
#       of one or more patent holders.  This license does not release you
#       from the requirement that you obtain separate licenses from these
#       patent holders to use this software.
#     - Use of the software either in source or binary form, must be run
#       on or directly connected to an Analog Devices Inc. component.
#
# THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED.
#
# IN NO EVENT SHALL ANALOG DEVICES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, INTELLECTUAL PROPERTY
# RIGHTS, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import sys
import adi
import numpy as np
import sine_gen
import sin_params
import matplotlib.pyplot as plt
import time
import os

def eeprom_frudump():
    path_EEPROM ="/sys/devices/soc0/fpga-axi@0/41620000.i2c/i2c-1/1-0050/eeprom"
    path_masterfile = "cn0577/cn0577master.bin"
    
    res1 = ''
    res1 = os.system('fru-dump -i '+ path_masterfile + " -o " + path_EEPROM + " -s " + sn)
    #if writing to eeprom fail, res1=1
    if (res1):
        sys.exit('Dumping of bin file to eeprom FAILED\n')

def rms_noise(my_uri):
    my_adc = adi.ltc2387(my_uri)
    my_adc.rx_buffer_size = 8000
    my_adc.sampling_frequency = 10000000

    shorted_input = my_adc.rx()
    time.sleep(2)
    noise_v = shorted_input * vref * 2 / (2 ** 18)               #Convert output digital code to voltage
    measured_noise = np.std(noise_v)
    print("Measured Noise: ", measured_noise) 

    if measured_noise < 0.002:
        print("RMS noise test PASS")
    else:
        print("RMS noise test FAIL")
        failed_tests.append("Failed rms noise test")
        record = open("error.csv","a")
        record.write(sn + "," + "RMS noise=" + "," + str(measured_noise) + "," + "\n")
        record.close()

    del my_adc
    
def fft_test(my_uri,att):

    my_adc = adi.ltc2387(uri=my_uri)
    my_adc.rx_buffer_size = 256000
    my_adc.sampling_frequency = 10000000

    data = my_adc.rx()
    time.sleep(2)

    # to sign extend bit 17
    for i in range(len(data)):
        if data[i] > (2 ** 17)-1:
            data[i] -= 2 ** 18

    # Verify DC component less than 0.1
    x = np.arange(0, len(data))
    voltage = data * 2.0 * vref / (2 ** 18)
    dc = np.average(voltage)  # Extract DC component
    print("DC component= ", dc)

    if dc < 0.1:
        print("DC component test PASS")
    else:
        print("DC component test FAIL")
        failed_tests.append("Fails DC component test, attenuation setting = " + str(att))
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
    print("Fundamental bin location =", fund_bin)
    if (510 < fund_bin < 514):
        print("Fundamental bin location test PASS")
    else:
        print("Fundamental bin location test FAIL")
        failed_tests.append("Fails Fundamental bin location test, attenuation setting = " + str(att))
        record = open("error.csv","a")
        record.write(sn + "," + str(att) + "," + "Fundamental bin location=" + "," + str(fund_bin) + "," + "\n")
        record.close()
    
    # Verify fundamental amplitude between lim1 and lim2 (expected fundamental amplitude = 2.048 @ 1:1, 0.0138)
    if att==1:
        fund_lim1= 2
        fund_lim2= 2.8
    else: #att==100
        fund_lim1= 0.012
        fund_lim2= 0.014

    print("Fundamental bin amplitude =", fund)
    if (fund_lim1 < fund < fund_lim2):
        print("Fundamental amplitude test PASS")
    else:
        print("Fundamental amplitude test FAIL")
        failed_tests.append("Fails Fundamental amplitude test, attenuation setting = " + str(att))
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

    print("SNR =", snr)
    if snr > snr_lim:
        print("SNR test PASS")
    else:
        print("SNR test FAIL")
        failed_tests.append("Fails SNR test, attenuation setting = " + str(att))
        record = open("error.csv","a")
        record.write(sn + "," + str(att) + "," + "SNR=" + "," + str(snr) + "," + "\n")
        record.close()

    print("THD =", thd)
    if thd < -65:
        print("THD test PASS")
    else:
        print("THD test FAIL")
        failed_tests.append("Fails THD test, attenuation setting = " + str(att))
        record = open("error.csv","a")
        record.write(sn + "," + str(att) + "," + "THD=" + "," + str(thd) + "," + "\n")
        record.close()
        
    record = open("cn0577_report.csv","a")
    record.write("SN, Attenuation, Sampling Frequency, Fundamental Amplitude, Fundamental bin location, DC component, SNR, THD, Floor\n")
    record.write(sn + "," + str(att) + "," + str(my_adc.sampling_frequency) + "," + str(fund)+ "," + str(fund_bin) + "," + str(dc) + "," + str(snr)+ "," + str(thd)+ "," + str(floor)+ "\n")
    record.close()   
    del my_adc


my_uri = sys.argv[1] if len(sys.argv) >= 2 else "ip:analog.local"
print("Connecting with CN0577 context at " + str(my_uri))

vref = 4.096
# Program FMC ID EEPROM with serial number.
sn = input("Enter serial number: ")
eeprom_frudump()
failed_tests = []

# my_adc = adi.ltc2387(uri=my_uri)
# Prompt the test operator to short the input to ground
input("\nStarting Production Test! \n\nConnect ADALM2000 with test jig \nWARNING: CN0577 should not be removed to the ZedBoard while the power is ON\nSet ADALM2000 switch in test jig: OFF. \nPress enter to continue...")
input("\nShort both input to ground, press enter to continue...")
# Verify RMS noise less than TBD counts
rms_noise(my_uri)
    
# Prompt the user to connect an ADALM2000 test jig to analog inputs.
input( "\nCarefully remove short connection of input to ground, press enter to continue...")
input( "\nSwitch attenuation 1:1.\nSwitch ON the ADALM2000 input on test jig, press enter to continue...")

#Play back a 90% full-scale sinewave at 20kHz using ADALM2000
ampl= 2.048
offset=2.048
sine_gen.main(ampl, offset)

do_plots = False

att=1
fft_test(my_uri,att)

att=100
input( "\nSwitch attenuation 100:1.\nSwitch ON the ADALM2000 input on test jig, press enter to continue...")
fft_test(my_uri,att)

if len(failed_tests) == 0:
    print("\n\nBoard PASSES!!")
else:
    print("\n\nBoard FAILED the following tests:")
    for failure in failed_tests:
        print(failure)
    print("\nNote failures and set aside for debug.")

#Automatic shutdown after completing the test to avoid improper shutdown and hotswap of board.
x = input("Press enter to finish test.")
print("Shutting down... \nTurn off ZedBoard.")
if os.name == "posix":
    os.system("sudo shutdown -h now")
else:
    print("Sorry, can only shut down system when running locally on Zedboard\n")
