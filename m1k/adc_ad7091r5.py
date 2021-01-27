"""Module to control ADC AD7091R5."""

from numpy import mean

import global_

global_.init()


def init():
    """Initialize the ADC in command mode configuration."""
    configuration_reg = 0x02
    command_mode_configuration = [0x04, 0xc0]
    global_.bus.write_i2c_block_data(
        global_.ADC_ID, configuration_reg, command_mode_configuration)


def convert_input(index):
    """Measure voltage from selected input."""
    conversion_result_reg = 0x00
    channel_reg = 0x01
    channel_selection = [0x01, 0x02, 0x04, 0x08]
    global_.bus.write_i2c_block_data(
        global_.ADC_ID, channel_reg, [channel_selection[index]])
    conversion_result_bytes = global_.bus.read_i2c_block_data(
        global_.ADC_ID, conversion_result_reg, 2)
    conversion_result_data = (
        (conversion_result_bytes[0] << 8) |
        conversion_result_bytes[1]) & 0x0fff
    return conversion_result_data


def current_value(offset_current, adc_i_ref, i_ref, sample_count, debug=False):
    """Measure current using calibration factors."""
    i_lsb = i_ref / (adc_i_ref - offset_current)
    get_crt_val = sample_count
    conversion_data = []
    while get_crt_val > 0:
        conversion_data.append(convert_input(0))
        get_crt_val -= 1
    if debug:
        print '\n', 'min', int(min(conversion_data)), \
            'avg', int(mean(conversion_data)), \
            'max', int(max(conversion_data))
    return [(int(mean(conversion_data)) - offset_current) * i_lsb,
            hex(int(mean(conversion_data)))]


def voltage_input(channel, calibration_factors, sample_count, debug=False):
    """Measure voltage using calibration factors."""
    adc_1v2_ref = calibration_factors[0]
    offset = calibration_factors[1]
    scaling = calibration_factors[2]
    gain = calibration_factors[3]

    v_lsb = adc_1v2_ref / 4096
    get_crt_val = sample_count
    conversion_data = []
    while get_crt_val > 0:
        conversion_data.append(convert_input(channel))
        get_crt_val -= 1
    if debug:
        print '\n', 'min', int(min(conversion_data)), \
            'avg', int(mean(conversion_data)), \
            'max', int(max(conversion_data))
    counts = int(mean(conversion_data))
    rezult = round((((counts - offset) * v_lsb) * scaling) * gain, 4)
    return [rezult, counts]
