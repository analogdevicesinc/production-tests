import libm2k
import numpy as np
import time
from open_context_and_files import ain, ctx
import random
import logging
import RPi.GPIO as GPIO


GPIO.setmode(GPIO.BCM)

R1=12# pin32
R2=24# pin18
R3=4 # pin 7
R4=2 # pin 3
GPIO.setwarnings(False)
GPIO.setup(R1,GPIO.OUT)
GPIO.setup(R2,GPIO.OUT)
GPIO.setup(R3,GPIO.OUT)
GPIO.setup(R4,GPIO.OUT)


def config_for_ps_test(ps,ain):
    """Retrieve the Power supply object and enabe the power supply channels
    Arguments:
        ps-- Power Supply object
        ain  -- AnalogIn object\n
    """
    #ctx.calibrate()
    #enable channels
    ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_1, True)
    ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_2,True)

    if ain.isChannelEnabled(libm2k.ANALOG_IN_CHANNEL_1) == False:
        ain.enableChannel(libm2k.ANALOG_IN_CHANNEL_1, True)
    if ain.isChannelEnabled(libm2k.ANALOG_IN_CHANNEL_2) == False:
        ain.enableChannel(libm2k.ANALOG_IN_CHANNEL_2, True)
        
    ain.setRange(libm2k.ANALOG_IN_CHANNEL_1,libm2k.PLUS_MINUS_25V)
    ain.setRange(libm2k.ANALOG_IN_CHANNEL_2,libm2k.PLUS_MINUS_25V)
    GPIO.output(R1,True)
    return

def ps_test_positive(ps, ain):
    """Tests the positive power supply
    Arguments:
        ps -- Power Supply object
        ain -- AnalogIn object
    Returns:
        pos_supply-- Vector that  holds 1 if the  voltage value read on the channel equals the voltage sent
    """
    voltage=1

    t=0.1 #threshold value 
    pos_supply=[]
    
   
    while voltage <= 5:
        if voltage <= 3:
            GPIO.output(R2,True)
            GPIO.output(R3,True)
            GPIO.output(R4,True)
        else:
            GPIO.output(R2,True)
            GPIO.output(R3,True)
            GPIO.output(R4,False)

        ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_1, voltage)
        
        time.sleep(1)
        read_voltage=(ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_1])
        logging.getLogger().info("Sent: " + str(voltage) + "V read: " + 
                        str(read_voltage) + "V")

        if(read_voltage>=(voltage-t) and read_voltage<=(voltage+t)):
            pos_supply=np.append(pos_supply,1)
        else:
            pos_supply=np.append(pos_supply,0)
        voltage = voltage + 1
    logging.getLogger().info(pos_supply)

    GPIO.output(R2, False)
    GPIO.output(R3, False)
    GPIO.output(R4, False)
    ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_1, 0)
    ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_1, False)
    return pos_supply


def ps_test_negative(ps, ain):
    """Tests the negativepower supply
    Arguments:
        ps -- Power Supply object
        ain -- AnalogIn object
    Returns:
        neg_supply-- Vector that  holds 1 if the  voltage value read on the channel equals the voltage sent
    """
    voltage=-1
    neg_supply=[]
    t=0.1 #threshold value 

    while voltage>=-5:
        if voltage>=-3:
            GPIO.output(R2,True)
            GPIO.output(R3,True)
            GPIO.output(R4,True)
        else:
            GPIO.output(R2,True)
            GPIO.output(R3,True)
            GPIO.output(R4,False)
        
        ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_2, voltage)
        time.sleep(1)

        read_voltage=(ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_2])
        logging.getLogger().info("Sent: " + str(voltage) + "V read: " + 
                        str(read_voltage) + "V")
 
        if(read_voltage<=(voltage+t) and read_voltage>=(voltage-t)):
            neg_supply=np.append(neg_supply,1)
        else:
            neg_supply=np.append(neg_supply,0)
        voltage=voltage-1 #subtract a random value from the previous voltage value
    
    
    logging.getLogger().info(neg_supply)
    
    GPIO.output(R1,False)
    GPIO.output(R2,False)
    GPIO.output(R3,False)
    GPIO.output(R3,False)
    
    ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_2, 0)
    ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_2, False)
    return neg_supply

def switch_to_pot_control(ps):
    ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_1, False)
    ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_2, False)
    logging.getLogger().info("*** Switch jumper P6 from M2K+ position to POT+ (R20) position")
    logging.getLogger().info("*** Switch jumper P7 from M2K- position to POT- (R19) position")
    
    
    return

def ps_test_potentiometer_lower_limit(ps, ain):
    switch_to_pot_control(ps)
    GPIO.output(R1,True)
    GPIO.output(R2,True)
    GPIO.output(R3,True)
    GPIO.output(R4,True)

    pot_lower_limit=[]
    voltage=0

    logging.getLogger().info("*** Make sure the arrow of POT+ (R20) is pointing to 1.5V")

    logging.getLogger().info("*** Make sure the arrow of POT- (R19) is pointing to -1.5V")
    logging.getLogger().info("*** Press enter to continue the test")
    input()
 
    voltage=ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_1]      
    logging.getLogger().info("Read: " + str(voltage) + "V")
    if (voltage>1) and (voltage <2):
        pot_lower_limit=np.append(pot_lower_limit,1)
    else:
        pot_lower_limit=np.append(pot_lower_limit,0)
        
 

    voltage=ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_2]
    logging.getLogger().info("Read: " + str(voltage) + "V")
    if (voltage<-1) and (voltage>-2):
        pot_lower_limit=np.append(pot_lower_limit,1)
    else:
        pot_lower_limit=np.append(pot_lower_limit,0)
    

    GPIO.output(R3,False)
    GPIO.output(R4,False)
    
    logging.getLogger().info(pot_lower_limit)
    return pot_lower_limit


def ps_test_potentiometer_upper_limit(ps, ain):
  

    pot_upper_limit=[]
    voltage=0
   

    logging.getLogger().info("*** Make sure the arrow of POT+ (R20) points to 15V")
    logging.getLogger().info("*** Make sure the arrow of POT- (R19) points to -15V")
    logging.getLogger().info("*** Press enter to continue the test")
    input()
  
    voltage=ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_1]
    logging.getLogger().info("Read: " + str(voltage) + "V")
    if (voltage>13) and (voltage <15):
        pot_upper_limit=np.append(pot_upper_limit,1)
    else:
        pot_upper_limit=np.append(pot_upper_limit,0)

   
    voltage=ain.getVoltage()[libm2k.ANALOG_IN_CHANNEL_2]
    logging.getLogger().info("Read: " + str(voltage) + "V")

    if (voltage<-13) and (voltage>-15):
        pot_upper_limit=np.append(pot_upper_limit,1)
    else:
        pot_upper_limit=np.append(pot_upper_limit,0)
  
    GPIO.output(R1,False)
    GPIO.output(R2,False)
    GPIO.output(R3,False)
    GPIO.output(R4,False)
    logging.getLogger().info(pot_upper_limit)
    
    
    
    return pot_upper_limit
   



    
def test_usbTypeC_connector():
    logging.getLogger().info("*** Plug in the USB-TypeC")
    logging.getLogger().info("*** Is LED DS3 ON? [Y/n]")
    usb_pwr = input()
    if usb_pwr in ["no", "n"]:
	    return False
    else:
	    return True
