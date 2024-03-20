import sys
sys.path.append('..')

from gmsl_lib import config_loader
from smbus2 import SMBus

I2C_BUS_NR = 1
IN_FILES = [
    'gmsl_scripts/MAX96724-MAX96717-V-QSH-rgb888-portAB.cpp',
    'gmsl_scripts/MAX96724_TPG.csv',
]

bus = SMBus(I2C_BUS_NR)

c = config_loader.GMSLConfig(bus, IN_FILES)
c.load()

bus.close()
print('Done configuring GMSL')
