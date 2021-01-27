"""Main module."""
import inspect
import os
import sys
from time import sleep

import calibrate_m1k
import calibration_file
import control_m1k
import eeprom_m24c02
import global_
from gpiozero import LED
from pysmu import Session

# print calibration coeficients calculated by M1K
VIEW_CALIBRATION_FACTORS = False

# print debug values chosen by developer
VIEW_DEBUG_MESSAGES = False

# create plot from buffer data
CREATE_PLOTS = False

# number of samples colected in buffer,
# discarding samples and effective number of used samples
global_.SAMPLES = 5000
global_.SAMPLES_OFFSET = 0
global_.SAMPLES_USED = 5000

TEXT = global_.TEXT_COLOR_MAP

# number of samples colected through I2C from ADC
ADC_SAMPLES = 200

# index used to calibrate first detected board
ORDER_INDEX = 0

# variable used to switch between channels and vector data
CHANNEL_INDEX = 0

# Switch configuration between calibration and verification steps
RESTART_CALIBRATION = 0

# Mean of buffer data or calculations result for each calibration step
# If list has 2 elements this represents [CH_A_V, CH_B_V]
# If list has 4 elements this represents [CH_A_V, CH_A_I, CH_B_V, CH_B_I]
CHX_2V5_EX_REF_RAW = [None] * 2
CHX_V_I_GND_RAW = [None] * 4

# Flags to perform calibration step by step by next ORDER_INDEX:
# Measure voltage, Source voltage, Measure current and then Source current
FIRST_STAGE = True
SECOND_STAGE = False
THIRD_STAGE = False
FOURTH_STAGE = False

# Stop script execution until user press ENTER
BRAKE_SCRIPT = False

# Read from EEPROM External 2V5 and 1V2 references value
EX_2V5_REF = eeprom_m24c02.read_write(0x00, '', 6, 'float')
EX_1V2_REF = eeprom_m24c02.read_write(0x08, '', 8, 'float')

USB = LED(12)
if __name__ == '__main__':
    USB.on()
    sleep(2)

    if VIEW_DEBUG_MESSAGES:
        print eeprom_m24c02.read_memory_content()

    control_m1k.upload_firmware(sys.argv[1], 6, TEXT)

    USB.off()
    sleep(2)
    USB.on()
    sleep(2)

    global_.session = Session()

    # print 'Wait for device to be detected...', \
    #     TEXT['orange'], inspect.stack()[0][1], TEXT['default']
    print TEXT['turquoise'], inspect.stack()[0][1], TEXT['default']
    while not global_.session.devices:
        global_.session = Session()
        sleep(1)
    # print 'Device detected... Start calibration...'

    BOARD_NUMBER = len(global_.session.devices)
    if VIEW_DEBUG_MESSAGES:
        print 'Number of detected boards:', BOARD_NUMBER

    if global_.session.devices:
        while ORDER_INDEX <= BOARD_NUMBER:
            if VIEW_DEBUG_MESSAGES:
                print 'ORDER_INDEX:', ORDER_INDEX, '\tbrdnum:', BOARD_NUMBER

            # Grab the first device from the session.
            global_.dev = global_.session.devices[0]
            global_.CHA = global_.dev.channels['A']
            global_.CHB = global_.dev.channels['B']

            if VIEW_CALIBRATION_FACTORS:
                print TEXT['purple'] + \
                    '\nInitial calibration parametters before ' + \
                    'writing default calibration:\n' + \
                    str(global_.dev.calibration) + TEXT['default']
            global_.dev.write_calibration("calib_default.txt")
            if VIEW_CALIBRATION_FACTORS:
                print TEXT['purple'] + \
                    '\nInitial calibration parametters after ' + \
                    'writing default calibration:\n' + \
                    str(global_.dev.calibration) + TEXT['default']

            DEVICE_ID = global_.dev.serial
            DEVICE_FIRMWARE_VERSION = global_.dev.fwver
            DEVICE_HARDWARE_VERSION = global_.dev.hwver

            device_dir = global_.device_log_dir()
            FILE_NAME = os.path.join(device_dir, 'calib.txt')
            calibration_file.copy_text_file('calib_default.txt', FILE_NAME)

            if VIEW_DEBUG_MESSAGES:
                print '\nORDER_INDEX', ORDER_INDEX, '\tDevID', DEVICE_ID,\
                    '\tDevFwVer', DEVICE_FIRMWARE_VERSION, '\tDevHwVer',\
                    DEVICE_HARDWARE_VERSION

            log_name = os.path.join(device_dir, 'log.txt')
            calibration_file.create_log(log_name)

            while RESTART_CALIBRATION <= 1:
                CHANNEL_NAME = chr(CHANNEL_INDEX + 65)

                DB_CAL = {
                    'channel_name': CHANNEL_NAME,
                    'device_id': DEVICE_ID,
                    'view_debug_messages': VIEW_DEBUG_MESSAGES,
                    'create_plots': CREATE_PLOTS,
                    'brake_script': BRAKE_SCRIPT,
                    'device': global_.dev,
                    'restart_calibration': RESTART_CALIBRATION,
                    'channel_index': CHANNEL_INDEX,
                    'chx_2v5_ex_ref_raw': CHX_2V5_EX_REF_RAW,
                    'chx_v_i_gnd_raw': CHX_V_I_GND_RAW,
                    'log_name': log_name}

                CHX_2V5_EX_REF_RAW = calibrate_m1k.measure_chx_external_2v5(
                    DB_CAL, TEXT)
                CHX_V_I_GND_RAW = calibrate_m1k.measure_chx_gnd(
                    DB_CAL, TEXT)

                STAGES = {'first_stage': FIRST_STAGE,
                          'second_stage': SECOND_STAGE,
                          'third_stage': THIRD_STAGE,
                          'fourth_stage': FOURTH_STAGE}

                DATA = {'chx_v_i_gnd_raw': CHX_V_I_GND_RAW,
                        'ex_2v5_ref': EX_2V5_REF,
                        'chx_2v5_ex_ref_raw': CHX_2V5_EX_REF_RAW}

                calibration_file.update(CHANNEL_INDEX, FILE_NAME, STAGES, DATA)

                if RESTART_CALIBRATION in range(1, 8, 2):
                    global_.dev.write_calibration(FILE_NAME)

                    if VIEW_CALIBRATION_FACTORS:
                        print '\n' + TEXT['turquoise'] + \
                            '\nCalibration factors: \n' + \
                            str(global_.dev.calibration) + \
                            TEXT['default'] + '\n\n'
                        with open(FILE_NAME, 'r') as fin:
                            print TEXT['purple'] + '\n' + fin.read() + \
                                TEXT['default']

                RESTART_CALIBRATION += 1
                if CHANNEL_INDEX < 1:
                    CHANNEL_INDEX += 1
                else:
                    CHANNEL_INDEX = 0
                if RESTART_CALIBRATION >= 2:
                    FIRST_STAGE, SECOND_STAGE, THIRD_STAGE, FOURTH_STAGE = \
                        False, True, False, False
                if RESTART_CALIBRATION >= 4:
                    FIRST_STAGE, SECOND_STAGE, THIRD_STAGE, FOURTH_STAGE = \
                        False, False, True, False
                if RESTART_CALIBRATION >= 6:
                    FIRST_STAGE, SECOND_STAGE, THIRD_STAGE, FOURTH_STAGE = \
                        False, False, False, True

            ORDER_INDEX += 1
            RESTART_CALIBRATION = 0
            CHANNEL_INDEX = 0

            if ORDER_INDEX == BOARD_NUMBER:
                # print 'Done ...'
                exit(0)
