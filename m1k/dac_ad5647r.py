"""Module to control DAC AD5647R."""

import global_

global_.init()


def init():
    """Initialize DAC internal reference for both channels."""
    global_.bus.write_i2c_block_data(global_.DAC_ID, 0xff, [0xff, 0xff])


def set_output(out):
    """Write to input register 'n' update all."""
    global_.bus.write_i2c_block_data(global_.DAC_ID, 0x17, out)
