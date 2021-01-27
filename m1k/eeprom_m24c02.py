"""Module to control EEPROM M24C02."""

from time import sleep

import global_

global_.init()


def pack_memory_data(source):
    """Prepare data to be writed in memory."""
    data = []
    cnt = 0
    if len(bytearray(source)) > global_.PAGE_SIZE:
        print 'Too much data to write on EEPROM'
    else:
        while cnt < len(bytearray(source)):
            data.append(bytearray(source)[cnt])
            cnt += 1
    return data


def unpack_memory_data(source, start_adr, end_adr):
    """Prepare data read from memory."""
    result = ''
    cnt = start_adr
    while cnt < end_adr:
        result += chr(source[cnt])
        cnt += 1 if 0 < end_adr - start_adr <= global_.PAGE_SIZE else 0
    return result


def read_write(page, data='', nr_of_bytes=0, float_or_hex=''):
    """Read or write from memmory depending on arguments."""
    def_nr_of_bytes = nr_of_bytes
    data_out = 0
    if data != '':
        if nr_of_bytes > global_.PAGE_SIZE:
            nr_of_bytes = global_.PAGE_SIZE
            print 'nr_of_bytes was resized from ' + str(def_nr_of_bytes) + \
                ' to ' + str(nr_of_bytes)
        global_.bus.write_i2c_block_data(
            global_.EEPROM_ID, page, pack_memory_data(data))
        sleep(0.01)
    if nr_of_bytes > 0:
        data_out = unpack_memory_data(global_.bus.read_i2c_block_data(
            global_.EEPROM_ID, page, nr_of_bytes), 0, nr_of_bytes)
    try:
        if float_or_hex == 'float':
            return float(data_out)
        elif float_or_hex == 'hex':
            # return hex(int(data_out,16))
            return hex(int('0x' + data_out, 16))
        return 'Data writed: ' + str(data)
    except ValueError:
        return 'Conversion fail... Check EEPROM content'


def read_memory_content(brut_data_or_char_data=False):
    """Read memory content."""
    add = 0x00
    print
    while add <= global_.MEMORY_ARRAY_BYTES - global_.PAGE_SIZE:
        if brut_data_or_char_data:
            sleep(0.01)
            data_out = global_.bus.read_i2c_block_data(
                global_.EEPROM_ID, add, global_.PAGE_SIZE)
        else:
            sleep(0.01)
            read_data = global_.bus.read_i2c_block_data(
                global_.EEPROM_ID, add, global_.PAGE_SIZE)
            data_out = unpack_memory_data(read_data, 0, global_.PAGE_SIZE)
        print 'EEPROM content: ' + str(data_out)
        add += global_.PAGE_SIZE
    return 'Done reading EEPROM content'


def clear_memory_content():
    """Clear memory content."""
    add = 0x00
    print '\nEEPROM content after clean:'
    while add <= global_.MEMORY_ARRAY_BYTES - global_.PAGE_SIZE:
        global_.bus.write_i2c_block_data(
            global_.EEPROM_ID, add, [0xff] * global_.PAGE_SIZE)
        sleep(0.01)
        print global_.bus.read_i2c_block_data(
            global_.EEPROM_ID, add, global_.PAGE_SIZE)
        sleep(0.01)
        add += global_.PAGE_SIZE
    print
