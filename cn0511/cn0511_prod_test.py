# Copyright (C) 2022 Analog Devices, Inc.
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


import pandas as pd

#import numpy
import sys
import datetime
#import time
import os

from hat_id_eep import hat_id_eep


#imports for ladybug###########################################################
import usb.core
import usb.util
import pyvisa as visa
###############################################################################

#imports for initialization ###################################################
import iio
###############################################################################


####### Constants #############################################################
#Masks for calculating register values:
m_byte_5 = 280375465082880#=11111111 00000000 00000000 00000000 00000000 00000000
m_byte_4 =   1095216660480#=00000000 11111111 00000000 00000000 00000000 00000000
m_byte_3 =      4278190080#=00000000 00000000 11111111 00000000 00000000 00000000
m_byte_2 =        16711680#=00000000 00000000 00000000 11111111 00000000 00000000
m_byte_1 =           65280#=00000000 00000000 00000000 00000000 11111111 00000000
m_byte_0 =             255#=00000000 00000000 00000000 00000000 00000000 11111111

output_power_margin = 0
###############################################################################


#Filename and directory########################################################
freq_step_plot = 1000000000
###############################################################################


# Function that returns the difference in dBm between the keysight's output
# and the ladybug's output at frequency freq_x.
def keysight_minus_ladybug_output(freq_x):
    freq_x = float(freq_x)

    if freq_x < 100e6:
        attenuation = 0.0016

    #Interval 0:
    elif freq_x >= 100e6 and freq_x < 2730e6:
        attenuation = 0.0016 + 3.741444866920150E-11*(freq_x - 100e6)

    #Interval 1:
    elif freq_x >= 2730e6 and freq_x < 2860e6:
        attenuation = 0.1 + 1.083846153846150E-9*(freq_x - 2730e6)

    #Interval 2:
    elif freq_x >= 2860e6 and freq_x < 2970e6:
        attenuation = 0.2409 + -3.232727272727270E-9*(freq_x - 2860e6)

    #Interval 3:
    elif freq_x >= 2970e6 and freq_x <= 3100e6:
        attenuation = -0.1147 + 5.046153846153850E-10*(freq_x - 2970e6)

    #Interval 4:
    elif freq_x >= 3100e6 and freq_x <= 3200e6:
        attenuation = -0.0491 + -4.593000000000000E-9*(freq_x - 3100e6)

    #Interval 5:
    elif freq_x >= 3200e6 and freq_x <= 3270e6:
        attenuation = -0.5084 + 3.992857142857140E-9*(freq_x - 3200e6)

    #Interval 6:
    elif freq_x >= 3270e6 and freq_x <= 3420e6:
        attenuation = -0.2289 + -1.612000000000000E-9*(freq_x - 3270e6)

    #Interval 7:
    elif freq_x >= 3420e6 and freq_x <= 3550e6:
        attenuation = -0.4707 + 2.188461538461540E-9*(freq_x - 3420e6)

    #Interval 8:
    elif freq_x >= 3550e6 and freq_x <= 3630e6:
        attenuation = -0.1862 + -1.279500000000000E-8*(freq_x - 3550e6)

    #Interval 9:
    elif freq_x >= 3630e6 and freq_x <= 3730e6:
        attenuation = -1.2098 + 8.658000000000000E-9*(freq_x - 3630e6)

    #Interval 10:
    elif freq_x >= 3730e6 and freq_x <= 3820e6:
        attenuation = -0.344 + -1.020000000000000E-8*(freq_x - 3730e6)

    #Interval 11:
    elif freq_x >= 3820e6 and freq_x <= 3900e6:
        attenuation = -1.262 + 7.251250000000000E-9*(freq_x - 3820e6)

    #Interval 12:
    elif freq_x >= 3900e6 and freq_x <= 4030e6:
        attenuation = -0.6819 + -4.354615384615390E-9*(freq_x - 3900e6)

    #Interval 13:
    elif freq_x >= 4030e6 and freq_x <= 4120e6:
        attenuation = -1.248 + 6.544444444444440E-9*(freq_x - 4030e6)

    #Interval 14:
    elif freq_x >= 4120e6 and freq_x <= 4170e6:
        attenuation = -0.659 + -7.800000000000000E-9*(freq_x - 4120e6)

    #Interval 15:
    elif freq_x >= 4170e6 and freq_x <= 4290e6:
        attenuation = -1.049 + 4.575000000000000E-9*(freq_x - 4170e6)

    #Interval 16:
    elif freq_x >= 4290e6 and freq_x <= 4540e6:
        attenuation = -0.5 + -6.960000000000000E-10*(freq_x - 4290e6)

    #Interval 17:
    elif freq_x >= 4540e6 and freq_x <= 4740e6:
        attenuation = -0.674 + -3.150000000000000E-9*(freq_x - 4540e6)

    #Interval 18:
    elif freq_x >= 4740e6 and freq_x <= 4910e6:
        attenuation = -1.304 + 3.464705882352940E-9*(freq_x - 4740e6)

    #Interval 19:
    elif freq_x >= 4910e6 and freq_x <= 5000e6:
        attenuation = -0.715 + -9.950000000000000E-9*(freq_x - 4910e6)

    #Interval 20:
    elif freq_x >= 5000e6 and freq_x <= 5090e6:
        attenuation = -1.6105 + 4.272222222222220E-9*(freq_x - 5000e6)

    #Interval 21:
    elif freq_x >= 5090e6 and freq_x <= 5450e6:
        attenuation = -1.226 + -2.183333333333330E-9*(freq_x - 5090e6)

    #Interval 22:
    elif freq_x >= 5450e6 and freq_x <= 5550e6:
        attenuation = -2.012 + 1.350000000000000E-9*(freq_x - 5450e6)

    #Interval 23:
    elif freq_x >= 5550e6 and freq_x <= 5810e6:
        attenuation = -1.877 + -2.080769230769230E-9*(freq_x - 5550e6)

    #Interval 24:
    elif freq_x >= 5810e6 and freq_x <= 5870e6:
        attenuation = -2.418 + 2.800000000000000E-9*(freq_x - 5810e6)

    #Interval 25:
    elif freq_x >= 5870e6 and freq_x <= 5990e6:
        attenuation = -2.25 + -1.119166666666670E-8*(freq_x - 5870e6)

    elif freq_x > 5990e6:
        attenuation = -2.25 + -1.119166666666670E-8*(5990e6 - 5870e6)

    return attenuation
###############################################################################


# This function reads the output power with ladybug ###########################
def read_output_ladybug():
    output_power_lb = inst.query("MEAS?")
    print("Measured_output_power" + inst.query("MEAS?"))
    return output_power_lb
###############################################################################


# This function reads the output power with ladybug and subtracts the
# approximated differennce calculated with keysight_minus_ladybug_output:
"""
current_freq -> the freqeuency at which the output power is measured
"""
def read_output_ladybug_optimized(current_freq):
    output_power_lb = str(float(inst.query("MEAS?")) +
                      float(keysight_minus_ladybug_output(current_freq)))
    return output_power_lb
###############################################################################


# Write to register function ##################################################
def write_reg(chip_name_str, register_addr_hex, value_addr_hex):
    #ex write_reg('ad9166', 0x115, 0xEB)
    iio_ad9166.reg_write(register_addr_hex, int(value_addr_hex, 16))
###############################################################################


# Set NCO value function ######################################################
def set_out_frequency(fout):
    iio_ad9166_ch.attrs["nco_frequency"].value = str(fout)
###############################################################################


# Set output amplitude function ###############################################
def set_out_amplitude(out_amplitude_dbm):
    reg_amplitude_dec = int(10**(out_amplitude_dbm/20)*32767)
    reg_amplitude_high = hex(reg_amplitude_dec >> 8)
    reg_amplitude_low = hex(reg_amplitude_dec&255)
    write_reg('ad9166', 0x14E, reg_amplitude_high)
    write_reg('ad9166', 0x14F, reg_amplitude_low)
###############################################################################


# Set output frequency and amplitude without Ioutfs trimmed (untested)#########
def set_out_amplitude_frequency(out_amplitude_dbm, out_frequency_hz):
    set_out_amplitude(out_amplitude_dbm)
    set_out_frequency(out_frequency_hz)
###############################################################################


# Adjust output power offset with ladybug######################################
# This function returns the difference that has to be added on 0x42|0x41 for
# a specific board to all offset consants in order to calibrate the output.
def calibrate_output_power_vs_frequency_offset_lb_adjustment(actual_offset,
        fmin, mid_scale, step_offset_reg, output_power_margin, dbm_wanted = 0):
    #Suggested modifications: make mid_scale internal parameter of the function
    fmin = int(fmin)
    output_power_margin = int(output_power_margin)
    dbm_wanted = int(dbm_wanted)

    nr_tries = 0
    verif_amplitude = 0.4
    # Repeat the calculation of the gain constant if the verification of
    # verif_amplitude fails.
    while(float(verif_amplitude) < -0.1) or (float(verif_amplitude) > 0.1):
        nr_tries += 1
        print("\n"+
            "OFFSET ADJUSTMENT at frequency [Hz]: ", str(fmin), " START--------")


        #Step 1###########################################################
        # Set the desired output with registers 0x14E and 0x14F. The values of
        # 0x14E and 0x14F registers remain constant for the full calibration
        # process:
        set_out_amplitude(dbm_wanted + output_power_margin)
        ##################################################################


        #Step 2###########################################################
        # Iofs_reg = Iofs_reg_initial (Iofs_reg is the number that has to be put
        # on registers 0x42|0x41, registers that modify Ioutfs value)

        # -> position at the middle of the with Iofs_reg => put the value 0x80
        #    on register 0x42 and 0x0 on register 0x41.

        # In this example: Iofs_reg_intial = mid_scale
        lsb_mid_scale = hex(mid_scale&3)
        msb_mid_scale = hex(mid_scale >> 2)
        write_reg('ad9166', 0x42, msb_mid_scale)
        write_reg('ad9166', 0x41, lsb_mid_scale)
        ##################################################################


        #Step 3###########################################################
        # Measure Pout(fmin, Iofs_reg_initial)

        # -> measure the output power for fmin and Iofs_reg set at #2

        # In this example: Pout(fmin, Iofs_reg_initial) = out_power_ioutfs_mid

        set_out_frequency(fmin) #set fmin
        out_power_ioutfs_mid = read_output_ladybug_optimized(fmin) #save the
                #measured amplitude with the Iofs_reg = Iofs_reg_initial set at #2
        print("out_power_ioutfs_mid: ", out_power_ioutfs_mid)
        ##################################################################


        #Step 4###########################################################
        # Choose Iofs_reg_increment_offset
        #  (for example Iofs_reg_increment_offset = 15)

        # -> choose the increment step size on Iofs_reg (this value is not 1
        #    because the measuring unit has errors).
        # In this example: Iofs_reg_increment_offset = step_offset_reg
        # step_offset_reg is taken as a parameter by this function
        ##################################################################


        #Step 5###########################################################
        # Measure Pout(fmin, Iofs_reg_initial + Iofs_reg_increment_offset)
        # -> measure the output power for fmin and Iofs_reg = Iofs_reg_initial +
        #                                                     + Iofs_reg_increment.
        # In this example:Iofs_reg_initial = mid_scale;
        #                 Iofs_reg_increment = step_offset_reg;
        #                 Pout(fmin, Iofs_reg_initial + Iofs_reg_increment_offset)=
        #                 = out_power_ioutfs_mid_plus_step
        incremented_number = mid_scale + step_offset_reg
        print("incremented_number: ", incremented_number)

        lsb_incremented_number = hex(incremented_number&3)
        msb_incremented_number = hex(incremented_number >> 2)
        write_reg('ad9166', 0x42, msb_incremented_number)
        write_reg('ad9166', 0x41, lsb_incremented_number)

        set_out_frequency(fmin) #set fmin
        out_power_ioutfs_mid_plus_step = read_output_ladybug_optimized(fmin)
        print("out_power_ioutfs_mid_plus_step: ", out_power_ioutfs_mid_plus_step)
        ##################################################################


        #Step 6###########################################################
        # Calculate Pout_LSB_offset = Pout(fmin, Iofs_reg_initial +
        #                              + Iofst_reg_increment_offset) -
        #                              - Pout(fmin, Iofs_reg_initial)

        # -> calculate the increment in power from Iofs_reg_initial to
        #    Iofs_reg_initial + Iofs_reg_increment_offset

        #In this example:Pout(fmin, Iofs_reg_initial + Iofst_reg_increment_offset)=
        #                = float(out_power_ioutfs_mid_plus_step)
        #                Pout(fmin, Iofs_reg_initial) = float(out_power_ioutfs_mid)
        #                Pout_LSB_offset = pout_increment_offset
        pout_increment_offset = (float(out_power_ioutfs_mid_plus_step) -
                                float(out_power_ioutfs_mid))

        print("pout_increment_offset: ", pout_increment_offset)
        ##################################################################


        #Step 7###########################################################
        # Calculate N_Pout_LSB_offset = int( (Pout(fmin, Iofs_reg_initial) –
        #                                - desired_output_dbm) / Pout_LSB_offset)
        # -> calculate the number of Pout_LSB_offset needed to correct the offset
        #    error
        n_pout_increment_offset = (float(out_power_ioutfs_mid) -
                                float(dbm_wanted))/pout_increment_offset

        print("n_pout_increment_offset: ", n_pout_increment_offset)
        ##################################################################


        #Step 8###########################################################
        # Calculate Iofs_reg_offset_correction =
        # = Iofs_reg_initial - N_Pout_LSB_offset * Iofs_reg_increment_offset
        #-> calculate the number that has to be put on registers 0x42|0x41 for
        #   correcting the offset error, more exactly, the green term in the
        # previously developed formula
        # (Iofs_reg(fx) = 0x42|0x41 = Iofs_reg_offset_correction +
        #                             + Cst_gain_correction*(fx – fmin))
        offset_number_dec =int(mid_scale - n_pout_increment_offset*step_offset_reg)

        number_iofs = offset_number_dec
        print("number_iofs: ", number_iofs)

        if number_iofs > 1023:
            number_iofs = 1023

        lsb_number_iofs = hex(number_iofs&3)
        msb_number_iofs = hex(number_iofs >> 2)

        write_reg('ad9166', 0x42, msb_number_iofs)
        write_reg('ad9166', 0x41, lsb_number_iofs)

        verif_amplitude = read_output_ladybug_optimized(100000000)

        print("verif_amplitude: ", verif_amplitude)
        # Do iterative calculation:
        mid_scale = offset_number_dec

        if(int(nr_tries) > 5):
                break

    adj_dif = offset_number_dec - actual_offset

    print("offset_number_dec: " + str(offset_number_dec))
    print("actual_offsetL " +  str(actual_offset))
    print("adj_diff: " + str(adj_dif))
    print("OFFSET ADJUSTMENT stop--------------------------------------------"
    + "\n")
    ##################################################################
    return adj_dif
###############################################################################


# Return output power vs frequency for ladybug#################################
# Parameters: out_power_dbm  -> NCO Scale = output power in dbm;
#             fmin -> the start freuqncy (condition fmin > fmin_interval);
#             fmax -> maximum frequency;
#             fstep -> step frequency;
#             fmin_interval -> minimum frequency of the interval
#             offset_dec -> cn0511_offset for interval [fmin_interval; fmax)
#             cst_cal_gain -> cn0511_cst for interval [fmin_interval; fmax)

# The function returns a list of lists where the first sublist is the x axis
# and the second sublist is the y axis.
def output_power_vs_freq_calibrated_lb(out_power_dbm, fmin, fmax, fstep,
                                       fmin_interval, offset_dec, cst_cal_gain):
    fmin = int(fmin)
    fmax = int(fmax)
    fstep = int(fstep)

    x_axis_hz = []
    y_axis_dbm = []
    x_y_axis = []
    set_out_amplitude(out_power_dbm) # set 0 dBm amplitude
    for current_freq in range(fmin, fmax, fstep):
        set_out_frequency(current_freq)

        #calculates the number on 0x42|0x41 as function of frequency
        number_iofs = int(offset_dec + cst_cal_gain*(current_freq - fmin_interval))

        if number_iofs > 1023:
            number_iofs = 1023

        lsb_number_iofs = hex(number_iofs&3)
        msb_number_iofs = hex(number_iofs >> 2)
        write_reg('ad9166', 0x42, msb_number_iofs)
        write_reg('ad9166', 0x41, lsb_number_iofs)
        ############################################################

        measured_amplitude = read_output_ladybug_optimized(current_freq)
        #measured_frequancy = measure_frequency_hz()

        if((float(measured_amplitude) < float(out_power_dbm-5)) or (float(measured_amplitude) > float(out_power_dbm+5))):
            print("Calibration fail, the amplitude has a different value than the desired one!")
            return None
        else:
            print("Point calculated correctly!")

        print("Measured amplitude: " + str(measured_amplitude))
        print("Measured_frequency: " + str(current_freq) + "\n")
        y_axis_dbm.append( float(measured_amplitude) )
        x_axis_hz.append( str(current_freq) )

    x_y_axis.append(x_axis_hz)
    x_y_axis.append(y_axis_dbm)

    # print("X axis: ", x_axis_hz)
    # print("Y axis: ", y_axis_dbm)
    # print("x_y axis: ", x_y_axis)

    return x_y_axis
###############################################################################


# This function plots the calibrated output and saves it in a csv file for
# verification. It takes as input any frequency step
def output_power_calibrated_anystep_lb(frequency_step):
    # calculate points for 0 dbm###########################################
    frequency_step = float(frequency_step)
    y_vs_x_list_0dbm = [[],[]] #the first sublist contains the x axis and
                               #the 2nd sublist containts y axis

    # Run trough all frequencies with frequency_step:
    my_freq = 0
    while int(my_freq) < 6000000000:
        my_freq += frequency_step

        #Set and measure the output for the freqs below the first interval
        if(my_freq < cn0511_freq[0]):
            y_vs_x_list_aux = output_power_vs_freq_calibrated_lb(
                                0 + output_power_margin,
                                my_freq, cn0511_freq[0], frequency_step,
                                0, cn0511_offset[0], 0)

            y_vs_x_list_0dbm[0] = y_vs_x_list_0dbm[0] + y_vs_x_list_aux[0]
            y_vs_x_list_0dbm[1] = y_vs_x_list_0dbm[1] + y_vs_x_list_aux[1]
            my_freq = float(y_vs_x_list_0dbm[0][len(y_vs_x_list_0dbm[0]) - 1])


        #Check what interval contains my_freq and set and measure the output
        # power using the corresponding calibration constants
        for freq_list_index in range(0, len(cn0511_freq) - 1):
            if(my_freq >= cn0511_freq[freq_list_index]) and (my_freq < cn0511_freq[freq_list_index + 1]):
                y_vs_x_list_aux = output_power_vs_freq_calibrated_lb(
                                    0 + output_power_margin, my_freq,
                                    cn0511_freq[freq_list_index + 1], frequency_step,
                                    cn0511_freq[freq_list_index], cn0511_offset[freq_list_index],
                                    cn0511_gain[freq_list_index])

                y_vs_x_list_0dbm[0] = y_vs_x_list_0dbm[0] + y_vs_x_list_aux[0]
                y_vs_x_list_0dbm[1] = y_vs_x_list_0dbm[1] + y_vs_x_list_aux[1]
                my_freq = float(y_vs_x_list_0dbm[0][len(y_vs_x_list_0dbm[0]) - 1])


        #Set and measure the output for the last interval
        if(my_freq >= cn0511_freq[len(cn0511_freq) - 1]) and (my_freq < 5990000000):
                y_vs_x_list_aux = output_power_vs_freq_calibrated_lb(
                                    0 + output_power_margin, my_freq,
                                    5990000000, frequency_step,
                                    cn0511_freq[len(cn0511_freq) - 1], cn0511_offset[len(cn0511_freq) - 1],
                                    cn0511_gain[len(cn0511_freq) - 1])

                y_vs_x_list_0dbm[0] = y_vs_x_list_0dbm[0] + y_vs_x_list_aux[0]
                y_vs_x_list_0dbm[1] = y_vs_x_list_0dbm[1] + y_vs_x_list_aux[1]
                my_freq = float(y_vs_x_list_0dbm[0][len(y_vs_x_list_0dbm[0]) - 1])

    print("x_vs_y_list1: ", y_vs_x_list_0dbm)

    #create raw data#######################################################
    name_dict = {
            'Frequencies': y_vs_x_list_0dbm[0],
            'Output Power dbm': y_vs_x_list_0dbm[1]
        }

    df = pd.DataFrame(name_dict)
    wd = str(datetime.date.today()) + '/'
    os.system('mkdir -p ' + wd)
    df.to_csv(wd + sys.argv[1] + '_cal.csv')


    #######################################################################


    print("cn0511_freq=", cn0511_freq)
    print("cn0511_offset=", cn0511_offset)
    print("cn0511_gain=", cn0511_gain)
    # #-----------------------------------------------------
###############################################################################


###############################################################################
#################### MAIN function#############################################
if __name__ == "__main__":

    if len(sys.argv) != 2:
        sys.exit('example: python cn0511_prod_test.py 202205100001')

    hat_id_eep(sys.argv[1], 'cn0511_hat_id_eep.txt', '/boot/overlays/rpi-cn0511.dtbo')

    iio_ctx = iio.Context('local:')
    iio_ad9166 = iio_ctx.find_device('ad9166')
    iio_ad9166.attrs["sampling_frequency"].value = "6000000000"
    iio_ad9166.attrs["fir85_enable"].value = "1"
    iio_ad9166_ch = iio_ad9166.find_channel("altvoltage0", True)
    iio_ad9166_ch.attrs["nco_frequency"].value = "100000000"

    #connect to ladybug########################################################
    ladybug = usb.core.find(idVendor = 0x1a0d)
    if not ladybug: print ("No LadyBug")

    for config in ladybug:
        for i in range(config.bNumInterfaces):
            if ladybug.is_kernel_driver_active(i):
                ladybug.detach_kernel_driver(i)

    rm = visa.ResourceManager()

    print (rm.list_resources())
    my_resources = rm.list_resources()
    manufid_modelcode = '6669::5592'
    # using list comprehension to check and return the resource with specified
    # manufacturing id and model code
    my_resource = [i for i in my_resources if manufid_modelcode in i]

    inst = rm.open_resource(my_resource[0])
    print('my_inst: ', inst)
    inst.timeout = 120000

    print (inst.query("*IDN?"))
    ###########################################################################

    # These are the initial constants obtained: ###############################
    cn0511_freq = [100000000, 430000000, 510000000, 850000000, 1240000000, 2250000000, 2790000000, 3040000000, 3140000000, 3220000000, 3360000000, 3460000000, 3560000000, 3630000000, 3720000000, 3810000000, 3850000000, 3950000000, 4000000000, 4070000000, 4120000000, 4180000000, 4260000000, 4360000000, 4440000000, 4730000000, 4860000000, 5010000000, 5110000000, 5670000000, 5730000000, 5860000000]
    cn0511_offset = [260, 293, 321, 288, 291, 345, 407, 474, 443, 491, 516, 493, 534, 642, 557, 606, 598, 645, 614, 627, 614, 655, 647, 682, 645, 714, 688, 763, 749, 874, 917, 899]
    cn0511_gain = [1.2565445026178007e-07, 3.3544921875e-07, -1.0769329565887484e-07, 1.4522821576763486e-08, 5.306764986122042e-08, 1.0081510081510082e-07, 2.5736040609137073e-07, -3.1037234042553216e-07, 5.852272727272726e-07, 2.305418719211822e-07, -2.2881355932203387e-07, 3.6219512195121936e-07, 1.3952119309262202e-06, -9.388185654008449e-07, 5.782520325203256e-07, -2.974137931034482e-07, 4.2547169811320736e-07, -5.426751592356699e-07, 1.4285714285714287e-07, -1.454545454545454e-07, 9.879807692307702e-07, -1.220930232558139e-07, 5.582608695652176e-07, -4.986979166666671e-07, 2.2954699121027734e-07, -1.391025641025642e-07, 4.4178082191780847e-07, -1.272727272727272e-07, 2.0280612244898007e-07, 7.956521739130434e-07, -4.520917678812415e-08, 8.961038961038966e-07]


    ###########################################################################
    ###########################################################################


    # Output adjustment with ladybug for a specific board #####################
    offset_difference=calibrate_output_power_vs_frequency_offset_lb_adjustment(
         cn0511_offset[0], 100000000, cn0511_offset[0], 15, output_power_margin, 0)

    for i in range(0, len(cn0511_offset)):
        cn0511_offset[i] += offset_difference
    ###########################################################################

    # Plot the calibrated output from freq_step_plot to 5.9GHz with frequency
    # step = freq_step_plot ###################################################
    output_power_calibrated_anystep_lb(freq_step_plot)
    ###########################################################################


    #Write the obtained calibration constants to a text file ##################
    string_to_file = ("cn0511_freq=" + str(cn0511_freq) + "\n" + "cn0511_offset="
                 + str(cn0511_offset) + "\n" + "cn0511_gain=" +str(cn0511_gain) + "\n")

    print("\n" + "cn0511.txt file contains: ", string_to_file)

    wd = str(datetime.date.today()) + '/'
    os.system('mkdir -p ' + wd)
    my_file = open(wd + sys.argv[1] + '_cal.txt', 'w+')
    my_file.write(string_to_file)
    my_file.close()
    ###########################################################################

    # Write to EEPROM #########################################################
    # Delete EEprom memory:
    os.system('dd if=/dev/zero of=/sys/devices/platform/soc/fe804000.i2c/i2c-1/1-0051/eeprom bs=4096 count=1')
    ######################

    # Write EEPROM memory:
    os.system('cat ' + wd + sys.argv[1] + '_cal.txt > /sys/devices/platform/soc/fe804000.i2c/i2c-1/1-0051/eeprom')
    ######################

    # Compare if EEPROM content is equal with cn0511.txt content
    f1 = open("/sys/devices/platform/soc/fe804000.i2c/i2c-1/1-0051/eeprom", "r")
    f2 = open(wd + sys.argv[1] + '_cal.txt', "r")

    i = 0
    identical_files = True

    for line1 in f1:
        i += 1

        for line2 in f2:

            # matching line1 from both files
            if line1 == line2:
                identical_files = True
            else:
                identical_files = False
            break

    if identical_files == True:
        print("\n" + "EEPROM successfully written!")
    else:
        sys.exit("\n" + "EEPROM write fail!")

    print("Test completed successfully!")

    ###########################################################################

###############################################################################
###############################################################################
#------------------------------------------------------------------------------

