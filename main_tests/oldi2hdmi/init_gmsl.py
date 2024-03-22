import sys
sys.path.append('..')

from gmsl_lib import config_loader
from smbus2 import SMBus

I2C_BUS_NR = 1
IN_FILES = [
    'gmsl_scripts/MAX96752_90.cpp',
    'gmsl_scripts/MAX96717_STREAM0_80.cpp',
    'gmsl_scripts/MAX96717_720P_TPG_80.csv',
]

bus = SMBus(I2C_BUS_NR)

c = config_loader.GMSLConfig(bus, IN_FILES)
c.load()

bus.close()
print('Done configuring GMSL')
