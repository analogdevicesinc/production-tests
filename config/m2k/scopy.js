#!/usr/bin/scopy -s

var SHOW_TIMESTAMP = true;
var SHOW_START_END_TIME = true;
var MAX_HIGH_GAIN = 2.525;
var MIN_HIGH_GAIN = 2.475;
var MAX_LOW_GAIN = 10.25;
var MIN_LOW_GAIN = 9.75;
var ADC_CONST_ERR_THRESHOLD = 0.03;
var ADC_BANDWIDTH_THRESHOLD = 7;
var WORKING_DIR = ".";
var M2KCALIB_INI = "/media/jig/M2k/m2k-calib.ini";

/*********************************************************************************************************
*	STEP 5
/*********************************************************************************************************/
function _osc_change_gain_mode(ch, high)
{
	osc.channels[ch].enabled = true;
	if (!high) {
		osc.channels[ch].volts_per_div = 1;
	} else {
		osc.channels[ch].volts_per_div = 0.5;
	}
	msleep(2000);
}

function _osc_check_range(high, value)
{
	if (high) {
		if ((value < MAX_HIGH_GAIN) && (value > MIN_HIGH_GAIN)) {
			return true;
		} else {
			return false;
		}
	} else {
		if ((value < MAX_LOW_GAIN) && (value > MIN_LOW_GAIN)) {
			return true;
		} else {
			return false;
		}
	}
}

function disable_ref_measurement()
{
	extern.start("./ref_measure_ctl.sh disable");
}

function _test_osc_range(ch, high)
{
	var result = "";
	var value;
	var ret;
	var output;

	if (high) {
		output = extern.start("./ref_measure_ctl.sh ref2.5v");
	} else {
		output = extern.start("./ref_measure_ctl.sh ref10v");
	}

	msleep(2500);

	osc.running = true;

	_osc_change_gain_mode(ch, high);
	value = _osc_read_constant(ch);
	ret = _osc_check_range(high, value);
	if (ret) {
		result += "PASSED ";
	} else {
		result += "FAILED ";
	}
	result += " channel: " +  ch + " high-mode: " + high + " " + value;
	log(result); 
	osc.running = false;	
	return ret;
}

function step_5()
{
	log(createStepHeader(5));
	var result, ret;

	disable_ref_measurement();

	/* CH 0 LOW Gain*/
	result = _test_osc_range(0, false);
	if (!result) {
		disable_ref_measurement();
		//handle this
		return false;
	}
	
	/* CH 0 HIGH Gain*/
	result = _test_osc_range(0, true);
	if (!result) {
		disable_ref_measurement();
		//handle this
		return false;
	}
	
	/* CH 1 LOW Gain*/
	result = _test_osc_range(1, false);
	if (!result) {
		disable_ref_measurement();
		//handle this
		return false;
	}
	
	/* CH 1 HIGH Gain*/
	result = _test_osc_range(1, true);
	if (!result) {
		disable_ref_measurement();
		//handle this
		return false;
	}
	_osc_change_gain_mode(0, false);
	_osc_change_gain_mode(1, false);
	disable_ref_measurement();
	return true;
	
}


/*********************************************************************************************************
*	STEP 6
/*********************************************************************************************************/

/* Setup and run SIG GEN */
function _awg_output_constant(ch, value)
{
	if (siggen.running == true) {
		siggen.running = false;
	}
	siggen.enabled[ch] = true;
	siggen.mode[ch] = 0;
	siggen.constant_volts[ch] = value;
	siggen.running = true;
	msleep(1500);
}

/* Read OSC values */
function _osc_read_constant(ch)
{
	osc.channels[ch].enabled = true;
	osc.time_base = 0.000001;
	
	var val = osc.channels[ch].mean;
	return val;
}

function _awg_osc_constant(ch, value)
{
	var ret;
	var result = "";
	_awg_output_constant(ch, value);
	var ret_value = _osc_read_constant(ch);

	if ((ret_value < (value + ADC_CONST_ERR_THRESHOLD)) && (ret_value > (value - ADC_CONST_ERR_THRESHOLD))) {
		ret = true;
	} else {
		ret = false;
	}

	if (ret) {
		result += "PASSED ";
	} else {
		result += "FAILED ";
	}
	result += "channel: " + ch + " ";
	result += "output: " + value + " ";
	result += "input: " + ret_value;
	
	log(result);
	
	siggen.running = false;	

	return ret;
}

function _test_awg_osc(ch)
{
	var ret = true;
	
	/* Display and run the OSC */
	osc.show();
	_osc_change_gain_mode(ch, false);
	osc.running = true;
	
	if (!_awg_osc_constant(ch, 0)) {
		ret = false;
	}
	
	if (!_awg_osc_constant(ch, 2)) {
		ret = false;
	}

	if (!_awg_osc_constant(ch, 5)) {
		ret = false;
	}
	
	osc.running = false;
	return ret;
}

function step_6()
{
	log(createStepHeader(6));
	var ret;
	ret = _test_awg_osc(0);
	if (!ret) {
		return false;
	}
	ret = _test_awg_osc(1);
	if (!ret) {
		return false;
	}
	return true;
}


/*********************************************************************************************************
*	STEP 7
/*********************************************************************************************************/

function _calibrate_pos_power_supply()
{
	var value, ok, next_calib;
	var nb_steps = manual_calib.start(0);
	var step = 0;
	var next_step = step + 1;
	var res = "";
	
	while (next_step > 0) {
		// call some shell script which returns the ADC value
		value = extern.start("./measure.sh V5B");
		ok = manual_calib.setParam(value);
		next_step = manual_calib.next();
		step++;
		res += value + " ";
	}
	
	if (next_step < 0) {
		next_calib = manual_calib.finish();
	}
	res = "DONE - pos supply " + res;
	log(res);
}

function _calibrate_neg_power_supply()
{
	var value, ok, next_calib;
	var nb_steps = manual_calib.start(1);
	var step = 0;
	var next_step = step + 1;
	var res = "";
	
	while (next_step > 0) {
		// call some shell script which returns the ADC value
		value = extern.start("./measure.sh V6B");
		ok = manual_calib.setParam(value);
		next_step = manual_calib.next();
		step++;
		res += value + " ";
	}
	
	if (next_step < 0) {
		next_calib = manual_calib.finish();
	}
	res = "DONE - neg supply " + res;
	log(res);
}

function step_7()
{
	log(createStepHeader(7));
	_calibrate_pos_power_supply();
	_calibrate_neg_power_supply();
	manual_calib.start(2);
	var ok = manual_calib.saveCalibration(M2KCALIB_INI);
	log("Saved calibration parameters to file");
	if (!ok) {
		printToConsole("Could not save the params on the board");
	}
	return ok;
}


/*********************************************************************************************************
*	STEP 8
/*********************************************************************************************************/
function _reset_DIO() 
{
	/* Stop the instrument before resetting the pins */
	if (dio.running == true) {
		dio.running = false;
	}
	/* Reset all the pins to default (input) */
	for (var i = 0; i < 16; i++) {
		dio.out[i] = false; // low
		dio.dir[i] = false; // input
	}
}


/* Set the output to a value and check it with the input 
 * true(high), false(low)	
 */
function _test_DIO_pair(input, output)
{
	var value = false;
	var result = "";
	var ret;

	/* Stop the instrument before resetting the pins */
	if (dio.running == true) {
		dio.running = false;
	}

	// Set the output pin
	dio.dir[output] = true;
	dio.out[output] = value;

	// Start the instrument
	dio.running = true;
	
	// Set the input pin
	dio.dir[input] = false;
	var input_val = dio.gpi[input];

	if (input_val == value) {
		result += "PASSED";
		ret = true;
	} else {
		result += "FAILED";
		ret = false;
	}

	result += "	input: ";
	result += input;
	result += "	output: ";
	result += output;
	log(result);

	return ret;
}

function step_8()
{
	log(createStepHeader(8));
	for (var i = 0; i < 8; i++) {
		_reset_DIO();
		ret = _test_DIO_pair(i, i + 8);
		if (!ret) {
			dio.running = false;
			return false;
		}
		_reset_DIO();
		ret = _test_DIO_pair(i + 8, i);
		if (!ret) {
			dio.running = false;		
			return false;
		}
	}
	dio.running = false;
	return true;
}


/*********************************************************************************************************
*	STEP 9
/*********************************************************************************************************/

/* Setup and run SIG GEN */
function _awg_output_square(ch, frequency, amplitude, offset)
{
	if (siggen.running == true) {
		siggen.running = false;
	}
	siggen.enabled[ch] = true;
	siggen.mode[ch] = 1;
	siggen.waveform_type[ch] = 1;
	siggen.waveform_frequency[ch] = frequency;
	siggen.waveform_amplitude[ch] = amplitude;
	siggen.waveform_offset[ch] = offset;
	siggen.running = true;
	msleep(500);
}

function toggle_relay(pos)
{
	/* set pin4 high to keep ref measurement off */
	if (pos)
		return extern.start("./toggle_pins.sh GPIO_EXP1 pin7 pin4");
	else
		return extern.start("./toggle_pins.sh GPIO_EXP1 pin4");
}

function _test_osc_trimmer_adjust(ch, positive)
{
	var input = "";
	var ok = false;
	var ret;
	var ch_type = "positive";

	osc.internal_trigger = true;
	osc.trigger_source = ch;
	osc.internal_condition = 0;
	toggle_relay(positive);

	if (!positive) {
		ch_type = "negative";
	}

	while (!ok) {
		/* Start the SIG GEN */
		_awg_output_square(ch, 1000, 2, 0);
	
		/* Display and run the OSC */
		osc.show();
		_osc_change_gain_mode(ch, true);
		osc.time_base = 0.0001;
		osc.running = true;

		while (input != "OK" && input != "ok") {
			input = readFromConsole("Adjust the trimmers for channel " + ch + " " + ch_type + ", then type OK");
		}

		if (input == "OK" || input == "ok") {
			input = readFromConsole("Are you sure? (y/n)");
			if (input == "Y" || input == "y") {
				ok = true;
			} else {
				ok = false;
			}
		}
		osc.running = false;
		siggen.running = false;
		_osc_change_gain_mode(ch, false);
		osc.channels[ch].enabled = false;
		ret = ok;
	}
	return ret;
}

function step_9()
{
	log(createStepHeader(9));
	var result, ret;
	/* CH 0 Positive*/
	// call some shell script which switches something
	result = _test_osc_trimmer_adjust(0, true);
	if (!result) {
		//handle this
		return false;
	}
	
	/* CH 0 Negative*/
	// call some shell script which switches something
	result = _test_osc_trimmer_adjust(0, false);
	if (!result) {
		//handle this
		return false;
	}
	
	/* CH 1 Positive*/
	// call some shell script which switches something
	result = _test_osc_trimmer_adjust(1, true);
	if (!result) {
		//handle this
		return false;
	}
	
	/* CH 1 Negative*/
	// call some shell script which switches something
	result = _test_osc_trimmer_adjust(1, false);
	if (!result) {
		//handle this
		return false;
	}
	return true;
}


/*********************************************************************************************************
*	STEP 10 - OSC bandwidth
/*********************************************************************************************************/

function _awg_output_sine(ch, frequency, amplitude, offset)
{
	if (siggen.running == true) {
		siggen.running = false;
	}
	siggen.enabled[ch] = true;
	siggen.mode[ch] = 1;
	siggen.waveform_type[ch] = 0;
	siggen.waveform_frequency[ch] = frequency;
	siggen.waveform_amplitude[ch] = amplitude;
	siggen.waveform_offset[ch] = offset;
	siggen.running = true;
	msleep(500);
}

function _spectrum_setup_general()
{
	spectrum.channels[0].enabled = true;
	spectrum.channels[1].enabled = true;
	spectrum.startFreq = 0;
	spectrum.stopFreq = 5E+7;
	spectrum.topScale = 0;
	spectrum.range = 200;
	spectrum.running = true;
}

function _spectrum_setup_marker(ch, frequency)
{
	var idx = ch * 5;
	if (ch != spectrum.markers[idx].chId) {
		return 0;
	}
	spectrum.markers[idx].en = true;
	spectrum.markers[idx].type = 0;
	spectrum.markers[idx].freq = frequency;
	return spectrum.markers[idx].magnitude;	
}

function _compute_adc_bandwidth(ch)
{
	var db_1, db_2;
	var freq_1 = 10000;
	var freq_2 = 30000000;
	
	_spectrum_setup_general();
	
	_awg_output_sine(ch, freq_1, 2, 0);
	db_1 = _spectrum_setup_marker(ch, freq_1);
	
	_awg_output_sine(ch, freq_2, 2, 0);
	db_2 = _spectrum_setup_marker(ch, freq_2);
	
	var diff = db_1 - db_2;
	log("channel: " + ch + " diff dB: " + diff);
	if ((diff > ADC_BANDWIDTH_THRESHOLD) || (diff < 0)) {
		log("Error: dB difference is too big");
		spectrum.running = false;
		siggen.running = false;
		return false;
	}

	spectrum.running = false;
	siggen.running = false;
	return true;
}

function step_10()
{
	log(createStepHeader(10));
	var ret;
	ret = _compute_adc_bandwidth(0);
	if (!ret) {
		return false;
	}
	ret = _compute_adc_bandwidth(1);
	if (!ret) {
		return false;
	}
	return true;
}


/*********************************************************************************************************
*	CONNECTION + UTILS
/*********************************************************************************************************/

function connectToUSB(host)
{
	log("Connecting to " + host + "...")
	var success = launcher.connect(host)

	if (success)
		log("Connected!")
	else
        	log("Failed to connect to: " + host + "!")

	return success;
}

function connect()
{
	var usb_devs = launcher.usb_uri_list();
	var usb_uri = usb_devs[0];
	if (usb_uri) {
        	var connected = connectToUSB(usb_uri);
        	if (!connected)
            		return false;
    	} else {
        	log("No usb devices available");
        	return false;
    	}
	return true;
}

function log(message) {
	printToConsole(message);
}

function createStepHeader(step)
{
	var str = "";
	str += "STEP ";
	str += step;
	return str;
}

function enableExternScripts()
{
	/* Enable external scripts */
	launcher.debugger = true;
	var ret = launcher.enableExtern(true);
	if (!ret) {
		log("Error: can't run external scripts");
		return Error();
	}
	extern.setProcessTimeout(0);
}

function enableCalibScripts()
{
	/* Enable manual calibration scripts */
	launcher.manual_calibration = true;
	var ret = launcher.enableCalibScript(true);
	if (!ret) {
		log("Error: can't run manual calibration scripts");
		return Error();
	}
}

function get_now_s()
{
	var date = new Date();
	return date.toTimeString();
}

function runTest(step)
{
	var trial_nb = 1;
	var ret = false;
	while (!ret && trial_nb < 4) {
		log("Step " + step + " started: " + get_now_s());

		ret = eval("step_" + step + "();");

		log("Step " + step + " finished: " + get_now_s());

		if (!ret) {
			if (trial_nb != 2) {
				log("Restarting step " + step);
			} else {
				log("Failed " + trial_nb + " times at step " + step);				
			}
			trial_nb++;
			manual_calib.autoCalibration();
		}
	}
	return ret;
}

function main()
{
	var i;

	if (!connect())      
		return Error()

	enableExternScripts();
	enableCalibScripts();
	extern.setWorkingDir(WORKING_DIR);
	extern.setProcessTimeout(0);

	if (SHOW_START_END_TIME)
		log("Script started on: " + get_now_s() + '\n');

	for (i = 5; i <= 10; i++) {
		if (!runTest(i)) {
			return Error();
		}
	}

	log("\nDone\n");
	if (SHOW_START_END_TIME) {
		log("Script ended on: " + get_now_s() + '\n')
	}
}
main()
