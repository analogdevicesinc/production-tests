import libm2k
import subprocess
from time import sleep
import math
import numpy as np
from datetime import datetime
from numpy.fft import fft, fftshift
from numpy import array
import matplotlib as mlt
mlt.use('tkagg')
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from sine_gen import sine_buffer_generator
from multiprocessing import Process
from scipy import signal as sg

SHOW_TIMESTAMP = True;
SHOW_START_END_TIME = True;
ADC_BANDWIDTH_THRESHOLD = 9;
WORKING_DIR = "~/plutosdr-m2k-production-test-V2";
PWS_POS_FIRST = 0.1;
PWS_POS_SECOND = 4.5;
PWS_NEG_FIRST = -PWS_POS_FIRST;
PWS_NEG_SECOND = -PWS_POS_SECOND;

#*********************************************************************************************************
#	TEST STEP 7 AFTER EJECT and CALIBRATION
#*********************************************************************************************************

def _read_pos_power_supply():
	global pws
	# Pos dac/adc offset calib with 100mV
	pws.enableChannel(0, True)
	pws.pushChannel(0, PWS_POS_FIRST)

	# call some shell script which returns the ADC value
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V5B pos true"])
#	value = extern.start("sshpass -pjig ssh jig@localhost sudo $WORKING_DIR/m2k_power_calib_meas.sh V5B pos true");
	log("pos result: " + value)

	if value == '' or value == "failed" or math.isnan(value):
		return False

	# Pos dac/adc gain calib with 4.5V
	pws.pushChannel(0, PWS_POS_SECOND)
	# call some shell script which returns the ADC value
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V5B pos true"])
	#value = extern.start("sshpass -pjig ssh jig@localhost sudo $WORKING_DIR/m2k_power_calib_meas.sh V5B pos true");
	log("pos result: " + value)
	if value == '' or value == "failed" or math.isnan(value):
		return False

	pws.pushChannel(0, 0.0)
	pws.enableChannel(0, False)
	return True

def _read_neg_power_supply():
	global pws
	# Neg dac/adc offset calib with -100mV
	pws.enableChannel(1, True)
	pws.pushChannel(1, PWS_NEG_FIRST)
	# call some shell script which returns the ADC value
	######### TODO use check_output for output retrieval
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V6B neg true"])
	#value = extern.start("sshpass -pjig ssh jig@localhost sudo $WORKING_DIR/m2k_power_calib_meas.sh V6B neg true").trim();
	log("neg result: " + value)
	if value == '' or value == "failed" or math.isnan(value):
		return False

	# Neg dac/adc gain calib with -4.5V
	pws.pushChannel(1, PWS_NEG_SECOND)
	# call some shell script which returns the ADC value
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V6B neg true"])
	#value = extern.start("sshpass -pjig ssh jig@localhost sudo $WORKING_DIR/m2k_power_calib_meas.sh V6B neg true").trim();
	log("neg result: " + value);
	if value == '' or value == "failed" or math.isnan(value):
		return False

	pws.pushChannel(1, 0.0)
	pws.enableChannel(1, False)
	return True

def step_7():
	log(createStepHeader(7))
	ret = _read_pos_power_supply()
	if not ret:
		return False
	log("\n")
	ret = _read_neg_power_supply()
	if not ret:
		return False;
	return True;


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
#	STEP 9
#*********************************************************************************************************
# Setup and run SIG GEN
def _awg_output_square(ch, frequency, amplitude, offset):
	global siggen
	nb_samples = 8192
	square_signals = []
	samp_rate = 75000000

	siggen.enableChannel(ch, True)
	siggen.setCyclic(True)

	time = np.linspace(0, 2, 1000)
	buffer1 = amplitude * sg.square(2 *np.pi * frequency * time, duty=0.5)
	siggen.setSampleRate(ch, samp_rate)
	siggen.push(ch, buffer1)
	#sleep(0.200);

def toggle_relay(pos):
	# set pin4 high to keep ref measurement off
	if pos:
		subprocess.run(["./toggle_pins.sh", " GPIO_EXP1 pin7 pin4"])
	else:
		subprocess.run(["./toggle_pins.sh", " GPIO_EXP1 pin4"])

def func_animate(i, ch, nb_samples):
	global osc, plt_line
	x = np.linspace(0, nb_samples, nb_samples)
	y = osc.getSamples(nb_samples)[ch]
	plt_line.set_data(x, y)
	return plt_line,

def plot_graph(ch, nb_samples, color):
	global plt_line, figure
	x = []
	y = []
	figure, ax = plt.subplots(figsize=(4,3))
	plt_line, = ax.plot(x, y, c = color)
	plt.axis([0, nb_samples, -3, 3])

	ani = FuncAnimation(figure, func_animate, fargs=(ch, nb_samples, ), frames=10, interval=50)
	plt.show()

def _test_osc_trimmer_adjust(ch, positive, color):
	global osc, plt_line, figure
	trigger = osc.getTrigger()
	nb_samples = 4096
	pressed = ""
	ok = False
	ch_type = "positive"
	#FIXME: change this to something else if needed
	continue_button = "pin1"
	ipc_file = "/tmp/" + continue_button + "_pressed"

	trigger.setAnalogSource(ch)
	trigger.setAnalogCondition(ch, libm2k.RISING_EDGE_ANALOG)
	trigger.setAnalogLevel(ch, 0.0)
	trigger.setAnalogMode(ch, libm2k.ANALOG)
	trigger.setAnalogDelay(int(-nb_samples/2))

	toggle_relay(positive);

	if not positive:
		ch_type = "negative"

	osc.setSampleRate(100000000)
	osc.setRange(ch, -2.5, 2.5)
	osc.enableChannel(ch, True)
	while not ok:
		#Start the SIG GEN
		_awg_output_square(ch, 1000, 2, 0);

		#Display and run the OSC
		subprocess.run(["rm", ipc_file])
		subprocess.run(["./wait_pins.sh", " D pin1 ; echo pressed > " +
			ipc_file + " ) &"])

		p = Process(target=plot_graph, args=(ch, nb_samples, color, ))
		p.start()
		while pressed != "pressed":
			tmp = open(ipc_file, "r")
			pressed = tmp.readline().strip()
			tmp.close()
		#subprocess.run(["rm", ipc_file])
		p.join()
		#TODO close the plot window
		ok = True;
		pressed = "";

		osc.stopAcquisition()
		siggen.stop()
		osc.enableChannel(ch, False)
		ret = ok
	return ret

def step_9():
	log(createStepHeader(9))
	# CH 0 Positive
	result = _test_osc_trimmer_adjust(0, True, 'red');
	if not result:
		return False

	#CH 0 Negative
	result = _test_osc_trimmer_adjust(0, False, 'blue');
	if not result:
		return False

	#CH 1 Positive
	result = _test_osc_trimmer_adjust(1, False, 'green');
	if not result:
		return False

	#CH 1 Negative
	result = _test_osc_trimmer_adjust(1, True, 'purple')
	if not result:
		return False
	return True


#*********************************************************************************************************
#	STEP 10 - OSC bandwidth
#*********************************************************************************************************

def _awg_output_sine(ch, frequency, amplitude, offset):
	global siggen

	siggen.enableChannel(ch, True)
	siggen.setCyclic(True)
	samp_rate, buffer1 = sine_buffer_generator(ch, frequency, amplitude, offset, 0)
	print("SAMP rate " + str(samp_rate))
	siggen.setSampleRate(ch, samp_rate)
	siggen.push(ch, buffer1)

def _spectrum_setup_general():
	global osc

	fs = 100000000
	N = 8192
	NFFT = N // 2

	osc.setKernelBuffersCount(1)
	osc.enableChannel(0, True)
	osc.enableChannel(1, True)
	osc.setSampleRate(fs)

	#f = float(fs) / 2 * np.linspace(0, 1, NFFT)  # array to x ticks
	a = osc.getSamplesRaw(N)[0] 	#RAW or VOLTS

	fig, ax = plt.subplots(nrows = 1, ncols = 1)

	sp_data = np.fft.fft(a, N)
	fVals = np.linspace(0, fs, N)

	sp_data = np.abs(sp_data)[:NFFT]# * 1 / N#[0 : np.int(NFFT)])
	sp_data = 10 * np.log10(sp_data / (2048 * 2048) )

	ax.plot(fVals[:NFFT], sp_data, 'b')
	plt.show()

def _spectrum_setup_marker(ch, frequency):
	global osc
	#idx = ch * 5
	#if (ch != spectrum.markers[idx].chId) {
	#	return 0;
	#}
	#spectrum.markers[idx].en = true;
	#spectrum.markers[idx].type = 0;
	#spectrum.markers[idx].freq = frequency;
	#return spectrum.markers[idx].magnitude;

def _compute_adc_bandwidth(ch):
	global osc, siggen
	db_1 = 10
	db_2 = 20
	freq_1 = 10000
	freq_2 = 30000000

	#_awg_output_sine(ch, freq_1, 2, 0)
	#db_1 = _spectrum_setup_marker(ch, freq_1);

	_awg_output_sine(ch, freq_2, 2, 0)
	#db_2 = _spectrum_setup_marker(ch, freq_2);

	_spectrum_setup_general()

	diff = db_1 - db_2
	log("channel: " + str(ch) + " diff dB: " + str(diff))
	osc.stopAcquisition()
	siggen.stop()

	if (diff > ADC_BANDWIDTH_THRESHOLD) or (diff < 0):
		log("Error: dB difference is too big")
		return False
	return True

def step_10():
	global m2k
	log(createStepHeader(10))
	m2k.calibrate()

	ret = _compute_adc_bandwidth(0)
	if not ret:
		return False

	#ret = _compute_adc_bandwidth(1)
	#if not ret:
#		return False
	return True


#*********************************************************************************************************
#	CONNECTION + UTILS
#*********************************************************************************************************/

def connect():
	global m2k, osc, siggen, pws, dig

	ctx_list = libm2k.getAllContexts()
	if (len(ctx_list) == 0):
		log("No usb devices available")
		return False
	m2k = libm2k.m2kOpen("usb:1.6.5")
	if m2k is None:
		log("Can't connect to M2K")
		return False
	m2k.calibrate()
	osc = m2k.getAnalogIn()
	siggen = m2k.getAnalogOut()
	pws = m2k.getPowerSupply()
	dig = m2k.getDigital()
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
	if SHOW_START_END_TIME:
		log("Script started on: " + get_now_s() + '\n');

	for i in range(10,11):
		if not runTest(i):
			libm2k.contextClose(m2k)
			raise Exception("M2k testing steps failed...")
	log("\nDone\n")
	if SHOW_START_END_TIME:
		log("Script ended on: " + get_now_s() + '\n')
	libm2k.contextClose(m2k)

main()
