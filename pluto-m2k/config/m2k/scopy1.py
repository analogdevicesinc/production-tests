import libm2k
import subprocess
from time import sleep
import math
import numpy as np
from datetime import datetime

SHOW_TIMESTAMP = True
SHOW_START_END_TIME = True
MAX_HIGH_GAIN = 2.515
MIN_HIGH_GAIN = 2.465
MAX_LOW_GAIN = 10.15
MIN_LOW_GAIN = 9.65
ADC_CONST_ERR_THRESHOLD = 0.1
M2KCALIB_INI = "m2k-calib-factory.ini"
M2KCALIB_INI_LOCAL = "/tmp/" + M2KCALIB_INI
PWS_POS_FIRST = 0.1;
PWS_POS_SECOND = 4.5;
PWS_NEG_FIRST = -PWS_POS_FIRST;
PWS_NEG_SECOND = -PWS_POS_SECOND;

#Default PWS calibration values
OFFSET_POS_DAC = 0
GAIN_POS_DAC = 1
OFFSET_POS_ADC = 0
GAIN_POS_ADC = 1
OFFSET_NEG_DAC = 0
GAIN_NEG_DAC = 1
OFFSET_NEG_ADC = 0
GAIN_NEG_ADC = 1

#*********************************************************************************************************
#	STEP 5
#*********************************************************************************************************

def _osc_change_gain_mode(ch, high):
	global osc
	osc.enableChannel(ch, True)

	if high:
		osc.setRange(ch, libm2k.HIGH_GAIN)
	else:
		osc.setRange(ch, libm2k.LOW_GAIN)


def _osc_check_range(high, value):
	if high:
		if (value < MAX_HIGH_GAIN) and (value > MIN_HIGH_GAIN):
			return True
		else:
			return False
	else:
		if (value < MAX_LOW_GAIN) and (value > MIN_LOW_GAIN):
			return True
		else:
			return False

def disable_ref_measurement():
	subprocess.run(["./ref_measure_ctl.sh", "disable"])
	#extern.start("sshpass -pjig ssh jig@localhost sudo ~/plutosdr-m2k-production-test-V2/ref_measure_ctl.sh disable");
	#//extern.start("./ref_measure_ctl.sh disable");

def _test_osc_range(ch, high):
	global osc
	result = ""

	if high:
		subprocess.run(["./ref_measure_ctl.sh", "ref2.5v"])
		#output = extern.start("sshpass -pjig ssh jig@localhost sudo ~/plutosdr-m2k-production-test-V2/ref_measure_ctl.sh ref2.5v");
		#output = extern.start("./ref_measure_ctl.sh ref2.5v")
	else:
		subprocess.run(["./ref_measure_ctl.sh", "ref10v"])
		#output = extern.start("sshpass -pjig ssh jig@localhost sudo ~/plutosdr-m2k-production-test-V2/ref_measure_ctl.sh ref10v");
		#output = extern.start("./ref_measure_ctl.sh ref10v")

	_osc_change_gain_mode(ch, high)
	#/* Busy wait for 10 seconds, with 100 milliseconds intervals */
	for i in range(0, 100):
		value = _osc_read_constant(ch)
		ret = _osc_check_range(high, value)
		if ret:
			break
		sleep(0.1)

	if ret:
		result += "PASSED "
	else:
		result += "FAILED "

	result += " channel: " +  str(ch) + " high-mode: " + str(high) + " " + str(value)
	log(result)

	osc.stopAcquisition()
	return ret

def step_5():
	log(createStepHeader(5))
	disable_ref_measurement()

	#/* CH 0 LOW Gain*/
	result = _test_osc_range(0, False)
	if not result:
		disable_ref_measurement()
		return false

	#/* CH 0 HIGH Gain*/
	result = _test_osc_range(0, True)
	if not result:
		disable_ref_measurement()
		return false

	#/* CH 1 LOW Gain*/
	result = _test_osc_range(1, False)
	if not result:
		disable_ref_measurement()
		return false

	#/* CH 1 HIGH Gain*/
	result = _test_osc_range(1, True)
	if not result:
		disable_ref_measurement()
		return false

	_osc_change_gain_mode(0, False)
	_osc_change_gain_mode(1, False)
	disable_ref_measurement()
	return True


#*********************************************************************************************************
#	STEP 6
#*********************************************************************************************************/
#/* Setup and run SIG GEN */
def _awg_output_constant(ch, value):
	global siggen

	siggen.enableChannel(ch, True)
	siggen.setSampleRate(ch, 75000000)
	siggen.setCyclic(True)
	buffer = [value] * 1024
	siggen.push(ch, buffer)
	sleep(0.500)

#/* Read OSC values */
def _osc_read_constant(ch):
	global osc

	osc.enableChannel(ch, True)
	osc.setKernelBuffersCount(1)
	osc.setSampleRate(100000000)
	val = osc.getVoltage(ch)
	#var val = osc.channels[ch].mean
	return val

def _awg_osc_constant(ch, value):
	global siggen

	result = ""
	_awg_output_constant(ch, value)
	ret = False
	#/* busy wait for 10 seconds with 100 milliseconds intervals */
	for i in range (0, 100):
		ret_value = _osc_read_constant(ch)
		if ((ret_value < (value + ADC_CONST_ERR_THRESHOLD)) and (ret_value > (value - ADC_CONST_ERR_THRESHOLD))):
			ret = True
			break
		sleep(0.1)

	if ret:
		result += "PASSED "
	else:
		result += "FAILED "

	result += "channel: " + str(ch) + " "
	result += "output: " + str(value) + " "
	result += "input: " + str(ret_value)

	log(result)
	siggen.stop()
	osc.stopAcquisition()
	return ret

def _test_awg_osc(ch):
	global osc
	ret = True

	# Display and run the OSC
	_osc_change_gain_mode(ch, False)
	if not _awg_osc_constant(ch, 0):
		ret = False

	if not _awg_osc_constant(ch, 2):
		ret = False

	if not _awg_osc_constant(ch, 5):
		ret = False

	osc.stopAcquisition()
	return ret

def step_6():
	log(createStepHeader(6))
	ret = _test_awg_osc(0)
	if not ret:
		return False
	ret = _test_awg_osc(1)
	if not ret:
		return False
	return True


#*********************************************************************************************************
#	STEP 7
#*********************************************************************************************************

def _calibrate_pos_power_supply():
	global pws
	global OFFSET_POS_ADC, OFFSET_POS_DAC
	global GAIN_POS_ADC, GAIN_POS_DAC
	step = 0
	res = ""

	# Pos dac/adc offset calib with 100mV
	pws.enableChannel(0, True)
	pws.pushChannel(0, PWS_POS_FIRST, False)
	# call some shell script which returns the ADC value
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V5B pos false"], universal_newlines = False, stdout = subprocess.PIPE)
	#value = extern.start("sshpass -pjig ssh jig@localhost sudo " + WORKING_DIR + "/m2k_power_calib_meas.sh V5B pos false").trim()
	value = float(value.stdout.decode())
	log("pos " + str(step) + " result: " + str(value))
	if value == '' or value == "failed" or math.isnan(value):
		return False
	OFFSET_POS_DAC = PWS_POS_FIRST - value
	value_m2k = pws.readChannel(0, False)
	OFFSET_POS_ADC = value - value_m2k
	res += str(value) + " "

	step += 1
	# Pos dac/adc gain calib with 4.5V
	pws.pushChannel(0, PWS_POS_SECOND, False)
	# call some shell script which returns the ADC value
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V5B pos false"], universal_newlines = False, stdout = subprocess.PIPE)
	#value = extern.start("sshpass -pjig ssh jig@localhost sudo " + WORKING_DIR + "/m2k_power_calib_meas.sh V5B pos false").trim()
	value = float(value.stdout.decode())
	log("pos " + str(step) + " result: " + str(value))
	if value == '' or value == "failed" or math.isnan(value):
		return False
	GAIN_POS_DAC = PWS_POS_SECOND / (value + OFFSET_POS_DAC)
	value_m2k = pws.readChannel(0, False)
	GAIN_POS_ADC = value / (value_m2k + OFFSET_POS_ADC)
	res += str(value) + " "

	res = "DONE with POSITIVE supply --> voltages: " + res
	log(res)

	pws.pushChannel(0, 0.0, False)
	pws.enableChannel(0, False)
	return True

def _calibrate_neg_power_supply():
	global pws
	global OFFSET_NEG_ADC, OFFSET_NEG_DAC
	global GAIN_NEG_ADC, GAIN_NEG_DAC
	step = 0
	res = ""

	# Neg dac/adc offset calib with -100mV
	pws.enableChannel(1, True)
	pws.pushChannel(1, PWS_NEG_FIRST, False)
	# call some shell script which returns the ADC value
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V6B neg false"], universal_newlines = False, stdout = subprocess.PIPE)
	#value = extern.start("sshpass -pjig ssh jig@localhost sudo " +  WORKING_DIR + "/m2k_power_calib_meas.sh V6B neg false");
	value = float(value.stdout.decode())	
	log("pos " + str(step) + " result: " + str(value))
	if value == '' or value == "failed" or math.isnan(value):
		return False
	OFFSET_NEG_DAC = PWS_NEG_FIRST - value
	value_m2k = pws.readChannel(1, False)
	OFFSET_NEG_ADC = value - value_m2k
	res += str(value) + " "

	step += 1
	# Neg dac/adc gain calib with -4.5V
	pws.pushChannel(1, PWS_NEG_SECOND, False)
	# call some shell script which returns the ADC value
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V6B neg false"], universal_newlines = False, stdout = subprocess.PIPE)
	#value = extern.start("sshpass -pjig ssh jig@localhost sudo " +  WORKING_DIR + "/m2k_power_calib_meas.sh V6B neg false")
	value = float(value.stdout.decode())
	log("pos " + str(step) + " result: " + str(value))
	if value == '' or value == "failed" or math.isnan(value):
		return False
	GAIN_NEG_DAC = PWS_NEG_SECOND / (value + OFFSET_NEG_DAC)
	value_m2k = pws.readChannel(1, False)
	GAIN_NEG_ADC = value / (value_m2k + OFFSET_NEG_ADC)
	res += str(value) + " "

	res = "DONE with NEGATIVE supply --> voltages: " + res
	log(res)

	pws.pushChannel(1, 0.0, False)
	pws.enableChannel(1, False)
	return True

def _write_calib_file():
	global dmm_ad9963, dmm_xadc
	calib_file = open(M2KCALIB_INI_LOCAL, "w")
	now = datetime.now()
	dt_string = now.strftime("%a. %b. %d %Y, %H:%M:%S")

	ad9963_temp = dmm_ad9963.readChannel("temp0").value
	fpga_temp = dmm_xadc.readChannel("temp0").value

	calib_file.write("#Calibration time: " + dt_string + "\n")
	calib_file.write("#ad9963 temperature: " + str(ad9963_temp) + " °C\n")
	calib_file.write("#FPGA temperature: " + str(fpga_temp) + " °C\n")
	calib_file.write("cal,offset_pos_dac=" + str(OFFSET_POS_DAC) + "\n")
	calib_file.write("cal,gain_pos_dac=" + str(GAIN_POS_DAC) + "\n")
	calib_file.write("cal,offset_pos_adc=" + str(OFFSET_POS_ADC) + "\n")
	calib_file.write("cal,gain_pos_adc=" + str(GAIN_POS_ADC) + "\n")
	calib_file.write("cal,offset_neg_dac=" + str(OFFSET_NEG_DAC) + "\n")
	calib_file.write("cal,gain_neg_dac=" + str(GAIN_NEG_DAC) + "\n")
	calib_file.write("cal,offset_neg_adc=" + str(OFFSET_NEG_ADC) + "\n")
	calib_file.write("cal,gain_neg_adc=" + str(GAIN_NEG_ADC) + "\n")

	calib_file.close()

def step_7():
	log(createStepHeader(7))
	ret = _calibrate_pos_power_supply()
	if not ret:
		return False
	log("")
	ret = _calibrate_neg_power_supply()
	if not ret:
		return False

	_write_calib_file()
	ret = subprocess.run(["./scp.sh", M2KCALIB_INI_LOCAL, " root@192.168.2.1:/mnt/jffs2/" + M2KCALIB_INI, " analog"],
		universal_newlines = False, capture_output = True)
	#ret = extern.start("sshpass -pjig ssh jig@localhost sudo " + WORKING_DIR + "/scp.sh " + M2KCALIB_INI_LOCAL + " root@192.168.2.1:/mnt/jffs2/" + M2KCALIB_INI + " analog").trim();

	ret = str(ret.stdout.decode().rstrip('\r\n'))
	subprocess.run(["rm", M2KCALIB_INI_LOCAL])
	if ret != "ok":
		log("Failed to save calibration file to M2k: " + ret)
		return False

	log("Saved calibration parameters to file");
	return True


#*********************************************************************************************************
#	STEP 8
#*********************************************************************************************************
def _reset_DIO():
	global dig
	# Reset all the pins to default (input)
	for i in range (0, 16):
		dig.setDirection(i, libm2k.DIO_INPUT)
		dig.setValueRaw(i, 1)


#/* Set the output to a value and check it with the input
# * true(high), false(low)
# */
def _test_DIO_pair(input, output):
	global dig
	value = False
	result = ""

	# Set the output pin and start it
	dig.setValueRaw(output, value)
	dig.setDirection(output, libm2k.DIO_OUTPUT)

	# Set the input pin
	dig.setDirection(input, libm2k.DIO_INPUT)
	input_val = dig.getValueRaw(input)

	if input_val == value:
		result += "PASSED"
		ret = True
	else:
		result += "FAILED"
		ret = False

	result += "	input: "
	result += str(input)
	result += "	output: "
	result += str(output)
	log(result)
	return ret

def step_8():
	global dig
	log(createStepHeader(8))
	retAll = True
	for i in range(0, 8):
		_reset_DIO()
		ret = _test_DIO_pair(i, i + 8)
		if not ret:
			retAll = False
			#_reset_DIO()
			#return False
		_reset_DIO()
		ret = _test_DIO_pair(i + 8, i)
		if not ret:
			retAll = False
			#_reset_DIO()
			#return False
	_reset_DIO()
	return retAll

#*********************************************************************************************************
#	CONNECTION + UTILS
#*********************************************************************************************************/

def connect():
	global m2k, osc, siggen, pws, dig, dmm_ad9963, dmm_xadc

	ctx_list = libm2k.getAllContexts()
	if (len(ctx_list) == 0):
		log("No usb devices available")
		return False
	m2k = libm2k.m2kOpen()
	if m2k is None:
		log("Can't connect to M2K")
		return False
	m2k.reset()
	m2k.calibrate()
	osc = m2k.getAnalogIn()
	siggen = m2k.getAnalogOut()
	pws = m2k.getPowerSupply()
	dig = m2k.getDigital()
	dmm_ad9963 = m2k.getDMM("ad9963")
	dmm_xadc = m2k.getDMM("xadc")
	return True

def log(message):
	print(message)

def createStepHeader(step):
	msg = ""
	msg += "STEP "
	msg += str(step)
	return msg

def get_now_s():
	now = datetime.now()
	return str(now)

def runTest(step):
	global m2k
	trial_nb = 1
	ret = False
	while (not ret and trial_nb < 4):
		log("Step " + str(step) + " started: " + get_now_s())
		method = eval("step_" + str(step))
		ret = method()
		log("Step " + str(step) + " finished: " + get_now_s() + "\n")

		if not ret:
			if trial_nb != 2:
				log("Restarting step " + str(step))
			else:
				log("Failed " + str(trial_nb) + " times at step " + str(step))
			trial_nb += 1
			m2k.calibrate()

	return ret

def main():
	global m2k
	if not connect():
		raise Exception("Can't connect to an M2k")

	log("Running libm2k " + libm2k.getVersion())
	if SHOW_START_END_TIME:
		log("Script started on: " + get_now_s() + '\n');

	for i in range(5,8):
		if not runTest(i):
			libm2k.contextClose(m2k)
			raise Exception("M2k testing steps failed...")
	log("Done\n")
	if SHOW_START_END_TIME:
		log("Script ended on: " + get_now_s() + '\n')
	libm2k.contextClose(m2k)

main()
