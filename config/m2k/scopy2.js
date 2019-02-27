#!/usr/bin/scopy -s

var SHOW_TIMESTAMP = true;
var SHOW_START_END_TIME = true;
var ADC_BANDWIDTH_THRESHOLD = 7;
var WORKING_DIR = ".";

function _osc_change_gain_mode(ch, high)
{
	osc.channels[ch].enabled = true;
	if (!high) {
		osc.channels[ch].volts_per_div = 1;
	} else {
		osc.channels[ch].volts_per_div = 0.5;
	}
}

/*********************************************************************************************************
*	TEST STEP 7 AFTER EJECT and CALIBRATION
/*********************************************************************************************************/

function _read_pos_power_supply()
{
	var value;

	power.dac1_value=0.100;
	power.dac1_enabled=true;
	value = extern.start("./m2k_power_calib_meas.sh V5B pos true").trim();
	log("pos result: " + value);
	if (value == '' || value == "failed" || isNaN(value))
		return false;

	power.dac1_value=4.5;
	power.dac1_enabled=true;
	value = extern.start("./m2k_power_calib_meas.sh V5B pos true").trim();
	log("pos result: " + value);
	if (value == '' || value == "failed" || isNaN(value))
		return false;

	power.dac1_enabled=false;
	return true;
}

function _read_neg_power_supply()
{
	var value;
	power.dac2_value=-0.100;
	power.dac2_enabled=true;
	value = extern.start("./m2k_power_calib_meas.sh V6B neg true").trim();
	log("neg result: " + value);
	if (value == '' || value == "failed" || isNaN(value))
		return false;

	power.dac2_value=-4.5;
	power.dac2_enabled=true;
	value = extern.start("./m2k_power_calib_meas.sh V6B neg true").trim();
	log("neg result: " + value);
	if (value == '' || value == "failed" || isNaN(value))
		return false;

	power.dac2_enabled=false;
	return true;
}

function step_7()
{
	var ret;
	log(createStepHeader(7));
	ret = _read_pos_power_supply();
	if (!ret)
		return false;
	log("\n");
	ret = _read_neg_power_supply();
	if (!ret)
		return false;
	return true;
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
	/* FIXME: change this to something else if needed */
	var continue_button = "pin1";
	var ipc_file = "/tmp/" + continue_button + "_pressed";

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

		extern.start("rm -rf " + ipc_file);
		/* Some simple stupid IPC */
		extern.start("( ./wait_pins.sh D pin1 ; echo pressed > " +
			ipc_file + " ) &");

		while (input.trim() != "pressed") {
			input = extern.start("cat " + ipc_file);
			msleep(200);
		}
		extern.start("rm -rf " + ipc_file);
		ok = true;
		input = "";

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
	_osc_change_gain_mode(0, true);
	_osc_change_gain_mode(1, true);
	/* CH 0 Positive*/
	// call some shell script which switches something
	osc.channels[0].setColor(230,6,6);
	result = _test_osc_trimmer_adjust(0, true);
	if (!result) {
		//handle this
		return false;
	}
	
	/* CH 0 Negative*/
	// call some shell script which switches something
	osc.channels[0].setColor(13,218,54);
	result = _test_osc_trimmer_adjust(0, false);
	if (!result) {
		//handle this
		return false;
	}
	
	/* CH 1 Positive*/
	// call some shell script which switches something
	osc.channels[1].setColor(197,218,13);
	result = _test_osc_trimmer_adjust(1, false);
	if (!result) {
		//handle this
		return false;
	}
	
	/* CH 1 Negative*/
	// call some shell script which switches something
	osc.channels[1].setColor(140,135,200);
	result = _test_osc_trimmer_adjust(1, true);
	if (!result) {
		//handle this
		return false;
	}
	launcher.hidden = true;
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

	manual_calib.autoCalibration();

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

		log("Step " + step + " finished: " + get_now_s() + "\n");

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

	launcher.maximized = true;

	if (!connect())      
		return Error()

	enableExternScripts();
	enableCalibScripts();
	extern.setWorkingDir(WORKING_DIR);
	extern.setProcessTimeout(0);

	if (SHOW_START_END_TIME)
		log("Script started on: " + get_now_s() + '\n');

	for (i = 7; i <= 10; i++) {
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
