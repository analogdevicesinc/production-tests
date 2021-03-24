#!/usr/bin/python
# Copyright (C) 2019 Analog Devices, Inc.
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
import time

# Channel scale factors
adc_scale = 0.000149011 #Vref=2.5; adc_scale=[2.5/(2^24)]
ldoU2_temp_scale = 1.0 # Degrees C/mV
ldoU3_temp_scale = 1.0 # Degrees C/mV
iout_scale = 0.005 # A/mV
vin_scale =  14.33/1000 # V/mV; vin_scale = 1+(20.0/1.5)
vout_scale =  10.52/1000 # V/mV; vout_sca;e = 1+(20.0/2.1)
ilim_pos_scale =  100.0/(2.5*1000) # Percent
vpot_pos_scale =  100.0/(2.5*1000) # Percent
ldoin_scale =  14.33/1000 # V/mV; vin_scale = 1+(20.0/1.5)

def main(my_ip):
    try:
        import adi
        myadc = adi.ad7124(uri=my_ip)
        mydac = adi.ad5686(uri=my_ip) # REMEMBER TO VERIFY POWERDOWN/UP BEHAVIOR
    except:
      print("No device found")
      sys.exit(0)

    print("setting up DAC, setting output to 0.0V...")
    dac_scale = mydac.channel[0].scale # This is set by the device tree, it's not an actual measured value.
    print("DAC scale factor: " + str(dac_scale))
    setpoint = 0.0
    mydac.channel[0].raw = str(int(setpoint * 1000.0 / (11.0 *dac_scale)))

    print("Setting sample rates...")
    #Set maximum sampling frequency
    myadc.sample_rate = 9600

    print("Setting scales to 0.000149011 (unity gain)...")
    for i in range(0, 8):
      myadc.channel[i].scale = adc_scale

    print("Reading all voltages...\n\n")

    # Read initial conditions
    ldoU2_temp_init = (float(myadc.channel[0].raw) * adc_scale) * ldoU2_temp_scale
    ldoU3_temp_init = (float(myadc.channel[1].raw) * adc_scale) * ldoU3_temp_scale
    iout = (float(myadc.channel[2].raw) * adc_scale) * iout_scale
    vin = (float(myadc.channel[3].raw) * adc_scale) * vin_scale
    vout = (float(myadc.channel[4].raw) * adc_scale) * vout_scale
    ilim_pos = (float(myadc.channel[5].raw) * adc_scale) * ilim_pos_scale
    vpot_pos = (float(myadc.channel[6].raw) * adc_scale) * vpot_pos_scale
    vldoin = (float(myadc.channel[7].raw) * adc_scale) * ldoin_scale

    print("Initial Board conditions:")
    print("U2 Temperature: " + str(ldoU2_temp_init) + " C")
    print("U3 Temperature: " + str(ldoU3_temp_init) + " C")
    print("Output Current: " + str(iout) + " A")
    print("Input Voltage: " + str(vin) + " V")
    print("Output Voltage: " + str(vout) + " V")
    print("ILIM pot position: " + str(ilim_pos) + " %")
    print("Vout pot position: " + str(vpot_pos) + " %")
    print("LDO input voltage: " + str(vldoin) + " %")

    # Production test code
    input("\n\nStarting Production Test! Verify nothing connected to output jacks, press enter to continue...")
    failed_tests = []
    input("Set both potentiometers to 12:00 position, then press enter to continue...")

    # Verify that potentiometer knobs are within 40% to 60% scale. This is not necessarily
    # to test the pots, but to verify that they're in position for subsequent tests.
    ilim_pos = (float(myadc.channel[5].raw) * adc_scale) * ilim_pos_scale
    vpot_pos = (float(myadc.channel[6].raw) * adc_scale) * vpot_pos_scale
    print("Vout pot position: %.3f," % (vpot_pos))
    print("ILIM pot position: %.3f," % (ilim_pos))
    if (40 < vpot_pos < 60):# and (40 < ilim_pos < 60):
        print("Voltage Pot GOOD!\n")
    else:
        print("Voltage Pot position FAILS!")
        failed_tests.append("Fails Voltage Pot Test")
    if (40 < ilim_pos < 60):
        print("Current Pot GOOD!\n")
    else:
        print("Voltage Pot position FAILS!")
        failed_tests.append("Fails Current Pot Test")

    # Test zero output (verifies negative supply and current sink)
    setpoint = 0.0
    mydac.channel[0].raw = str(int(setpoint * 1000.0 / (11.0 *dac_scale)))
    time.sleep(0.1)
    vout = (float(myadc.channel[4].raw) * adc_scale) * vout_scale
    if (-0.01 < vout < 0.01):
        print("Zero output voltage: %.3f, test PASSES!" % (vout))
    else:
        print("Zero output voltage test FAILS!")
        failed_tests.append("Fails zero output test")

    # Test DAC gain
    setpoint = 10.0
    mydac.channel[0].raw = str(int(setpoint * 1000.0 / (11.0 *dac_scale)))
    time.sleep(0.1)
    vout = (float(myadc.channel[4].raw) * adc_scale) * vout_scale
    print("10V output voltage: %.3f" % (vout))
    if (9.9 < vout < 10.1):
        print("10V output voltage test PASSES!")
    else:
        print("10V output voltage test FAILS!")
        failed_tests.append("Fails 10V output test")

    # Test AND circuitry (verifies output voltage of the board is the lower between DAC and Vpot)
    setpoint = 18.0
    mydac.channel[0].raw = str(int(setpoint * 1000.0 / (11.0 *dac_scale)))
    time.sleep(0.1)
    vout = (float(myadc.channel[4].raw) * adc_scale) * vout_scale
    print("Testing analog AND. Output voltage: %.3f" % (vout))
    if (12.0 < vout < 15):
        print("Output between 12V and 15V, test PASSES!")
    else:
        print("AND circuit output voltage test FAILS!")
        failed_tests.append("Fails AND circuit output voltage test")
    # Test LDO preregulation
    vldoin = (float(myadc.channel[7].raw) * adc_scale) * ldoin_scale
    vdrop = vldoin - vout
    print("LDO input voltage: %.3f (%3f drop)" % (vldoin, vdrop))
    if(1.5 < vdrop < 2.0):
        print("LDO Preregulation PASSES!")
    else:
        print("LDO Preregulation FAILS")
        failed_tests.append("Fails LDO preregulation")

    print("\nConnect a 4-ohm, 50W power resistor between output terminals,")
    input("then press enter to continue...")
    time.sleep(1)
    iout = (float(myadc.channel[2].raw) * adc_scale) * iout_scale
    if (1.6 < iout < 2.1):
        print("midscale current limit: %.3f, test PASSES!\n" % (iout))
    else:
        print("midscale urrent limit test FAILS\n")
        failed_tests.append("Fails mid-current limit test")

    input("Set current limit potentiometer fully clockwise (5:00 position)")

    iout = (float(myadc.channel[2].raw) * adc_scale) * iout_scale
    if (2.6 < iout < 3.1):
        print("Current limit: %.3f, test PASSES!\n" % (iout))
    else:
        print("Current limit test FAILS\n")
        failed_tests.append("Fails current limit test")


    print("LDO Temp test...")
    time.sleep(7)
    ldoU2_temp = (float(myadc.channel[0].raw) * adc_scale) * ldoU2_temp_scale
    ldoU3_temp = (float(myadc.channel[1].raw) * adc_scale) * ldoU3_temp_scale
    tempdiff = abs(ldoU2_temp - ldoU3_temp)
    print("U2 Temperature: " + str(ldoU2_temp) + " C")
    print("U3 Temperature: " + str(ldoU3_temp) + " C")

    if((50 < ldoU2_temp < 80) and (50 < ldoU3_temp < 80) and tempdiff < 12.0):
        print("LDO temp test PASS!")
    else:
        print("LDO temp test FAILS")
        failed_tests.append("Fails LDO temp test")

    print("\nSetting DAC output to zero, just to be safe...\n\n")
    mydac.channel[0].raw = "0"
    time.sleep(1)

    del myadc
    del mydac
    del adi

    if len(failed_tests) == 0:
        print("Board PASSES!!")
    else:
        print("Board FAILED the following tests:")
        for failure in failed_tests:
            print(failure)
        print("Note failures and set aside for debug.")

if __name__ == '__main__':
    import os
    from time import sleep
    hardcoded_ip = 'ip:localhost'
    my_ip = sys.argv[1] if len(sys.argv) >= 2 else hardcoded_ip
    print("Connecting with CN0508 context at %s" % (my_ip))

    while(1):
        testdata = main(my_ip)
        x = input("Type \'s\' to shut down, \'a\' to test again, or \'q\'to quit:  ")
        if(x == 's'):
            if os.name == "posix":
                os.system("shutdown -h now")
            else:
                print("Sorry, can only shut down system when running locally on Raspberry Pi")
            break
        elif(x == 'q'):
            break
        else:
            sleep(0.5)
        # any other character tests again.