#!/usr/bin/scopy -s

var SHOW_TIMESTAMP = true;
var SHOW_START_END_TIME = true;
var MAX_HIGH_GAIN = 2.525;
var MIN_HIGH_GAIN = 2.475;
var MAX_LOW_GAIN = 10.25;
var MIN_LOW_GAIN = 9.75;
var ADC_CONST_ERR_THRESHOLD = 0.1;
var WORKING_DIR = ".";
var M2KCALIB_INI = "m2k-calib-factory.ini";
var M2KCALIB_INI_LOCAL = "/tmp/" + M2KCALIB_INI;

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
	var i;

	if (high) {
		output = extern.start("./ref_measure_ctl.sh ref2.5v");
	} else {
		output = extern.start("./ref_measure_ctl.sh ref10v");
	}

	osc.running = true;

	_osc_change_gain_mode(ch, high);
	/* Busy wait for 10 seconds, with 100 milliseconds intervals */
	for (i = 0; i < 100; i++) {
		value = _osc_read_constant(ch);
		ret = _osc_check_range(high, value);
		if (ret)
			break;
		msleep(100);
	}
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
	msleep(500);
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
	var i;
	var result = "";
	var ret_value;

	_awg_output_constant(ch, value);

	ret = false;
	/* busy wait for 10 seconds with 100 milliseconds intervals */
	for (i = 0; i < 100; i++) {
		ret_value = _osc_read_constant(ch);
		if ((ret_value < (value + ADC_CONST_ERR_THRESHOLD)) && (ret_value > (value - ADC_CONST_ERR_THRESHOLD))) {
			ret = true;
			break;
		}
		msleep(100);
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
		value = extern.start("./m2k_power_calib_meas.sh V5B pos false").trim();
		log("pos " + step + " result: " + value);
		if (value == '' || value == "failed" || isNaN(value))
			return false;
		ok = manual_calib.setParam(value);
		if (!ok)
			return false;
		next_step = manual_calib.next();
		step++;
		res += value + " ";
	}
	
	if (next_step < 0) {
		next_calib = manual_calib.finish();
	}
	res = "DONE - pos supply - voltages: " + res;
	log(res);
	return true;
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
		value = extern.start("./m2k_power_calib_meas.sh V6B neg false").trim();
		log("neg " + step + " result: " + value);
		if (value == '' || value == "failed" || isNaN(value))
			return false;
		ok = manual_calib.setParam(value);
		if (!ok)
			return false;
		next_step = manual_calib.next();
		step++;
		res += value + " ";
	}
	
	if (next_step < 0) {
		next_calib = manual_calib.finish();
	}
	res = "DONE - neg supply - voltages: " + res;
	log(res);
	return true;
}

function step_7()
{
	var ret;
	log(createStepHeader(7));
	ret = _calibrate_pos_power_supply();
	if (!ret)
		return false;
	log("\n");
	ret = _calibrate_neg_power_supply();
	if (!ret)
		return false;
	manual_calib.start(2);
	manual_calib.saveCalibration(M2KCALIB_INI_LOCAL);
	ret = extern.start("./scp.sh " + M2KCALIB_INI_LOCAL + " root@192.168.2.1:/mnt_jffs2/" + M2KCALIB_INI + " analog").trim();
	if (ret != "ok") {
		extern.start("rm -f " + M2KCALIB_INI_LOCAL);
		log("Failed to save calibration file to M2k: " + ret);
		return false;
	}
	extern.start("rm -f " + M2KCALIB_INI_LOCAL);
	log("Saved calibration parameters to file");
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

	if (!connect())      
		return Error()

	enableExternScripts();
	enableCalibScripts();
	extern.setWorkingDir(WORKING_DIR);
	extern.setProcessTimeout(0);

	if (SHOW_START_END_TIME)
		log("Script started on: " + get_now_s() + '\n');

	for (i = 5; i <= 7; i++) {
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
