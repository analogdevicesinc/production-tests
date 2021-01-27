"""Module used to control M1K board."""
import commands
from time import sleep

from numpy import mean

import global_
from gpiozero import LED

global_.init()


def upload_firmware(firwmare_file, retry, text):
    """Upload firmware.

    Run firmare upload command and print returned message.
    Loop every seccond firmware upload command maximum n attempts
    then exit or continue depending on returned message
    """
    err_msg_retry = [
        'smu: failed updating firmware: no devices found in SAM-BA mode',
        'smu: failed updating firmware: failed to read SAM-BA response: ' +
        'Operation timed out']
    err_msg_exit = [
        'smu: failed updating firmware: failed to open firmware file',
        'smu: error initializing session: Device or resource busy',
        'smu: failed updating firmware: failed to read SAM-BA response: ' +
        'Input/Output Error']
    print text['green'] + '\nStart flash device...' + text['default']

    firmware_update_msg = commands.getstatusoutput(
        'smu -f ' + firwmare_file)[1]
    if firmware_update_msg in err_msg_exit:
        print text['red'] + firmware_update_msg + text['default']
        exit(1)
    if firmware_update_msg not in err_msg_retry:
        print text['green'] + firmware_update_msg + text['default']
    while firmware_update_msg in err_msg_retry:
        firmware_update_msg = commands.getstatusoutput(
            'smu -f ' + firwmare_file)[1]
        sleep(1)
        retry -= 1
        if retry <= 0:
            print text['red'] + firmware_update_msg + text['default']
            exit(1)


def channels_in_hi_z():
    """Set channel A and B in HI_Z mode."""
    global_.CHA.mode = global_.Mode.HI_Z
    global_.CHB.mode = global_.Mode.HI_Z


def set_switches_chs_2v5_gnd(cha_2v5, cha_gnd, chb_2v5, chb_gnd, device):
    """Set M1K switches state."""
    function_name = set_switches_chs_2v5_gnd.__name__
    if cha_2v5 == 'close':
        device.ctrl_transfer(0x40, 0x50, 32, 0, 0, 0, 100)
    elif cha_2v5 == 'open':
        device.ctrl_transfer(0x40, 0x51, 32, 0, 0, 0, 100)
    else:
        print 'invalid value 1st arg ' + function_name

    if cha_gnd == 'close':
        device.ctrl_transfer(0x40, 0x50, 33, 0, 0, 0, 100)
    elif cha_gnd == 'open':
        device.ctrl_transfer(0x40, 0x51, 33, 0, 0, 0, 100)
    else:
        print 'invalid value 2nd arg ' + function_name

    if chb_2v5 == 'close':
        device.ctrl_transfer(0x40, 0x50, 37, 0, 0, 0, 100)
    elif chb_2v5 == 'open':
        device.ctrl_transfer(0x40, 0x51, 37, 0, 0, 0, 100)
    else:
        print 'invalid value 3rd arg ' + function_name

    if chb_gnd == 'close':
        device.ctrl_transfer(0x40, 0x50, 38, 0, 0, 0, 100)
    elif chb_gnd == 'open':
        device.ctrl_transfer(0x40, 0x51, 38, 0, 0, 0, 100)
    else:
        print 'invalid value 4th arg ' + function_name


def get_external_2v5_samples(device):
    """Get channels voltage value and return mean and buffer data."""
    voltage_channel_a_list = []
    voltage_channel_b_list = []
    buffer_data = device.get_samples(global_.SAMPLES)
    for index in range(global_.SAMPLES_USED):
        channel_a_data = buffer_data[index + global_.SAMPLES_OFFSET][0]
        channel_b_data = buffer_data[index + global_.SAMPLES_OFFSET][1]

        voltage_channel_a = float(channel_a_data[0])
        voltage_channel_a_list.append(voltage_channel_a)

        voltage_channel_b = float(channel_b_data[0])
        voltage_channel_b_list.append(voltage_channel_b)

    global_.CHX_2V5_EX_REF = [
        mean(voltage_channel_a_list), 0.0,
        mean(voltage_channel_b_list), 0.0,
        [voltage_channel_a_list, [0.0] * global_.SAMPLES_USED,
         voltage_channel_b_list, [0.0] * global_.SAMPLES_USED]]
    return global_.CHX_2V5_EX_REF


def get_samples_find_average(device):
    """Get samples.

    Get channels voltage and current value and return mean and buffer data.
    """
    voltage_channel_a_list = []
    current_channel_a_list = []
    voltage_channel_b_list = []
    current_channel_b_list = []
    buffer_data = device.get_samples(global_.SAMPLES)
    for index in range(global_.SAMPLES_USED):
        channel_a_data = buffer_data[index + global_.SAMPLES_OFFSET][0]
        channel_b_data = buffer_data[index + global_.SAMPLES_OFFSET][1]

        voltage_channel_a = float(channel_a_data[0])
        voltage_channel_a_list.append(voltage_channel_a)

        current_channel_a = float(channel_a_data[1])
        current_channel_a_list.append(current_channel_a)

        voltage_channel_b = float(channel_b_data[0])
        voltage_channel_b_list.append(voltage_channel_b)

        current_channel_b = float(channel_b_data[1])
        current_channel_b_list.append(current_channel_b)

    global_.CHX_V_I = [round(mean(voltage_channel_a_list), 6),
                       round(mean(current_channel_a_list), 6),
                       round(mean(voltage_channel_b_list), 6),
                       round(mean(current_channel_b_list), 6),
                       [voltage_channel_a_list, current_channel_a_list,
                        voltage_channel_b_list, current_channel_b_list]]
    return global_.CHX_V_I


def source_0v(channel, mode_1, mode_value, mode_2, device):
    """Source 0V.

    Source 0V with channel A or B, put unused channel
    in HI_Z and open 2V5 and GND switches.
    """
    if channel == 0:
        set_switches_chs_2v5_gnd('open', 'open', 'open', 'open', device)
        channel_a_mode_and_value(mode_1, mode_value)
        channel_b_mode_and_value(mode_2)
    else:
        set_switches_chs_2v5_gnd('open', 'open', 'open', 'open', device)
        channel_b_mode_and_value(mode_1, mode_value)
        channel_a_mode_and_value(mode_2)


def channel_a_mode_and_value(a_mode, a_val=None):
    """Set mode for channel A."""
    global_.CHA.mode = a_mode
    if a_val is not None:
        global_.CHA.constant(a_val)


def channel_b_mode_and_value(b_mode, b_val=None):
    """Set mode for channel B."""
    global_.CHB.mode = b_mode
    if b_val is not None:
        global_.CHB.constant(b_val)


def source(channel, mode_1, mode_value, mode_2, device, get_ref_val=True):
    """Source xV.

    Source with channel A or B, put unused channel
    in HI_Z and choose to measure 2V5
    """
    if channel == 0:
        if get_ref_val:
            set_switches_chs_2v5_gnd('open', 'open', 'close', 'open', device)
        else:
            set_switches_chs_2v5_gnd('open', 'open', 'open', 'open', device)
        channel_a_mode_and_value(mode_1, mode_value)
        channel_b_mode_and_value(mode_2)
    else:
        if get_ref_val:
            set_switches_chs_2v5_gnd('close', 'open', 'open', 'open', device)
        else:
            set_switches_chs_2v5_gnd('open', 'open', 'open', 'open', device)
        channel_b_mode_and_value(mode_1, mode_value)
        channel_a_mode_and_value(mode_2)
