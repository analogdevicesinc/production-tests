"""Main module."""
import inspect
import os
from time import sleep

import calibrate_m1k
import calibration_file
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
RESTART_CALIBRATION = 4

# Mean of buffer data or calculations result for each calibration step
# If list has 2 elements this represents [CH_A_V, CH_B_V]
# If list has 4 elements this represents [CH_A_V, CH_A_I, CH_B_V, CH_B_I]
CHX_F0V_RAW = [None] * 4
CHX_S5V_RAW = [None] * 4
CHX_S0V_RAW = [None] * 4
CALCULATED_I_POZ_REF = [None] * 2
CALCULATED_I_NEG_REF = [None] * 2

# M1K 2V5 external reference value for
# channel A and B when measure or source current
M1K_2V5 = [None] * 10

# M1K channel value measured channel which is in HI_Z mode
M1K_HI_Z_CHX = [None] * 4

# Flag used to enable of disable M1K 2V5 external reference value
DO_NOT_GET_M1K_2V5_VAL = False

# Flags to perform calibration step by step by next ORDER_INDEX:
# Measure voltage, Source voltage, Measure current and then Source current
FIRST_STAGE = False
SECOND_STAGE = False
THIRD_STAGE = True
FOURTH_STAGE = False

# Stop script execution until user press ENTER
BRAKE_SCRIPT = False

# PARAMETERS_USED_TO_CHECK_MEASURE_CURRENT_PERFORMANCES_AFTER_CALIBRATION___
# Read from EEPROM resistor value when channel A or B
# source or sink current
R_CH_SRS = eeprom_m24c02.read_write(0x10, '', 8, 'float')
R_CH_SNK = eeprom_m24c02.read_write(0x18, '', 8, 'float')
# Voltage setpoints for positive and
# negative current when M1K is in SVMI mode
SVMI_SETPOINT_POZ = 3.85
SVMI_SETPOINT_NEG = 1.15
# Voltage offsets between CHA and CHB
# caused by the voltage drop on the connector
COMP_POZ = eeprom_m24c02.read_write(0x61, '', 6, 'float')
COMP_NEG = eeprom_m24c02.read_write(0x68, '', 7, 'float')

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

            while RESTART_CALIBRATION <= 5:
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
                     'do_not_get_m1k_2v5_val': DO_NOT_GET_M1K_2V5_VAL,
                     'chx_s5v_raw': CHX_S5V_RAW,
                     'chx_s0v_raw': CHX_S0V_RAW,
                     'm1k_hi_z_chx': M1K_HI_Z_CHX,
                     'm1k_2v5': M1K_2V5,
                     'calculated_i_poz_ref': CALCULATED_I_POZ_REF,
                     'calculated_i_neg_ref': CALCULATED_I_NEG_REF,
                     'r_ch_srs': R_CH_SRS,
                     'r_ch_snk': R_CH_SNK,
                     'svmi_setpoint_poz': SVMI_SETPOINT_POZ,
                     'svmi_setpoint_neg': SVMI_SETPOINT_NEG,
                     'comp_poz': COMP_POZ,
                     'comp_neg': COMP_NEG,
                     'log_name': os.path.join(device_dir, 'log.txt')}

                INDEX = CHANNEL_INDEX * 2 + 1
                CHX_F0V_RAW[INDEX] = \
                    float(calibration_file.extract_data_from_log(
                        DB_CAL['log_name'], 14 + CHANNEL_INDEX * 6)[INDEX])

                DATA = calibrate_m1k.measure_chx_positive_current(
                    DB_CAL, TEXT)
                CHX_S5V_RAW, M1K_HI_Z_CHX, M1K_2V5 = DATA[0], DATA[1], DATA[2]
                DATA = calibrate_m1k.measure_chx_negative_current(
                    DB_CAL, TEXT)
                CHX_S0V_RAW, M1K_HI_Z_CHX, M1K_2V5 = DATA[0], DATA[1], DATA[2]

                DATA = calibrate_m1k.calculate_currents(DB_CAL, TEXT)
                CALCULATED_I_POZ_REF, CALCULATED_I_NEG_REF = DATA[0], DATA[1]

                STAGES = {'first_stage': FIRST_STAGE,
                          'second_stage': SECOND_STAGE,
                          'third_stage': THIRD_STAGE,
                          'fourth_stage': FOURTH_STAGE}

                DATA = {'chx_f0v_raw': CHX_F0V_RAW,
                        'calculated_i_poz_ref': CALCULATED_I_POZ_REF,
                        'chx_s5v_raw': CHX_S5V_RAW,
                        'calculated_i_neg_ref': CALCULATED_I_NEG_REF,
                        'chx_s0v_raw': CHX_S0V_RAW}

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
