import matplotlib.pyplot as plt
import numpy as np
import libm2k
from multiprocessing.pool import ThreadPool
import threading
import logging
import random

sample=random.randint(0,255)
def dig_reset(dig):
    """ Reset digital object
    
    Arguments:
        dig  -- Digital object\n
    """
    dig.setSampleRateIn(10000)
    dig.setSampleRateOut(10000)
    dig.setCyclic(True)
    dig.setDirection(0b1111111111111111)
    for i in range(16):
        dig.setOutputMode(i,1)
    dig.enableAllOut(True)
    return

def set_digital_trigger(dig):
    """Set the digital trigger
    
    Arguments:
        dig  -- Digital object\n
    """
    d_trig=dig.getTrigger()
    d_trig.setDigitalMode(0)
    d_trig.setDigitalStreamingFlag(True)
    for i in range(16):
        d_trig.setDigitalCondition(i,0)
    return d_trig

def ch_0_7_digital_output(dig):
    """Channels 0 to 7 are set as digital output and channels 8-to 16 are set as digital input.
    A data buffer is sent to 0-7 and received on 8-16. In ch1 are saved signals for each corresponding channel which will be plotter further
    
    Arguments:
        dig  -- Digital object\n
        buff  -- Data buffer to be sent\n
    """
    #enable 8 output channels
    for i in range(8):
        dig.setDirection(i,libm2k.DIO_OUTPUT)
        dig.enableChannel(i,True)
    #enable 8 input channels
    for i in range(8,16):
        dig.setDirection(i,libm2k.DIO_INPUT)
        dig.enableChannel(i, True)

    buff=[sample]*8
    dig.push(buff)
    ch1=[]
    data = dig.getSamples(100)
    dig.stopBufferOut()
    dig.stopAcquisition()
    val=data[0]
    logging.getLogger().info("\n*** 0-7 output ***")
    logging.getLogger().info(bin(val))
    vl=val&(2**8-1)
    vh=val>>8
    vlr=rotl(vl)
    logging.getLogger().info(bin(vh))
    logging.getLogger().info(bin(vl))
    logging.getLogger().info(bin(vlr))
    for i in range(8):

        if(vh&(1<<i))==(vlr&(1<<i)):
            ch1.append(1)
        else:
            ch1.append(0)
    return ch1

def ch_8_15_digital_output(dig):
    """Channels 8 to 16 are set as digital output and channels 0-to 7 are set as digital input.
    A data buffer is sent to 8-16 and received on 0-7. In ch1 are saved signals for each corresponding channel which will be plotter further
    
    Arguments:
        dig  -- Digital object\n
        buff  -- Data buffer to be sent\n
    """
    #enable 8 output channels
    for i in range(8,16):
        dig.setDirection(i,libm2k.DIO_OUTPUT)
        dig.enableChannel(i,True)
    #enable 8 input channels
    for i in range(8):
        dig.setDirection(i,libm2k.DIO_INPUT)
        dig.enableChannel(i, True)
    buff=[sample<<8]*8
    dig.push(buff)
    ch2=[]
    data = dig.getSamples(100)
    dig.stopBufferOut()
    dig.stopAcquisition()
    val=data[0]
    logging.getLogger().info("\n*** 8-15 output ***")
    logging.getLogger().info(bin(val))
    vl=val&(2**8-1)
    vh=val>>8
    vlr=rotl(vl)
    logging.getLogger().info(bin(vh))
    logging.getLogger().info(bin(vl))
    logging.getLogger().info(bin(vlr))
    for i in range(8):
            #get the signal from the digital channel i

            if(vh&(1<<i))==(vlr&(1<<i)):
                ch2.append(1)
            else:
                ch2.append(0)
    return ch2

def rotl(num):
    new=0
    for i in range(8):
        bit = num & (1 << i)
    
        if(bit):
            new |= 1
        new <<= 1    
    new>>=1

    return new



