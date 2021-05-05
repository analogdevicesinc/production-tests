"""Main module."""
import inspect
import sys
from time import sleep

import check_m1k
import eeprom_m24c02
import global_
import ioxp_adp5589
from gpiozero import LED
from pysmu import Session

# print debug values chosen by developer
VIEW_DEBUG_MESSAGES = False
VIEW_SHORT_DEBUG_MESSAGES = False

# continue script execution after fail
ENABLE_DEBUG_MODE = False

# create plot from buffer data
CREATE_PLOTS = False

# number of samples colected in buffer,
# discarding samples and effective number of used samples
global_.SAMPLES_OFFSET = 1000
global_.SAMPLES = global_.SAMPLES_OFFSET + 5000
global_.SAMPLES_USED = global_.SAMPLES - global_.SAMPLES_OFFSET

TEXT = global_.TEXT_COLOR_MAP

# number of samples colected through I2C from ADC
ADC_SAMPLES = 500

# index used to calibrate first detected board
ORDER_INDEX = 0

# variable used to switch between channels and vector data
CHANNEL_INDEX = 0

# Switch configuration between calibration and verification steps
RESTART_VERIFICATION = 0

# Verification status list for each step
# If each element of this list has 'True' value
# the M1K LED will be green else red
STATUS = []
STATUS_VALUES = []

# Stop script execution until user press ENTER
BRAKE_SCRIPT = False

# Read from EEPROM parameters used to
# calibrate current measurement using CSA and ADC
ADC_OFFSET_POZ = int(eeprom_m24c02.read_write(0x70, '', 3, 'hex'), 16)
ADC_GAIN_POZ = int(eeprom_m24c02.read_write(0x75, '', 3, 'hex'), 16)
I_GAIN_POZ = eeprom_m24c02.read_write(0x7A, '', 6, 'float')

ADC_OFFSET_NEG = int(eeprom_m24c02.read_write(0x80, '', 3, 'hex'), 16)
ADC_GAIN_NEG = int(eeprom_m24c02.read_write(0x85, '', 3, 'hex'), 16)
I_GAIN_NEG = eeprom_m24c02.read_write(0x89, '', 7, 'float')

# Tolerance values for all measurement
TOLERANCE_VOLTAGE = 0.011
TOLERANCE_CURRENT = 0.004

# Read from EEPROM External 2V5 and 1V2 references value
EX_1V2_REF = eeprom_m24c02.read_write(0x08, '', 6, 'float')

# Voltage setpoints for positive and
# negative current when M1K is in SVMI mode
SVMI_SETPOINT_POZ = 3.85
SVMI_SETPOINT_NEG = 1.15

# PARAMETERS_USED_TO_CHECK_MEASURE_VOLTAGE_PERFORMANCES_AFTER_CALIBRATION___
# Read from EEPROM MSB and LSB bytes for DAC
# to source 1V25, 3V75 and create DAC command
MSB_DAC_SRS_1V25 = int(eeprom_m24c02.read_write(0x20, '', 2, 'hex'), 16)
LSB_DAC_SRS_1V25 = int(eeprom_m24c02.read_write(0x22, '', 2, 'hex'), 16)
DAC_SRS_1V25_CMD = [MSB_DAC_SRS_1V25, LSB_DAC_SRS_1V25]
MSB_DAC_SRS_3V75 = int(eeprom_m24c02.read_write(0x25, '', 2, 'hex'), 16)
LSB_DAC_SRS_3V75 = int(eeprom_m24c02.read_write(0x27, '', 2, 'hex'), 16)
DAC_SRS_3V75_CMD = [MSB_DAC_SRS_3V75, LSB_DAC_SRS_3V75]

# PARAMETERS_USED_TO_CHECK_SOURCE_VOLTAGE_PERFORMANCES_AFTER_CALIBRATION____
# Define voltage setpoint and tolerance for 0V8, 2V5 and 4V5 measurement
SRS_0V8_SETPOINT = 0.8
SRS_2V5_SETPOINT = 2.5
SRS_4V5_SETPOINT = 4.5

# PARAMETERS_USED_TO_CHECK_SOURCE_CURRENT_PERFORMANCES_AFTER_CALIBRATION____
# Current setpoint for positive and negative
# current when M1K is in SIMV mode
SRS_I_SETPOINT_POZ = 0.1
SRS_I_SETPOINT_NEG = -0.1

# Read from EEPROM parametters for external
# ADC calibration for channel 2,3 and 4
ADC_OFFSET_VIN1 = int(eeprom_m24c02.read_write(0x30, '', 2, 'float'))
ADC_SCALE_VIN1 = eeprom_m24c02.read_write(0x33, '', 6, 'float')
ADC_GAIN_VIN1 = eeprom_m24c02.read_write(0x3A, '', 6, 'float')
CALIBRATION_FACTORS_VIN1 = [
    EX_1V2_REF, ADC_OFFSET_VIN1, ADC_SCALE_VIN1, ADC_GAIN_VIN1]

ADC_OFFSET_VIN2 = int(eeprom_m24c02.read_write(0x40, '', 2, 'float'))
ADC_SCALE_VIN2 = eeprom_m24c02.read_write(0x43, '', 6, 'float')
ADC_GAIN_VIN2 = eeprom_m24c02.read_write(0x4A, '', 6, 'float')
CALIBRATION_FACTORS_VIN2 = [
    EX_1V2_REF, ADC_OFFSET_VIN2, ADC_SCALE_VIN2, ADC_GAIN_VIN2]

ADC_OFFSET_VIN3 = int(eeprom_m24c02.read_write(0x50, '', 2, 'float'))
ADC_SCALE_VIN3 = eeprom_m24c02.read_write(0x53, '', 6, 'float')
ADC_GAIN_VIN3 = eeprom_m24c02.read_write(0x5A, '', 6, 'float')
CALIBRATION_FACTORS_VIN3 = [
    EX_1V2_REF, ADC_OFFSET_VIN3, ADC_SCALE_VIN3, ADC_GAIN_VIN3]

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
    # print 'Device detected... Start verification...'

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

            if VIEW_DEBUG_MESSAGES:
                print '\nORDER_INDEX', ORDER_INDEX, '\tDevID', DEVICE_ID, \
                    '\tDevFwVer', DEVICE_FIRMWARE_VERSION, '\tDevHwVer', \
                    DEVICE_HARDWARE_VERSION

            CHANNEL_INDEX = 0
            ioxp_adp5589.gpo_set_port_a(['EN_1V2__1'])
            # USB.on()
            # sleep(1)

            while RESTART_VERIFICATION <= 1:
                CHANNEL_NAME = chr(CHANNEL_INDEX + 65)

                DB_CHECK = \
                    {'channel_name': CHANNEL_NAME,
                     'device_id': DEVICE_ID,
                     'view_debug_messages': VIEW_DEBUG_MESSAGES,
                     'view_short_debug_messages': VIEW_SHORT_DEBUG_MESSAGES,
                     'enable_debug_mode': ENABLE_DEBUG_MODE,
                     'create_plots': CREATE_PLOTS,
                     'brake_script': BRAKE_SCRIPT,
                     'device': global_.dev,
                     'restart_verification': RESTART_VERIFICATION,
                     'calibration_factors_vin2': CALIBRATION_FACTORS_VIN2,
                     'adc_samples': ADC_SAMPLES,
                     'tolerance_voltage': TOLERANCE_VOLTAGE,
                     'tolerance_current': TOLERANCE_CURRENT,
                     'dac_srs_1v25_cmd': DAC_SRS_1V25_CMD,
                     'dac_srs_3v75_cmd': DAC_SRS_3V75_CMD,
                     'srs_0v8_setpoint': SRS_0V8_SETPOINT,
                     'srs_2v5_setpoint': SRS_2V5_SETPOINT,
                     'srs_4v5_setpoint': SRS_4V5_SETPOINT,
                     'adc_offset_poz': ADC_OFFSET_POZ,
                     'adc_gain_poz': ADC_GAIN_POZ,
                     'i_gain_poz': I_GAIN_POZ,
                     'adc_offset_neg': ADC_OFFSET_NEG,
                     'adc_gain_neg': ADC_GAIN_NEG,
                     'i_gain_neg': I_GAIN_NEG,
                     'svmi_setpoint_poz': SVMI_SETPOINT_POZ,
                     'svmi_setpoint_neg': SVMI_SETPOINT_NEG,
                     'srs_i_setpoint_poz': SRS_I_SETPOINT_POZ,
                     'srs_i_setpoint_neg': SRS_I_SETPOINT_NEG,
                     'channel_index': CHANNEL_INDEX,
                     'status': STATUS,
                     'status_values': STATUS_VALUES}

                if VIEW_DEBUG_MESSAGES:
                    print '\nwhile restart performance \trestart: ' + \
                        str(RESTART_VERIFICATION)

                if RESTART_VERIFICATION == 0:
                    if VIEW_DEBUG_MESSAGES:
                        print check_m1k.check_current_offset(DB_CHECK, TEXT)
                    STATUS = check_m1k.supply_output_5v0(
                        4.9, 5.1, CALIBRATION_FACTORS_VIN1,
                        ADC_SAMPLES, DB_CHECK)
                    STATUS = check_m1k.supply_output_2v5(
                        2.4, 2.6, CALIBRATION_FACTORS_VIN3,
                        ADC_SAMPLES, DB_CHECK)
                    STATUS = check_m1k.user_digital_in_out(
                        global_.dev, DB_CHECK)

                STATUS = check_m1k.voltage_measurement_2v5(DB_CHECK, TEXT)
                STATUS = check_m1k.voltage_measurement_2v5_aux(DB_CHECK, TEXT)
                STATUS = check_m1k.voltage_measurement_1v25(DB_CHECK, TEXT)
                STATUS = check_m1k.voltage_measurement_3v75(DB_CHECK, TEXT)
                STATUS = check_m1k.source_0v8(DB_CHECK, TEXT)
                STATUS = check_m1k.source_2v5(DB_CHECK, TEXT)
                STATUS = check_m1k.source_4v5(DB_CHECK, TEXT)
                STATUS = check_m1k.positive_current_measurement(DB_CHECK, TEXT)
                STATUS = check_m1k.negative_current_measurement(DB_CHECK, TEXT)
                STATUS = check_m1k.positive_current_source(DB_CHECK, TEXT)
                STATUS = check_m1k.negative_current_source(DB_CHECK, TEXT)

                RESTART_VERIFICATION += 1
                CHANNEL_INDEX += 1

            ORDER_INDEX += 1
            RESTART_VERIFICATION = 0
            CHANNEL_INDEX = 0

            if ORDER_INDEX == BOARD_NUMBER:
                USB.off()
                sleep(1)
                check_m1k.tft_check_status(DB_CHECK, TEXT)
                ioxp_adp5589.gpo_set_port_a([])
                if ('v' + str(DEVICE_FIRMWARE_VERSION)) != sys.argv[1]:
                    print TEXT['red'] + "Firmware version mismatch:"
                    print "Got: v" + str(DEVICE_FIRMWARE_VERSION)
                    print "Expected: " + sys.argv[1]
                    print TEXT['default']
                    exit(1)
                if (all(x is True for x in STATUS)):
                    exit(0)
                else:
                    exit(1)
