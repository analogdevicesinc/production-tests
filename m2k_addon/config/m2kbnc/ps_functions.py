import libm2k
import numpy as np
import time
from open_context_and_files import ain, ctx
import random
import logging

def config_for_ps_test(ps,ain):
    """Retrieve the Power supply object and enabe the power supply channels
    Arguments:
        ps-- Power Supply object
        ain  -- AnalogIn object\n
    """
    #ctx.calibrate()
    #enable channels
    ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_1, True)
    ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_1, 0)
    ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_2,True)
    ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_2, 0)
    if ain.isChannelEnabled(libm2k.ANALOG_IN_CHANNEL_1)==False:
        ain.enableChannel(libm2k.ANALOG_IN_CHANNEL_1, True)
    if ain.isChannelEnabled(libm2k.ANALOG_IN_CHANNEL_2)==False:
        ain.enableChannel(libm2k.ANALOG_IN_CHANNEL_2, True)
    return

def ps_test_positive(ps,ain, file):
    """Tests the positive power supply
    Arguments:
        ps -- Power Supply object
        ain -- AnalogIn object
    Returns:
        pos_supply-- Vector that  holds 1 if the  voltage value read on the channel equals the voltage sent
    """
    file.write("\n\nPositive power supply test:\n")
    voltage=0
    t=0.1 #threshold value 
    pos_supply=[]
    ain.setRange(libm2k.ANALOG_IN_CHANNEL_1,libm2k.PLUS_MINUS_25V)
    while voltage<=5:
        ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_1, voltage)
        time.sleep(0.2)
        read_voltage=(ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_1])
        file.write("Sent voltage: "+str(voltage)+"\n")
        file.write("Read voltage: "+str(read_voltage)+"\n")
        if(read_voltage>=(voltage-(t*voltage)) and read_voltage<=(voltage+(t*voltage))):
            pos_supply=np.append(pos_supply,1)
        else:
            pos_supply=np.append(pos_supply,0)
        voltage=voltage+random.uniform(0.4,0.5) #add a random value to the previous voltage value
    logging.getLogger().info(pos_supply)
    return pos_supply


def ps_test_negative(ps,ain, file):
    """Tests the negativepower supply
    Arguments:
        ps -- Power Supply object
        ain -- AnalogIn object
    Returns:
        neg_supply-- Vector that  holds 1 if the  voltage value read on the channel equals the voltage sent
    """
    file.write("\n\nNegative power supply test:\n")
    voltage=0
    neg_supply=[]
    t=0.2 #threshold value (read voltage should be in the +_10% range)
    ain.setRange(libm2k.ANALOG_IN_CHANNEL_2,libm2k.PLUS_MINUS_25V)
    while voltage>=-5:
        ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_2, voltage)
        time.sleep(0.2)
        read_voltage=(ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_2])
        file.write("Sent voltage: "+str(voltage)+"\n")
        file.write("Read voltage: "+str(read_voltage)+"\n")
        if(read_voltage<=(voltage+(t*voltage)) and read_voltage>=(voltage-(t*voltage))):
            neg_supply=np.append(neg_supply,1)
        else:
            neg_supply=np.append(neg_supply,0)
        voltage=voltage-random.uniform(0.4, 0.5) #subtract a random value from the previous voltage value
    
    
    logging.getLogger().info(neg_supply)
    return neg_supply

def  switch_to_pot_control(ps):
    
    ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_1,False)
    ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_2,False)
    logging.getLogger().info("\n\n*** Switch jumper P6 from M2k+ position to POT+ position ***")
    logging.getLogger().info("\n\n*** Switch jumper P7 from M2k- position to POT- position ***")
    logging.getLogger().info("\n After switching the jumpers, press ENTER to continue the test\n")
    input()
    return
def ps_test_positive_with_potentiometer(ps, ain, file):
    file.write("\n\nPositive power supply - potentiometer test:\n")
    pot_pos_supply=[]
    voltage=0
    logging.getLogger().info("\n\n*** For this test will use POT+ ***")
    logging.getLogger().info("Make sure the arrow is pointing to 1.5V and press enter")
    input()
    
    voltage=ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_1]
    file.write("Read voltage: "+str(voltage)+"\n")
    if (voltage>1) and (voltage <2):
        pot_pos_supply=np.append(pot_pos_supply,1)
    else:
        pot_pos_supply=np.append(pot_pos_supply,0)
 
    logging.getLogger().info("\nMake sure the arrow is pointing to 15V and press enter")
    input()
    voltage=ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_1]
    file.write("Read voltage: "+str(voltage)+"\n")
    if (voltage>4) and (voltage <5):
        pot_pos_supply=np.append(pot_pos_supply,1)
    else:
        pot_pos_supply=np.append(pot_pos_supply,0)
    
    logging.getLogger().info(pot_pos_supply)
    return pot_pos_supply


def ps_test_negative_with_potentiometer(ps, ain, file):
    file.write("\n\nNegative power supply - potentiometer test:\n")
    pot_neg_supply=[]
    voltage=0
    logging.getLogger().info("\n\n *** For this test will use POT- ***")
    logging.getLogger().info("Make sure the arrow is pointing to -1.5V and press enter")
    input()
    
    voltage=ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_2]
    file.write("Read voltage: "+str(voltage)+"\n")
    if (voltage<-1) and (voltage>-2):
        pot_neg_supply=np.append(pot_neg_supply,1)
    else:
        pot_neg_supply=np.append(pot_neg_supply,0)
  

    logging.getLogger().info("\nMake sure the arrow is pointing to -15V and press enter")
    input()
    voltage=ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_2]
    file.write("Read voltage: "+str(voltage)+"\n")
    if (voltage<-4) and (voltage>-5):
        pot_neg_supply=np.append(pot_neg_supply,1)
    else:
        pot_neg_supply=np.append(pot_neg_supply,0)
    
    logging.getLogger().info(pot_neg_supply)
    return pot_neg_supply
   


def test_external_connector():
    logging.getLogger().info("\n\nConnect a voltage source 4.5-18V to the 2 terminal screw connector")
    logging.getLogger().info("If LED DS3 is ON,  press 1 ")
    logging.getLogger().info("Press Enter to continue")
    ext_pwr=input()
    return ext_pwr

    
def test_usbTypeC_connector():
    logging.getLogger().info("\n\n***! Disconnect the external power !***")
    logging.getLogger().info("Plug in the USB-TypeC ")
    logging.getLogger().info("If LED DS3 is ON, press 1 ")
    logging.getLogger().info("Press Enter to continue")
    usb_pwr=input()
    return usb_pwr