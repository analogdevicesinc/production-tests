import libm2k
import subprocess
import os
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
from multiprocessing import Process, Manager, Value
from scipy import signal as sg
from scipy.stats import pearsonr
import sys

SHOW_TIMESTAMP = True;
SHOW_START_END_TIME = True;
ADC_BANDWIDTH_THRESHOLD = 9;
PWS_POS_FIRST = 0.1;
PWS_POS_SECOND = 4.5;
PWS_NEG_FIRST = -PWS_POS_FIRST;
PWS_NEG_SECOND = -PWS_POS_SECOND;
SHAPE_CORR_THRESHOLD = 0.9997
SHAPE_PHASE_THRESHOLD = 0.8


#*********************************************************************************************************
#	TEST STEP 7 AFTER EJECT and CALIBRATION
#*********************************************************************************************************

def _read_pos_power_supply():
	global pws
	# Pos dac/adc offset calib with 100mV
	pws.enableChannel(0, True)
	pws.pushChannel(0, PWS_POS_FIRST)

	# call some shell script which returns the ADC value
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V5B pos true"], universal_newlines = False, stdout = subprocess.PIPE)
#	value = extern.start("sshpass -pjig ssh jig@localhost sudo $WORKING_DIR/m2k_power_calib_meas.sh V5B pos true");
	value = float(value.stdout.decode())
	log("pos result: " + str(value))

	if value == '' or value == "failed" or math.isnan(value):
		return False

	# Pos dac/adc gain calib with 4.5V
	pws.pushChannel(0, PWS_POS_SECOND)
	# call some shell script which returns the ADC value
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V5B pos true"], universal_newlines = False, stdout = subprocess.PIPE)
	#value = extern.start("sshpass -pjig ssh jig@localhost sudo $WORKING_DIR/m2k_power_calib_meas.sh V5B pos true");
	value = float(value.stdout.decode())
	log("pos result: " + str(value))
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
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V6B neg true"], universal_newlines = False, stdout = subprocess.PIPE)
	#value = extern.start("sshpass -pjig ssh jig@localhost sudo $WORKING_DIR/m2k_power_calib_meas.sh V6B neg true").trim();
	value = float(value.stdout.decode())
	log("neg result: " + str(value))
	if value == '' or value == "failed" or math.isnan(value):
		return False

	# Neg dac/adc gain calib with -4.5V
	pws.pushChannel(1, PWS_NEG_SECOND)
	# call some shell script which returns the ADC value
	value = subprocess.run(["./m2k_power_calib_meas.sh", "V6B neg true"], universal_newlines = False, stdout = subprocess.PIPE)
	#value = extern.start("sshpass -pjig ssh jig@localhost sudo $WORKING_DIR/m2k_power_calib_meas.sh V6B neg true").trim();
	value = float(value.stdout.decode())
	log("neg result: " + str(value))
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
	log("")
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
		_reset_DIO()
		ret = _test_DIO_pair(i + 8, i)
		if not ret:
			retAll = False
	_reset_DIO()
	return retAll


#*********************************************************************************************************
#	STEP 9
#*********************************************************************************************************
# Setup and run SIG GEN
def _awg_output_square(ch, nb_samples, dac_sample_rate, amplitude, offset):
	global siggen, m2k
	siggen.enableChannel(ch, True)
	siggen.setCyclic(True)

	buffer1 = amplitude * np.append(np.linspace(-1,-1,int(nb_samples/2)),np.linspace(1,1,int(nb_samples/2)))

	siggen.setSampleRate(ch, dac_sample_rate)
	m2k.setTimeout(5000)
	try:
		siggen.push(ch, buffer1)
	except:
		m2k.setTimeout(0)
		raise Exception("Timeout occured")
	m2k.setTimeout(0)
	return buffer1

def toggle_relay(pos):
	# set pin4 high to keep ref measurement off
	if pos:
		subprocess.run(["./toggle_pins.sh", " GPIO_EXP1 pin7 pin4"])
	else:
		subprocess.run(["./toggle_pins.sh", " GPIO_EXP1 pin4"])

def plot_graph(ch, nb_samples_per, adc_nb_periods, color, done_trimming, generated_buffer, ch_type):
	global osc
	plt.ion()
	adc_final_nb_samples = nb_samples_per * adc_nb_periods

	# Uncomment to display reference waveform
	'''fig2 = plt.figure()
	gen = plt.subplot(1, 1, 1)
	gen.set_xlabel('Time')
	gen.set_ylabel('Voltage - generated signal')
	gen.set_xlim([0, len(generated_buffer)])
	gen.set_ylim([-3, 3])'''

	fig = plt.figure("CH " + str(ch) + " " + ch_type)
	ax = plt.subplot(1, 1, 1)
	ax.set_xlabel('Samples')
	ax.set_ylabel('Voltage')
	ax.set_xlim([0, adc_final_nb_samples])
	ax.set_ylim([-3, 3])

	x = []
	y = []
	ax.plot(x, y, color = color) #empty line on the plot
	fig.show()

	# Uncomment to display reference waveform
	'''x_gen = np.linspace(0, len(generated_buffer), len(generated_buffer))
	gen.plot(x_gen, generated_buffer, 'b') #empty line on the plot
	fig2.show()'''
	
	while done_trimming.value == 0:
		x = np.linspace(0, adc_final_nb_samples, adc_final_nb_samples)
		y = osc.getSamples(adc_final_nb_samples)[ch]

		shape_ok = _test_shape(y[0:len(generated_buffer)], generated_buffer)
		if shape_ok:
			ax.lines[0].set_color('g')
			ax.set_title('Signal shape: good', loc = 'left', color = 'g')
		else:
			ax.lines[0].set_color('r')
			ax.set_title('Signal shape: bad', loc = 'left', color = 'r')
		ax.lines[0].set_data(x, y)
		fig.canvas.flush_events()
		sleep(0.1)
	osc.stopAcquisition()
	osc.enableChannel(ch, False)
	plt.close()

def _test_shape(input_buffer, generated_buffer):
	corr_shape, _= pearsonr(generated_buffer, input_buffer)
	phase_diff=((math.acos(corr_shape))*180)/np.pi
	#print("Correlation coefficient between square signal and its reference: " +str(corr_shape))
	#print("Phase difference between square signal and its reference:" +str(phase_diff))
	if (corr_shape <= SHAPE_CORR_THRESHOLD or phase_diff > SHAPE_PHASE_THRESHOLD):
		return False
	return True

def _test_osc_trimmer_adjust(ch, positive, color):
	global osc
	trigger = osc.getTrigger()
	nb_samples = 8192
	adc_nb_periods = 3
	dac_sample_rate = 7500000
	adc_sample_rate = 10000000
	adc_nb_samples = int(np.ceil(nb_samples / (dac_sample_rate / adc_sample_rate)))

	# Used to align the first period with the DAC period (influenced by the 0.75 ratio)
	adc_trig_value = int(np.ceil((adc_nb_samples - nb_samples) / 2))
	pressed = ""
	ok = False
	ch_type = "positive"
	continue_button = "pin1"
	ipc_file = "/tmp/" + continue_button + "_pressed"
	done_trimming = False

	trigger.setAnalogSource(ch)
	trigger.setAnalogCondition(ch, libm2k.FALLING_EDGE_ANALOG)
	trigger.setAnalogLevel(ch, 0.0)
	trigger.setAnalogMode(ch, libm2k.ANALOG)
	trigger.setAnalogDelay(adc_trig_value)

	toggle_relay(positive);

	if not positive:
		ch_type = "negative"

	osc.setSampleRate(adc_sample_rate)
	osc.setRange(ch, -2.5, 2.5)
	osc.enableChannel(ch, True)
	while not ok:
		#Start the SIG GEN
		try:
			generated_buffer = _awg_output_square(ch, nb_samples, dac_sample_rate, 2, 0);
		except:
			log("Error: DAC Timeout occured")
			siggen.stop(ch)
			return False

		#Display and run the OSC
		subprocess.run(["rm", "-f", ipc_file])
	
		done_trimming = Value('i', 0)
		plot_process = Process(target=plot_graph, args=(ch, adc_nb_samples, adc_nb_periods, 
					color, done_trimming, generated_buffer, ch_type))
		plot_process.start()

		command = "./wait_pins.sh D pin1 ; echo pressed > " + ipc_file + " &"
		waiting_process = subprocess.Popen(command, stdout = subprocess.PIPE, shell=True)

		while pressed != "pressed":
			if not os.path.exists(ipc_file):
				continue
			tmp = open(ipc_file, "r")
			pressed = tmp.readline().strip()
			tmp.close()

		# Join the btn waiting background proc
		waiting_process.wait()
		
		# Remove btn dummy file
		subprocess.run(["rm", "-f", ipc_file])
		
		# Signal the plot process to finish its job
		done_trimming.value = 1
		# Join the plot process and close the window
		plot_process.join()
		
		ok = True;
		pressed = "";

		siggen.stop(ch)
		ret = ok
	return ret

def step_9():
	log(createStepHeader(9))
	# CH 0 Positive
	result = _test_osc_trimmer_adjust(0, True, 'blue');
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
	result = _test_osc_trimmer_adjust(1, True, 'green')

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
	siggen.setSampleRate(ch, samp_rate)
	siggen.push(ch, buffer1)

def _spectrum_setup_channel(ch, test_sig_frequency, fs):
	global osc

	scaling_factor = osc.getScalingFactor(ch)
	N = 8192
	NFFT = N // 2

	# Low range
	osc.setRange(ch, -25, 25)
	osc.enableChannel(ch, True)
	osc.setSampleRate(fs)

	m2k.setTimeout(5000)
	try:
		a = osc.getSamplesRaw(N)[ch]
	except:
		m2k.setTimeout(0)
		raise Exception("Timeout occured")
	m2k.setTimeout(0)

	# Convert raw values to volts (for debug and display only)
	b = list(a)
	for i in range(0, N):
		b[i] = b[i] * scaling_factor

	# Uncomment the following to use the plots for debugging
	'''fig, ax = plt.subplots(3)'''

	sp_data = np.fft.fft(a, N)
	freq = np.arange(NFFT + 1) / (float(N) / fs)

	# Scale the magnitude of FFT by window(None) and factor of 2,
	# because we are using half of FFT spectrum.
	sp_data = np.abs(sp_data)[0:NFFT+1]
	sp_data = sp_data * 2 / N
	sp_data = 10 * np.log10(sp_data / 32768)

	# Uncomment the following to use the plots for debugging
	'''ax[0].plot(freq, sp_data, 'b')
	ax[1].plot(a)
	ax[2].plot(b)'''

	# Determine the db value for the test_sig_frequency
	# We choose the max db value from the 2 values that are closest to test_sig_frequency
	# freqs_gt contains the index of all the frequency values >= test_sig_frequency
	freqs_gt = np.where(freq >= test_sig_frequency)
	marker_1 = freq[freqs_gt[0][0] - 1]
	marker_2 = freq[freqs_gt[0][0]]
	peak_marker_1 = sp_data[freqs_gt[0][0]]
	peak_marker_2 = sp_data[freqs_gt[0][0] - 1]

	# Uncomment the following to use the plots for debugging
	'''plt.show()'''
	return max(peak_marker_1, peak_marker_2)

def _compute_adc_bandwidth(ch):
	global osc, siggen
	db_1 = 0
	db_2 = 0
	freq_1 = 10000
	freq_2 = 30000000
	adc_freq_1 = 1000000
	adc_freq_2 = 100000000

	try:
		_awg_output_sine(ch, freq_1, 2, 0)
		db_1 = _spectrum_setup_channel(ch, freq_1, adc_freq_1)
		siggen.stop()
		osc.stopAcquisition()

		_awg_output_sine(ch, freq_2, 2, 0)
		db_2 = _spectrum_setup_channel(ch, freq_2, adc_freq_2)
		siggen.stop()
		osc.stopAcquisition()
	except:
		log("Error: Timeout occured")
		siggen.stop()
		osc.stopAcquisition()
		return False
	
	diff = db_1 - db_2
	log("db_1: " + str(db_1) + " db_2: " + str(db_2))
	log("channel: " + str(ch) + " diff dB: " + str(diff))

	if (diff > ADC_BANDWIDTH_THRESHOLD) or (diff < 0):
		log("Error: dB difference is too big")
		return False
	return True

def _spectrum_setup_trigger():
	global osc
	trigger = osc.getTrigger()
	trigger.setAnalogDelay(0)
	trigger.setAnalogMode(0, libm2k.ALWAYS)
	trigger.setAnalogMode(1, libm2k.ALWAYS)

def step_10():
	global m2k
	log(createStepHeader(10))

	m2k.calibrate()
	osc.setKernelBuffersCount(1)

	# Disable the triggers setup during the previous step
	_spectrum_setup_trigger()

	osc.enableChannel(0, False)
	osc.enableChannel(1, False)
	ret = _compute_adc_bandwidth(0)
	if not ret:
		return False

	osc.enableChannel(0, False)
	osc.enableChannel(1, False)
	ret = _compute_adc_bandwidth(1)
	if not ret:
		return False
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
	m2k = libm2k.m2kOpen()
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
	global m2k, osc
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
			osc.setKernelBuffersCount(1)

	return ret

def main():
	global m2k
	sys.tracebacklimit = 0
	if not connect():
		raise Exception("ERROR: Can't connect to an M2k")
	if SHOW_START_END_TIME:
		log("Script started on: " + get_now_s() + '\n');

	for i in range(7, 11):
		if not runTest(i):
			libm2k.contextClose(m2k)
			raise ValueError("ERROR: M2k testing steps failed at step " + str(i) + "...")
	log("\nDone\n")
	if SHOW_START_END_TIME:
		log("Script ended on: " + get_now_s() + '\n')
	libm2k.contextClose(m2k)

main()
