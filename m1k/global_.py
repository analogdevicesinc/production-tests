"""Declare global variables."""
import os
import datetime

import serial

import smbus
from pysmu import Mode

EXPANDER_ID = 0x34
DAC_ID = 0x0E
ADC_ID = 0x2A
EEPROM_ID = 0x50
PAGE_SIZE = 16
MEMORY_ARRAY_BYTES = 256
CHX_V_I = [None] * 4
CHX_2V5_EX_REF = [None] * 4
SAMPLES = 0
SAMPLES_OFFSET = 0
SAMPLES_USED = 0
CHA = None
CHB = None

LOGDIR = os.getenv('LOGDIR', './log')
if not os.path.exists(LOGDIR):
    os.makedirs(LOGDIR)

TEXT_COLOR_MAP = {'green': '\033[1;32m', 'red': '\033[1;31m',
                  'purple': '\033[1;35m', 'orange': '\033[1;33m',
                  'turquoise': '\033[1;36m', 'default': '\033[m'}


def device_log_dir():
    global dev, LOGDIR
    tm1 = '_' + os.getenv('RUN_TIMESTAMP', 'unknown_time')
    device_dir = os.path.join(LOGDIR, dev.serial + tm1)
    if not os.path.exists(device_dir):
        os.makedirs(device_dir)
    return device_dir

def init(enable_serial=False):
    """Initialize variables used globaly."""
    global bus, ser, session, dev
    # Get I2C bus
    bus = smbus.SMBus(1)
    if enable_serial:
        ser = serial.Serial("/dev/ttyUSB0", baudrate=115200, timeout=0.5)
