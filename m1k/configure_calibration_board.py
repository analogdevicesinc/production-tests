"""Module used to calbrate the M1K test board."""
import signal
import sys
import types

import adc_ad7091r5
import dac_ad5647r
import eeprom_m24c02
import global_
import ioxp_adp5589
from gpiozero import LED
from numpy import mean
from pysmu import Mode, Session

TEXT = global_.TEXT_COLOR_MAP
usb = LED(12)
usb.on()

COMMANDS = ['a', 'b', 'c', 'd', 'e', 'f', 'g',
            'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o']


def load_lists():
    """Define commands and settings."""
    commands = ['a', 'b', 'c', 'd', 'e', 'f', 'g',
                'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o']
    functions = [
        [0.0, Mode.HI_Z], [0.1, Mode.SIMV], [-0.1, Mode.SIMV],
        [0.0, Mode.HI_Z], [0.0, Mode.HI_Z],
        [0.0, Mode.HI_Z], [0.0, Mode.HI_Z],
        [4.0, Mode.SVMI], [0.0, Mode.HI_Z],
        [3.75, Mode.SVMI], [1.25, Mode.SVMI],
        [0.0, Mode.HI_Z], [0.1, Mode.SIMV],
        [0.0, Mode.HI_Z], [-0.1, Mode.SIMV]]
    return commands, functions


def write_in_eeprom(flag, memmory_address, memmory_data):
    """Write data in EEPROM."""
    while True:
        key_2 = wait_key('\r\tWrite in EEPROM? <y/n>: ', 1)
        if key_2 == 'y':
            eeprom_m24c02.read_write(memmory_address, memmory_data)
            break
        if key_2 == 'n':
            break
        flag = True
    return flag


def move_to_next_step(flag, value):
    """Return confirmed value."""
    while True:
        key_2 = wait_key('\rConfirm value? <y/n>: \t', 1)
        if key_2 == 'y':
            value = key_2
            break
        if key_2 == 'n':
            break
        flag = True
    return [flag, value]


def display_eeprom_content():
    """Check EEPROM content."""
    while True:
        key_2 = wait_key('\rDisplay EEPROM content? <y/n>: \t', 1)
        if key_2 == 'y':
            eeprom_m24c02.read_memory_content()
            print
            break
        if key_2 == 'n':
            break


def menu():
    """Display menu.

    a -> Measure external 2V5 and 1V2.
    b -> Measure voltage and current to calculate source resistance.
    c -> Measure voltage and current to calculate sink resistance.
    d -> Set DAC command for 1V25.
    e -> Set DAC command for 3V75.
    f -> Calibrate ADC VIN1 (5V0). Measure offset, calculate scale and gain.
    g -> Calibrate ADC VIN2 (CHX). Measure offset.
    h -> Calibrate ADC VIN2 (CHX). Calculate scale and gain.
    i -> Calibrate ADC VIN3 (2V5). Measure offset, calculate scale and gain.
    j -> Calculate voltage drop between channels when source 3V75.
    k -> Calculate voltage drop between channels when source 1V25.
    l -> Calibrate ADC offset to measure positive current.
    m -> Calibrate ADC gain to measure positive current.
    n -> Calibrate ADC offset to measure negative current
    o -> Calibrate ADC gain to measure negative current
    """
    print TEXT['turquoise'], menu.__doc__, TEXT['default']


def check_adc(channel, ex_1v2_ref, adc_offset, adc_scale, adc_gain):
    """Check ADC calibration for selected channel."""
    done = False
    while not done:
        adc_params = [ex_1v2_ref, adc_offset, adc_scale, adc_gain]
        adc = adc_ad7091r5.voltage_input(channel, adc_params, 1000)
        key = wait_key('\t ADC: {:<20}              \r'.format(adc), 1)
        if key == '':
            done = True
            break
    return adc


def check_adc_csa(offset_i, adc_i_ref, i_ref):
    """Check ADC calibration for selected channel."""
    done = False
    while not done:
        adc = adc_ad7091r5.current_value(offset_i, adc_i_ref, i_ref, 1000)
        key = wait_key('\t ADC: {:<20}              \r'.format(adc), 1)
        if key == '':
            done = True
            break


def predetermine_resistance(polarity):
    """Calculate resistance besed on ADC measurements after calibration."""
    ex_1v2_ref = eeprom_m24c02.read_write(0x08, '', 8, 'float')

    adc_offset_vin3 = int(eeprom_m24c02.read_write(0x50, '', 2, 'float'))
    adc_scale_vin3 = eeprom_m24c02.read_write(0x53, '', 6, 'float')
    adc_gain_vin3 = eeprom_m24c02.read_write(0x5A, '', 6, 'float')
    adc_params_3 = [ex_1v2_ref, adc_offset_vin3, adc_scale_vin3, adc_gain_vin3]

    adc_offset_vin2 = int(eeprom_m24c02.read_write(0x40, '', 2, 'float'))
    adc_scale_vin2 = eeprom_m24c02.read_write(0x43, '', 6, 'float')
    adc_gain_vin2 = eeprom_m24c02.read_write(0x4A, '', 6, 'float')
    adc_params_2 = [ex_1v2_ref, adc_offset_vin2, adc_scale_vin2, adc_gain_vin2]

    adc_offset_poz = int(eeprom_m24c02.read_write(0x70, '', 3, 'hex'), 16)
    adc_gain_poz = int(eeprom_m24c02.read_write(0x75, '', 3, 'hex'), 16)
    i_gain_poz = eeprom_m24c02.read_write(0x7A, '', 6, 'float')

    adc_offset_neg = int(eeprom_m24c02.read_write(0x80, '', 3, 'hex'), 16)
    adc_gain_neg = int(eeprom_m24c02.read_write(0x85, '', 3, 'hex'), 16)
    i_gain_neg = eeprom_m24c02.read_write(0x89, '', 7, 'float')

    comp_poz = eeprom_m24c02.read_write(0x61, '', 6, 'float')
    comp_neg = eeprom_m24c02.read_write(0x68, '', 7, 'float')

    if polarity == 'poz':
        ref_2v5_srs = adc_ad7091r5.voltage_input(3, adc_params_3, 1000)[0]
        chx_voltage_srs = adc_ad7091r5.voltage_input(2, adc_params_2, 1000)[0]
        current_chx_poz = adc_ad7091r5.current_value(
            adc_offset_poz, adc_gain_poz, i_gain_poz, 1000)[0]
        voltage = chx_voltage_srs + comp_poz - ref_2v5_srs
        resistance_srs = voltage / current_chx_poz
        print(resistance_srs)

    if polarity == 'neg':
        ref_2v5_snc = adc_ad7091r5.voltage_input(3, adc_params_3, 1000)[0]
        chx_voltage_snc = adc_ad7091r5.voltage_input(2, adc_params_2, 1000)[0]
        current_chx_neg = adc_ad7091r5.current_value(
            adc_offset_neg, adc_gain_neg, i_gain_neg, 1000)[0]
        voltage = chx_voltage_snc + comp_neg - ref_2v5_snc
        resistance_snc = voltage / current_chx_neg
        print(resistance_snc)


def request_factor(text, memory_location, spaceholder, spaces):
    """Request ADC factor for calibration."""
    next_step = False
    while not next_step:
        factor = wait_key(TEXT['orange'] + '\r\t' + text + TEXT['default'], 1)
        if isinstance(factor, types.StringType):
            print '\tValue is: ' + spaceholder.format(factor)[:spaces]
            next_step = write_in_eeprom(
                next_step, memory_location,
                spaceholder.format(factor)[:spaces])


def measure_external_2v5_1v2(functions, commands):
    """Measure external 2V5 and 1V2."""
    print TEXT['green'], measure_external_2v5_1v2.__doc__, TEXT['default']
    settings = functions[0]
    settings.append(commands[0])
    return settings


def __measure_external_2v5_1v2():
    """Measure external references.

    SETUP: Connect M1K on the calibration board.
    Measure 2.5 V reference value on R38 on the M1K.
    Measure 1.2 V reference value on calibration
    board referenced on the ADC GND.
    """
    print TEXT['green'], __measure_external_2v5_1v2.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'GPIO_0__1', 'EN_1V2__1'])
    request_factor(
        'Enter 2.5 V reference value (e.g: 2.4990): ', 0x00, '{:<6}', 6)
    display_eeprom_content()
    request_factor(
        'Enter 1.2 V reference value (e.g: 1.2009): ', 0x08, '{:<6}', 6)
    display_eeprom_content()


def calculate_resistance_source(functions, commands):
    """Measure voltage and current to calculate source resistance."""
    print TEXT['green'], calculate_resistance_source.__doc__, TEXT['default']
    settings = functions[1]
    settings.append(commands[1])
    return settings


def __calculate_resistance_source():
    """Calculate resistance when source.

    SETUP: Measure voltage across channel A and M1K 2V5 reference.
    Measure current between M1K and calibration board channel A pins.
    """
    print TEXT['green'], __calculate_resistance_source.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'GPIO_1__1', 'EN_1V2__1'])
    predetermine_resistance('poz')
    request_factor(
        'Enter source resistance value (e.g: 13.2280): ', 0x10, '{:<7}', 7)
    display_eeprom_content()


def calculate_resistance_sink(functions, commands):
    """Measure voltage and current to calculate sink resistance."""
    print TEXT['green'], calculate_resistance_sink.__doc__, TEXT['default']
    settings = functions[2]
    settings.append(commands[2])
    return settings


def __calculate_resistance_sink():
    """Calculate resistance when sink.

    SETUP: Measure voltage across channel A and M1K 2V5 reference.
    Measure current between M1K and calibration board channel A pins.
    """
    print TEXT['green'], __calculate_resistance_sink.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'GPIO_1__1', 'EN_1V2__1'])
    predetermine_resistance('neg')
    request_factor(
        'Enter sink resistance value (e.g: 13.3485): ', 0x19, '{:<7}', 7)
    display_eeprom_content()


def set_dac_for_1v25(functions, commands):
    """Set DAC command for 1V25."""
    print TEXT['green'], set_dac_for_1v25.__doc__, TEXT['default']
    settings = functions[3]
    settings.append(commands[3])
    return settings


def __set_dac_for_1v25():
    """DAC setup.

    SETUP: Connect M1K on the calibration board.
    Measure voltage value on R38 on the M1K.
    """
    print TEXT['green'], __set_dac_for_1v25.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'GPIO_2__1', 'EN_1V2__1'])
    request_factor('Enter DAC command value (e.g: 30A4): ', 0x20, '{:<4}', 4)
    msb_dac_srs_1v25 = int(eeprom_m24c02.read_write(0x20, '', 2, 'hex'), 16)
    lsb_dac_srs_1v25 = int(eeprom_m24c02.read_write(0x22, '', 2, 'hex'), 16)
    display_eeprom_content()
    dac_srs_1v25_cmd = [msb_dac_srs_1v25, lsb_dac_srs_1v25]
    dac_ad5647r.set_output(dac_srs_1v25_cmd)


def set_dac_for_3v75(functions, commands):
    """Set DAC command for 3V75."""
    print TEXT['green'], set_dac_for_3v75.__doc__, TEXT['default']
    settings = functions[4]
    settings.append(commands[4])
    return settings


def __set_dac_for_3v75():
    """DAC setup.

    SETUP: Connect M1K on the calibration board.
    Measure voltage value on R38 on the M1K.
    """
    print TEXT['green'], __set_dac_for_3v75.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'GPIO_2__1', 'EN_1V2__1'])
    request_factor('Enter DAC command value (e.g: 9278): ', 0x25, '{:<4}', 4)
    msb_dac_srs_3v75 = int(eeprom_m24c02.read_write(0x25, '', 2, 'hex'), 16)
    lsb_dac_srs_3v75 = int(eeprom_m24c02.read_write(0x27, '', 2, 'hex'), 16)
    display_eeprom_content()
    dac_srs_3v75_cmd = [msb_dac_srs_3v75, lsb_dac_srs_3v75]
    dac_ad5647r.set_output(dac_srs_3v75_cmd)


def calibrate_adc_vin1_5v0(functions, commands):
    """Calibrate ADC VIN1 (5V0). Measure offset, calculate scale and gain."""
    print TEXT['green'], calibrate_adc_vin1_5v0.__doc__, TEXT['default']
    settings = functions[5]
    settings.append(commands[5])
    return settings


def __calibrate_adc_vin1_5v0():
    """Calibrate ADC VIN1.

    SETUP: Connect M1K GND on the calibration board GND.
    For offset measurement connect calibration board 5V0 pin on GND.

    For scale determination connect calibration board 5V0 pin on CHA pin.
    On the M1K connector measure voltage value between 5V0 pin and GND.
    Measure voltage on R20 on the calibration board.
    Determine the report between these two voltages.

    For gain determination observe current voltage value measured by ADC.
    On the M1K connector measure voltage value between 5V0 pin and GND.
    Determine the report between these two voltages.
    """
    print TEXT['green'], __calibrate_adc_vin1_5v0.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['EN_1V2__1'])
    ex_1v2_ref = eeprom_m24c02.read_write(0x08, '', 8, 'float')
    check_adc(1, ex_1v2_ref, 1, 1, 1)
    request_factor('Enter offset value (e.g: 4): ', 0x30, '{:<2}', 2)
    adc_offset_vin1 = int(eeprom_m24c02.read_write(0x30, '', 2, 'float'))
    check_adc(1, ex_1v2_ref, adc_offset_vin1, 1, 1)
    display_eeprom_content()

    request_factor('Enter scale value (e.g: 4.2347): ', 0x33, '{:<6}', 6)
    adc_scale_vin1 = eeprom_m24c02.read_write(0x33, '', 6, 'float')
    check_adc(1, ex_1v2_ref, adc_offset_vin1, adc_scale_vin1, 1)
    display_eeprom_content()

    request_factor('Enter gain value (e.g: 1.0001): ', 0x3A, '{:<6}', 6)
    adc_gain_vin1 = eeprom_m24c02.read_write(0x3A, '', 6, 'float')
    check_adc(1, ex_1v2_ref, adc_offset_vin1, adc_scale_vin1, adc_gain_vin1)
    display_eeprom_content()


def calibrate_adc_vin2_offset(functions, commands):
    """Calibrate ADC VIN2 (CHX). Measure offset."""
    print TEXT['green'], calibrate_adc_vin2_offset.__doc__, TEXT['default']
    settings = functions[6]
    settings.append(commands[6])
    return settings


def __calibrate_adc_vin2_offset():
    """Calibrate ADC VIN2.

    SETUP: Connect M1K GND on the calibration board GND.
    For offset measurement connect calibration board CHA pin on GND.
    """
    print TEXT['green'], __calibrate_adc_vin2_offset.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'EN_1V2__1'])
    ex_1v2_ref = eeprom_m24c02.read_write(0x08, '', 8, 'float')
    check_adc(2, ex_1v2_ref, 1, 1, 1)
    request_factor('Enter offset value (e.g: 9): ', 0x40, '{:<2}', 2)
    adc_offset_vin2 = int(eeprom_m24c02.read_write(0x40, '', 2, 'float'))
    check_adc(2, ex_1v2_ref, adc_offset_vin2, 1, 1)
    display_eeprom_content()


def calibrate_adc_vin2_scale_gain(functions, commands):
    """Calibrate ADC VIN2 (CHX). Calculate scale and gain."""
    print TEXT['green'], calibrate_adc_vin2_scale_gain.__doc__, TEXT['default']
    settings = functions[7]
    settings.append(commands[7])
    return settings


def __calibrate_adc_vin2_scale_gain():
    """SETUP: Connect M1K GND on the calibration board GND.

    For scale determination connect M1K board on the calibration board.
    Measure voltage value on R38 on the M1K.
    Measure voltage on R17 on the calibration board.
    Determine the report between these two voltages.

    For gain determination observe current voltage value measured by ADC.
    Measure voltage value on R38 on the M1K.
    Determine the report between these two voltages.
    """
    print TEXT['green'], \
        __calibrate_adc_vin2_scale_gain.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'EN_1V2__1'])
    ex_1v2_ref = eeprom_m24c02.read_write(0x08, '', 8, 'float')
    adc_offset_vin2 = int(eeprom_m24c02.read_write(0x40, '', 2, 'float'))
    check_adc(2, ex_1v2_ref, adc_offset_vin2, 1, 1)
    request_factor('Enter scale value (e.g: 4.2340): ', 0x43, '{:<6}', 6)
    adc_scale_vin2 = eeprom_m24c02.read_write(0x43, '', 6, 'float')
    check_adc(2, ex_1v2_ref, adc_offset_vin2, adc_scale_vin2, 1)
    display_eeprom_content()

    request_factor('Enter gain value (e.g: 1.0015): ', 0x4A, '{:<6}', 6)
    adc_gain_vin2 = eeprom_m24c02.read_write(0x4A, '', 6, 'float')
    check_adc(2, ex_1v2_ref, adc_offset_vin2, adc_scale_vin2, adc_gain_vin2)
    display_eeprom_content()


def calibrate_adc_vin3_2v5(functions, commands):
    """Calibrate ADC VIN3 (2V5). Measure offset, calculate scale and gain."""
    print TEXT['green'], calibrate_adc_vin3_2v5.__doc__, TEXT['default']
    settings = functions[8]
    settings.append(commands[8])
    return settings


def __calibrate_adc_vin3_2v5():
    """Calibrate ADC VIN3.

    SETUP: Connect M1K GND on the calibration board GND.
    For offset measurement connect calibration board 2v5 pin on GND.

    For scale determination connect calibration board 2v5 pin on CHA pin.
    On the M1K connector measure voltage value between 2V5 pin and GND.
    Measure voltage on R21 on the calibration board.
    Determine the report between these two voltages.

    For gain determination observe current voltage value measured by ADC.
    On the M1K connector measure voltage value between 2V5 pin and GND.
    Determine the report between these two voltages.
    """
    print TEXT['green'], __calibrate_adc_vin3_2v5.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['EN_1V2__1'])
    ex_1v2_ref = eeprom_m24c02.read_write(0x08, '', 8, 'float')
    check_adc(3, ex_1v2_ref, 1, 1, 1)
    request_factor('Enter offset value (e.g: 3): ', 0x50, '{:<2}', 2)
    adc_offset_vin3 = int(eeprom_m24c02.read_write(0x50, '', 2, 'float'))
    check_adc(3, ex_1v2_ref, adc_offset_vin3, 1, 1)
    display_eeprom_content()

    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'GPIO_0__1', 'EN_1V2__1'])
    request_factor('Enter scale value (e.g: 4.2411): ', 0x53, '{:<6}', 6)
    adc_scale_vin3 = eeprom_m24c02.read_write(0x53, '', 6, 'float')
    check_adc(3, ex_1v2_ref, adc_offset_vin3, adc_scale_vin3, 1)
    display_eeprom_content()

    request_factor('Enter gain value (e.g: 0.9996): ', 0x5A, '{:<6}', 6)
    adc_gain_vin3 = eeprom_m24c02.read_write(0x5A, '', 6, 'float')
    check_adc(3, ex_1v2_ref, adc_offset_vin3, adc_scale_vin3, adc_gain_vin3)
    display_eeprom_content()


def calculate_voltage_drop_3v75(functions, commands):
    """Calculate voltage drop between channels when source 3V75."""
    print TEXT['green'], calculate_voltage_drop_3v75.__doc__, TEXT['default']
    settings = functions[9]
    settings.append(commands[9])
    return settings


def __calculate_voltage_drop_3v75():
    """Measure switch voltage drop.

    SETUP: Connect M1K on the calibration board.
    Measure voltage value on connector and R8 on the M1K.
    """
    print TEXT['green'], __calculate_voltage_drop_3v75.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'GPIO_7__1', 'GPIO_1__1'])
    request_factor(
        'Enter voltage drop value (e.g: 0.0235): ', 0x61, '{:<6}', 6)
    display_eeprom_content()


def calculate_voltage_drop_1v25(functions, commands):
    """Calculate voltage drop between channels when source 1V25."""
    print TEXT['green'], calculate_voltage_drop_1v25.__doc__, TEXT['default']
    settings = functions[10]
    settings.append(commands[10])
    return settings


def __calculate_voltage_drop_1v25():
    """Measure switch voltage drop.

    SETUP: Connect M1K on the calibration board.
    Measure voltage value on connector and R8 on the M1K.
    """
    print TEXT['green'], __calculate_voltage_drop_1v25.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'GPIO_7__1', 'GPIO_1__1'])
    request_factor(
        'Enter voltage drop value (e.g: -0.0260): ', 0x68, '{:<7}', 7)
    display_eeprom_content()


def calibrate_adc_vin0_offset_poz(functions, commands):
    """Calibrate ADC offset to measure positive current."""
    print TEXT['green'], calibrate_adc_vin0_offset_poz.__doc__, TEXT['default']
    settings = functions[11]
    settings.append(commands[11])
    return settings


def __calibrate_adc_vin0_offset_poz():
    """SETUP: Connect M1K GND on the calibration board GND."""
    print TEXT['green'], \
        __calibrate_adc_vin0_offset_poz.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['EN_1V2__1'])
    check_adc_csa(0, 1, 1)
    request_factor('Enter offset hexa value (e.g: 757): ', 0x70, '{:<3}', 3)
    display_eeprom_content()


def calibrate_adc_vin0_gain_pos(functions, commands):
    """Calibrate ADC gain to measure positive current."""
    print TEXT['green'], calibrate_adc_vin0_gain_pos.__doc__, TEXT['default']
    settings = functions[12]
    settings.append(commands[12])
    return settings


def __calibrate_adc_vin0_gain_pos():
    """Calibrate ADC VIN0.

    SETUP: Connect between M1K and calibration board
    channel A pins a DMM to measure current.
    """
    print TEXT['green'], __calibrate_adc_vin0_gain_pos.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'GPIO_1__1', 'EN_1V2__1'])
    adc_offset_poz = int(eeprom_m24c02.read_write(0x70, '', 3, 'hex'), 16)
    check_adc_csa(adc_offset_poz, 1, 1)
    request_factor(
        'Enter adc current hexa value (e.g: A90): ', 0x75, '{:<3}', 3)
    display_eeprom_content()
    request_factor('Enter current value (e.g: .10010): ', 0x7A, '{:<6}', 6)
    adc_gain_poz = int(eeprom_m24c02.read_write(0x75, '', 3, 'hex'), 16)
    i_gain_poz = eeprom_m24c02.read_write(0x7A, '', 6, 'float')
    check_adc_csa(adc_offset_poz, adc_gain_poz, i_gain_poz)
    display_eeprom_content()


def calibrate_adc_vin0_offset_neg(functions, commands):
    """Calibrate ADC offset to measure negative current."""
    print TEXT['green'], calibrate_adc_vin0_offset_neg.__doc__, TEXT['default']
    settings = functions[13]
    settings.append(commands[13])
    return settings


def __calibrate_adc_vin0_offset_neg():
    """Calibrate ADC VIN0.

    SETUP: Connect M1K GND on the calibration board GND.
    """
    print TEXT['green'], \
        __calibrate_adc_vin0_offset_neg.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['EN_1V2__1'])
    check_adc_csa(0, 1, 1)
    request_factor('Enter offset hexa value (e.g: 757): ', 0x80, '{:<3}', 3)
    display_eeprom_content()


def calibrate_adc_vin0_gain_neg(functions, commands):
    """Calibrate ADC gain to measure negative current."""
    print TEXT['green'], calibrate_adc_vin0_gain_neg.__doc__, TEXT['default']
    settings = functions[14]
    settings.append(commands[14])
    return settings


def __calibrate_adc_vin0_gain_neg():
    """Calibrate ADC VIN0.

    SETUP: Connect between M1K and calibration board
    channel A pins a DMM to measure current.
    """
    print TEXT['green'], __calibrate_adc_vin0_gain_neg.__doc__, TEXT['default']
    ioxp_adp5589.gpo_set_ac(['GPIO_8__1', 'GPIO_1__1', 'EN_1V2__1'])
    adc_offset_neg = int(eeprom_m24c02.read_write(0x80, '', 3, 'hex'), 16)
    check_adc_csa(adc_offset_neg, 1, 1)
    request_factor(
        'Enter adc current hexa value (e.g: 41A): ', 0x85, '{:<3}', 3)
    display_eeprom_content()
    request_factor('Enter current value (e.g: -.10000)', 0x89, '{:<6}', 7)
    adc_gain_neg = int(eeprom_m24c02.read_write(0x85, '', 3, 'hex'), 16)
    i_gain_neg = eeprom_m24c02.read_write(0x89, '', 7, 'float')
    check_adc_csa(adc_offset_neg, adc_gain_neg, i_gain_neg)
    display_eeprom_content()


def default_set(default):
    """Reset to default."""
    print TEXT['green'], default_set.__doc__, TEXT['default']
    settings = [0.0, default, None]
    eeprom_m24c02.read_memory_content()
    ioxp_adp5589.gpo_set_ac([""])
    return settings


def translate_keyboard(keyboard_input, counter):
    """Convert keyboard input."""
    if keyboard_input == '':
        counter = 0
    if keyboard_input == '\x1b[C':
        counter += 1
    if keyboard_input == '\x1b[D':
        counter -= 1
    if keyboard_input == '\x1b':
        exit(1)
    if counter < 0:
        counter = 0
    if counter > 15:
        counter = 15
    return [counter, keyboard_input]


def set_configuration_part_1(counter, commands, functions, default):
    """Set configuration."""
    if counter[1] == commands[0]:
        settings = measure_external_2v5_1v2(functions, commands)
    elif counter[1] == commands[1]:
        settings = calculate_resistance_source(functions, commands)
    elif counter[1] == commands[2]:
        settings = calculate_resistance_sink(functions, commands)
    elif counter[1] == commands[3]:
        settings = set_dac_for_1v25(functions, commands)
    elif counter[1] == commands[4]:
        settings = set_dac_for_3v75(functions, commands)
    elif counter[1] == commands[5]:
        settings = calibrate_adc_vin1_5v0(functions, commands)
    elif counter[1] == commands[6]:
        settings = calibrate_adc_vin2_offset(functions, commands)
    else:
        settings = set_configuration_part_2(
            counter, commands, functions, default)
    settings.append(counter)
    return settings


def set_configuration_part_2(counter, commands, functions, default):
    """Set configuration."""
    if counter[1] == commands[7]:
        settings = calibrate_adc_vin2_scale_gain(functions, commands)
    elif counter[1] == commands[8]:
        settings = calibrate_adc_vin3_2v5(functions, commands)
    elif counter[1] == commands[9]:
        settings = calculate_voltage_drop_3v75(functions, commands)
    elif counter[1] == commands[10]:
        settings = calculate_voltage_drop_1v25(functions, commands)
    elif counter[1] == commands[11]:
        settings = calibrate_adc_vin0_offset_poz(functions, commands)
    elif counter[1] == commands[12]:
        settings = calibrate_adc_vin0_gain_pos(functions, commands)
    elif counter[1] == commands[13]:
        settings = calibrate_adc_vin0_offset_neg(functions, commands)
    elif counter[1] == commands[14]:
        settings = calibrate_adc_vin0_gain_neg(functions, commands)
    else:
        settings = default_set(default)
    settings.append(counter)
    return settings


def check_input(info_text, time, default, counter):
    """Check keyboard input."""
    keyboard_input = wait_for_input(info_text, time)
    loaded = load_lists()
    commands, functions = loaded[0], loaded[1]
    if not keyboard_input[0]:
        # print 'Keyboard input: ' + keyboard_input[1]
        try:
            counter = translate_keyboard(keyboard_input[1], counter)
            return set_configuration_part_1(
                counter, commands, functions, default)

        except ValueError:
            pass
    else:
        pass


def request_info(counter, commands):
    """Request informations."""
    if counter[1] == commands[0]:
        __measure_external_2v5_1v2()
    elif counter[1] == commands[1]:
        __calculate_resistance_source()
    elif counter[1] == commands[2]:
        __calculate_resistance_sink()
    elif counter[1] == commands[3]:
        __set_dac_for_1v25()
    elif counter[1] == commands[4]:
        __set_dac_for_3v75()
    elif counter[1] == commands[5]:
        __calibrate_adc_vin1_5v0()
    elif counter[1] == commands[6]:
        __calibrate_adc_vin2_offset()
    else:
        request_info_part_2(counter, commands)
    return menu()


def request_info_part_2(counter, commands):
    """Request informations."""
    if counter[1] == commands[7]:
        __calibrate_adc_vin2_scale_gain()
    elif counter[1] == commands[8]:
        __calibrate_adc_vin3_2v5()
    elif counter[1] == commands[9]:
        __calculate_voltage_drop_3v75()
    elif counter[1] == commands[10]:
        __calculate_voltage_drop_1v25()
    elif counter[1] == commands[11]:
        __calibrate_adc_vin0_offset_poz()
    elif counter[1] == commands[12]:
        __calibrate_adc_vin0_gain_pos()
    elif counter[1] == commands[13]:
        __calibrate_adc_vin0_offset_neg()
    elif counter[1] == commands[14]:
        __calibrate_adc_vin0_gain_neg()
    else:
        pass


def wait_key(info_text, time):
    """Check keyboard input."""
    keyboard_input = wait_for_input(info_text, time)
    if not keyboard_input[0]:
        # print 'Keyboard input: ' + keyboard_input[1]
        try:
            return keyboard_input[1]
        except ValueError:
            pass
    else:
        pass


def wait_for_input(text, time):
    """Wait for keyboard input."""
    signal.signal(signal.SIGALRM, signal_handler)
    signal.alarm(time)
    try:
        keyboard_input = raw_input(text)
        signal.alarm(0)
        timeout = False
    except KeyboardInterrupt:
        exit(1)
    except:
        timeout = True
        signal.alarm(0)
        keyboard_input = ''
    return timeout, keyboard_input


def signal_handler():
    """Signal handler function."""
    raise Exception('')


def output(string_text):
    """Print text on a single line in terminal."""
    return sys.stdout.write('\r' + string_text)


def set_channel_a_mode(received_mode, setpoint):
    """Set channel A mode."""
    if received_mode == Mode.SVMI:
        CHAN_A.mode = Mode.SVMI
        CHAN_A.write([setpoint], -1)
    elif received_mode == Mode.SIMV:
        CHAN_A.mode = Mode.SIMV
        CHAN_A.write([setpoint], -1)
    else:
        CHAN_A.mode = Mode.HI_Z


if __name__ == "__main__":
    SESSION = Session()
    VALID_SETPOINT = 0.0

    print 'Wait for device to be detected...'
    while not SESSION.devices:
        SESSION = Session()
    print 'Device detected...'

    if SESSION.devices:
        # Grab the first device from the session.
        DEV = SESSION.devices[0]

        # Set both channels to source voltage, measure current mode.
        CHAN_A = DEV.channels['A']
        CHAN_B = DEV.channels['B']
        CHAN_A.mode = Mode.HI_Z
        CHAN_B.mode = Mode.HI_Z

        # Start a continuous session.
        SESSION.start(0)
        NUM_SAMPLES = SESSION.queue_size + 1

        READY = False
        COUNTER = 0
        ioxp_adp5589.gpo_set_ac([""])
        adc_ad7091r5.init()
        dac_ad5647r.init()
        menu()
        while True:
            CH_A_VOLTAGE, CH_A_CURRENT, CH_B_VOLTAGE, CH_B_CURRENT = \
                [0.0], [0.0], [0.0], [0.0]
            SETTINGS_M1K = check_input(
                TEXT['purple'] + 'Step: ' + TEXT['default'],
                1, Mode.HI_Z, COUNTER)
            if SETTINGS_M1K is not None:
                COUNTER = SETTINGS_M1K[len(SETTINGS_M1K) - 1]
                VALID_SETPOINT = SETTINGS_M1K
                set_channel_a_mode(SETTINGS_M1K[1], VALID_SETPOINT[0])
                request_info(COUNTER, COMMANDS)

            SAMPLES = DEV.read(NUM_SAMPLES)
            for x in SAMPLES:
                CH_A_VOLTAGE.append(x[0][0])
                CH_A_CURRENT.append(x[0][1])
                CH_B_VOLTAGE.append(x[1][0])
                CH_B_CURRENT.append(x[0][1])
                READY = True
            if READY:
                output('{: 6f} {: 6f} {: 6f} {: 6f} '.format(
                    mean(CH_A_VOLTAGE), mean(CH_A_CURRENT),
                    mean(CH_B_VOLTAGE), mean(CH_B_CURRENT)))
    else:
        print 'no devices attached'
