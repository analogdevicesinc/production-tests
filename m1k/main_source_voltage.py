"""Main module."""
import inspect
import os
from time import sleep

import calibrate_m1k
import calibration_file
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
RESTART_CALIBRATION = 2

# Mean of buffer data or calculations result for each calibration step
# If list has 4 elements this represents [CH_A_V, CH_A_I, CH_B_V, CH_B_I]
CHX_F0V_RAW = [None] * 4
CHX_F2V5_RAW = [None] * 4

# Flag used to enable of disable M1K 2V5 external reference value
DO_NOT_GET_M1K_2V5_VAL = False

# Flags to perform calibration step by step by next ORDER_INDEX:
# Measure voltage, Source voltage, Measure current and then Source current
FIRST_STAGE = False
SECOND_STAGE = True
THIRD_STAGE = False
FOURTH_STAGE = False

# Stop script execution until user press ENTER
BRAKE_SCRIPT = False

USB = LED(12)
if __name__ == '__main__':
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
    # print 'Device detected... Continue calibration...'

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

            DEVICE_ID = global_.dev.serial
            DEVICE_FIRMWARE_VERSION = global_.dev.fwver
            DEVICE_HARDWARE_VERSION = global_.dev.hwver

            device_dir = global_.device_log_dir()
            FILE_NAME = os.path.join(device_dir, 'calib.txt')

            if VIEW_DEBUG_MESSAGES:
                print '\nORDER_INDEX', ORDER_INDEX, '\tDevID', DEVICE_ID, \
                    '\tDevFwVer', DEVICE_FIRMWARE_VERSION, '\tDevHwVer', \
                    DEVICE_HARDWARE_VERSION

            while RESTART_CALIBRATION <= 3:
                CHANNEL_NAME = chr(CHANNEL_INDEX + 65)

                DB_CAL = \
                    {'channel_name': CHANNEL_NAME,
                     'device_id': DEVICE_ID,
                     'view_debug_messages': VIEW_DEBUG_MESSAGES,
                     'create_plots': CREATE_PLOTS,
                     'brake_script': BRAKE_SCRIPT,
                     'device': global_.dev,
                     'restart_calibration': RESTART_CALIBRATION,
                     'channel_index': CHANNEL_INDEX,
                     'chx_f0v_raw': CHX_F0V_RAW,
                     'chx_f2v5_raw': CHX_F2V5_RAW,
                     'do_not_get_m1k_2v5_val': DO_NOT_GET_M1K_2V5_VAL,
                     'log_name': os.path.join(device_dir, 'log.txt')}

                CHX_F0V_RAW = calibrate_m1k.source_chx_0v_without_load(
                    DB_CAL, TEXT)
                CHX_F2V5_RAW = calibrate_m1k.source_chx_2v5_without_load(
                    DB_CAL, TEXT)

                STAGES = {'first_stage': FIRST_STAGE,
                          'second_stage': SECOND_STAGE,
                          'third_stage': THIRD_STAGE,
                          'fourth_stage': FOURTH_STAGE}

                DATA = {'chx_f0v_raw': CHX_F0V_RAW,
                        'chx_f2v5_raw': CHX_F2V5_RAW}

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
