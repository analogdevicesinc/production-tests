"""Main module."""
import inspect
import os
from time import sleep

import calibrate_m1k
import calibration_file
import control_m1k
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
RESTART_CALIBRATION = 6

# Mean of buffer data or calculations result for each calibration step
# If list has 4 elements this represents [CH_A_V, CH_A_I, CH_B_V, CH_B_I]
CHX_S0A_RAW = [None] * 4
CHX_S_POZ_RAW = [None] * 4
CHX_S_NEG_RAW = [None] * 4

# M1K 2V5 external reference value for
# channel A and B when measure or source current
M1K_2V5 = [None] * 10

# Flag used to enable of disable M1K 2V5 external reference value
DO_NOT_GET_M1K_2V5_VAL = False

# Flags to perform calibration step by step by next ORDER_INDEX:
# Measure voltage, Source voltage, Measure current and then Source current
FIRST_STAGE = False
SECOND_STAGE = False
THIRD_STAGE = False
FOURTH_STAGE = True

# Stop script execution until user press ENTER
BRAKE_SCRIPT = False

# PARAMETERS_USED_TO_CHECK_SOURCE_CURRENT_PERFORMANCES_AFTER_CALIBRATION____
# Current setpoint for positive and negative
# current when M1K is in SIMV mode
SRS_I_SETPOINT_POZ = 0.1
SRS_I_SETPOINT_NEG = -0.1

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
            log_name = os.path.join(device_dir, 'log.txt')

            if VIEW_DEBUG_MESSAGES:
                print '\nORDER_INDEX', ORDER_INDEX, '\tDevID', DEVICE_ID, \
                    '\tDevFwVer', DEVICE_FIRMWARE_VERSION, '\tDevHwVer', \
                    DEVICE_HARDWARE_VERSION

            LOG_M1K_2V5 = calibration_file.extract_data_from_log(log_name, 47)
            M1K_2V5[0] = float(LOG_M1K_2V5[0])
            M1K_2V5[1] = float(LOG_M1K_2V5[1])
            M1K_2V5[5] = float(LOG_M1K_2V5[5])
            M1K_2V5[6] = float(LOG_M1K_2V5[6])

            while RESTART_CALIBRATION <= 7:
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
                     'do_not_get_m1k_2v5_val': DO_NOT_GET_M1K_2V5_VAL,
                     'srs_i_setpoint_poz': SRS_I_SETPOINT_POZ,
                     'srs_i_setpoint_neg': SRS_I_SETPOINT_NEG,
                     'chx_s0a_raw': CHX_S0A_RAW,
                     'chx_s_poz_raw': CHX_S_POZ_RAW,
                     'chx_s_neg_raw': CHX_S_NEG_RAW,
                     'm1k_2v5': M1K_2V5,
                     'log_name': log_name}

                DATA = calibrate_m1k.source_chx_0a_current(DB_CAL, TEXT)
                CHX_S0A_RAW, M1K_2V5 = DATA[0], DATA[1]

                DATA = calibrate_m1k.source_chx_positive_current(DB_CAL, TEXT)
                CHX_S_POZ_RAW, M1K_2V5 = DATA[0], DATA[1]

                DATA = calibrate_m1k.source_chx_negative_current(DB_CAL, TEXT)
                CHX_S_NEG_RAW, M1K_2V5 = DATA[0], DATA[1]

                # Disconnect channels from GND and 2V5
                # using internal M1K switches
                control_m1k.set_switches_chs_2v5_gnd(
                    'open', 'open', 'open', 'open', global_.dev)

                STAGES = {'first_stage': FIRST_STAGE,
                          'second_stage': SECOND_STAGE,
                          'third_stage': THIRD_STAGE,
                          'fourth_stage': FOURTH_STAGE}

                DATA = {'chx_s0a_raw': CHX_S0A_RAW,
                        'srs_i_setpoint_poz': SRS_I_SETPOINT_POZ,
                        'chx_s_poz_raw': CHX_S_POZ_RAW,
                        'srs_i_setpoint_neg': SRS_I_SETPOINT_NEG,
                        'chx_s_neg_raw': CHX_S_NEG_RAW}

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
