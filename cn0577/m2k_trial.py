from asyncore import file_dispatcher
import sys

import adi
import numpy as np
from scipy import signal

# M2k libraries#
import libm2k
import time
import sine_gen
import sin_params

# importing os module 
import os

my_uri = sys.argv[1] if len(sys.argv) >= 2 else "ip:analog.local"
print("Connecting with CN0577 context at " + str(my_uri))

device_name = "ltc2387"
vref = 4.096
board = input("B#: ")

# Prompt the user to connect an ADALM2000 test jig to analog inputs.
input( " Connect ADALM2000 test jig ")

sine_gen.main()
print("ADALM2000 runs successfully")

# capture a block of 8192 (actually let's bump this to 256k, 2**18 )samples per channel -is this sampling freq or buffer size?
my_adc = adi.ltc2387(uri=my_uri)
# my_adc.rx_buffer_size = 131072
my_adc.rx_buffer_size = 256000
my_adc.sampling_frequency = 10000000

data = my_adc.rx()

# Verify DC offset (average of all samples) less than TBD
x = np.arange(0, len(data))
voltage = data * 2.0 * vref / (2 ** 18)
dc = np.average(voltage)  # Extract DC component
print("DC component=", dc)

# Subtract DC offset from data record, apply window (what type of window?)
ac = voltage - dc  # Extract AC component
print("AC component=", ac)

# Take FFT of data (via sin_params.py functions), verify:
# window_type= BLACKMAN_HARRIS_92
fft_data = sin_params.windowed_fft_mag(voltage)

# Location of fundamental in the correct bin! (Helps to weed out severely distorted waveforms, misaligned data, etc.) 
# fundamental amplitude between TBD and TBD
# max_harms=1
# harm_bins, harms, harm_bws = sin_params.find_harmonics(fft_data, max_harms)
fund, fund_bin = sin_params.get_max(fft_data)
print("Fundamental amplitude =", fund)
print("Fundamental location =", fund_bin)

record = open("fund_data.csv","a")
record.write("B"+ board + "," + str(my_adc.sampling_frequency) + "," + str(fund)+ "," + str(fund_bin) + ","+ str(dc) + "," + "\n")
record.close()

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
    print("THD pass")
else:
    print("THD fail, THD =", thd)


if snr > 43:
    print("SNR pass")
else:
    print("SNR fail, SNR=", snr)




# Switch in a 1000:1 attenuator, same FFT tests. THD and SNR should actually be about the same, since the ADC resolution is very high.




del my_adc


