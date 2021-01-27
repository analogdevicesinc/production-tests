"""Module used to check M1K board calibration."""

import adc_ad7091r5
import control_m1k
import dac_ad5647r
import debug
import global_
import ioxp_adp5589

global_.init()
# Init DAC and ADC
adc_ad7091r5.init()
dac_ad5647r.init()

TEXT = global_.TEXT_COLOR_MAP


def supply_output_5v0(
        min_lim, max_lim, calibration_factors_vin1, adc_samples, args):
    """Check M1K 5.0V reference.

    Compare M1K 5V0 with a min and a max value and return PASS or FAIL message
    """
    m1k_5v0_rail = \
        adc_ad7091r5.voltage_input(1, calibration_factors_vin1, adc_samples)[0]
    if m1k_5v0_rail >= min_lim and m1k_5v0_rail < max_lim:
        result = TEXT['green'] + '5V0 CHECK PASS' + TEXT['default']
        args['status'].append(True)
        args['status_values'].append('{0:.4f}'.format(m1k_5v0_rail))
    else:
        result = TEXT['red'] + '5V0 CHECK FAIL' + TEXT['default']
        args['status'].append(False)
        args['status_values'].append('{0:.4f}'.format(m1k_5v0_rail))
        if not args['enable_debug_mode']:
            print result
            exit(1)
    if args['view_short_debug_messages']:
        print result
    return args['status']


def supply_output_2v5(
        min_lim, max_lim, calibration_factors_vin3, adc_samples, args):
    """Check M1K 2.5V reference.

    Compare M1K 2V5 with a min and a max value and return PASS or FAIL message
    """
    m1k_2v5_rail = \
        adc_ad7091r5.voltage_input(3, calibration_factors_vin3, adc_samples)[0]
    if m1k_2v5_rail >= min_lim and m1k_2v5_rail < max_lim:
        result = TEXT['green'] + '2V5 CHECK PASS' + TEXT['default']
        args['status'].append(True)
        args['status_values'].append('{0:.4f}'.format(m1k_2v5_rail))
    else:
        result = TEXT['red'] + '2V5 CHECK FAIL' + TEXT['default']
        args['status'].append(False)
        args['status_values'].append('{0:.4f}'.format(m1k_2v5_rail))
        if not args['enable_debug_mode']:
            print result
            exit(1)
    if args['view_short_debug_messages']:
        print result
    return args['status']


def user_digital_in_out(device, args):
    """Digital IO test sequence."""
    reference_status = \
        ['0x74', '0x34', '0x14', '0x4', '0x84', '0xc4', '0xe4', '0xf4']
    repeat = 0
    while repeat <= 1:
        status = []
        ioxp_adp5589.setup_digital_in_out()

        # device.ctrl_transfer(0x40, 0x50, 0, 0, 0, 0, 100)
        device.ctrl_transfer(0x40, 0x50, 4, 0, 0, 0, 100)
        status.append(ioxp_adp5589.get_status_digital_in_out())

        # device.ctrl_transfer(0x40, 0x50, 1, 0, 0, 0, 100)
        device.ctrl_transfer(0x40, 0x50, 5, 0, 0, 0, 100)
        status.append(ioxp_adp5589.get_status_digital_in_out())

        # device.ctrl_transfer(0x40, 0x50, 2, 0, 0, 0, 100)
        device.ctrl_transfer(0x40, 0x50, 6, 0, 0, 0, 100)
        status.append(ioxp_adp5589.get_status_digital_in_out())

        # device.ctrl_transfer(0x40, 0x50, 3, 0, 0, 0, 100)
        device.ctrl_transfer(0x40, 0x50, 7, 0, 0, 0, 100)
        status.append(ioxp_adp5589.get_status_digital_in_out())

        # device.ctrl_transfer(0x40, 0x51, 0, 0, 0, 0, 100)
        device.ctrl_transfer(0x40, 0x51, 4, 0, 0, 0, 100)
        status.append(ioxp_adp5589.get_status_digital_in_out())

        # device.ctrl_transfer(0x40, 0x51, 1, 0, 0, 0, 100)
        device.ctrl_transfer(0x40, 0x51, 5, 0, 0, 0, 100)
        status.append(ioxp_adp5589.get_status_digital_in_out())

        # device.ctrl_transfer(0x40, 0x51, 2, 0, 0, 0, 100)
        device.ctrl_transfer(0x40, 0x51, 6, 0, 0, 0, 100)
        status.append(ioxp_adp5589.get_status_digital_in_out())

        # device.ctrl_transfer(0x40, 0x51, 3, 0, 0, 0, 100)
        device.ctrl_transfer(0x40, 0x51, 7, 0, 0, 0, 100)
        status.append(ioxp_adp5589.get_status_digital_in_out())
        repeat += 1

    ioxp_adp5589.direction_port_b(0x00)

    if status == reference_status:
        result = TEXT['green'] + 'DIO TEST PASS' + TEXT['default']
        args['status'].append(True)
    else:
        result = TEXT['red'] + 'DIO TEST FAIL' + TEXT['default']
        args['status'].append(False)
        if not args['enable_debug_mode']:
            print result
            exit(1)
    if args['view_short_debug_messages']:
        print result
    # print status
    return args['status']


def voltage_measurement_2v5(args, text):
    """MEASURE CHA/B EXTERNAL REFERENCE 2V5.

    Disconnect channels from GND and 2V5 using internal M1K switches
    Connect channel A or B at 2V5 external reference
    Set both channels to high impedance mode and get samples
    Optional is possible to generate plot images and display debug messages
    Compare voltage difference between measurement and reference
    to be in reference range then print PASS or FAIL message
    """
    control_m1k.set_switches_chs_2v5_gnd(
        'open', 'open', 'open', 'open', args['device'])
    if args['restart_verification'] == 0:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_8__1', 'GPIO_0__1', 'EN_1V2__1'])
    if args['restart_verification'] == 1:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_7__1', 'GPIO_0__1', 'EN_1V2__1'])
    control_m1k.channels_in_hi_z()
    control_m1k.get_samples_find_average(args['device'])
    adc_meas = \
        adc_ad7091r5.voltage_input(
            2, args['calibration_factors_vin2'],
            args['adc_samples'])[0]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Performance'), '1__P__CH_' +
            args['channel_name'] + '_measure_2V5',
            global_.CHX_V_I[4], str(args['channel_index'] * 2))
    if args['view_debug_messages']:
        print '\n', global_.CHX_V_I[args['channel_index'] * 2], '-', \
            adc_meas, '=> abs():', \
            abs(global_.CHX_V_I[args['channel_index'] * 2] - adc_meas), \
            'should be <=', adc_meas * args['tolerance_voltage']
    if abs(global_.CHX_V_I[args['channel_index'] * 2] - adc_meas) <= \
            adc_meas * args['tolerance_voltage']:
        debug_message = text['green'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [V] CH_' + \
            args['channel_name'] + ' PASS' + text['default']
        args['status'].append(True)
        args['status_values'].append('{0:.4f}'.format(adc_meas))
    else:
        debug_message = text['red'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [V] CH_' + \
            args['channel_name'] + ' FAIL' + text['default']
        args['status'].append(False)
        args['status_values'].append('{0:.4f}'.format(adc_meas))
        if not args['enable_debug_mode']:
            print debug_message
            exit(1)
    if args['view_short_debug_messages']:
        print debug_message
    return args['status']


def voltage_measurement_2v5_aux(args, text):
    """MEASURE CHA/B AUX EXTERNAL REFERENCE 2V5.

    Connect channel A or B auxiliary input at 2V5 external reference
    Set both channels to high impedance mode and get samples
    Optional is possible to generate plot images and display debug messages
    Compare voltage difference between measurement and reference
    to be in reference range then print PASS or FAIL message
    """
    if args['restart_verification'] == 0:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_10__1', 'GPIO_0__1', 'EN_1V2__1'])
    if args['restart_verification'] == 1:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_9__1', 'GPIO_0__1', 'EN_1V2__1'])
    control_m1k.channels_in_hi_z()
    control_m1k.get_samples_find_average(args['device'])
    adc_meas = \
        adc_ad7091r5.voltage_input(
            2, args['calibration_factors_vin2'],
            args['adc_samples'])[0]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Performance'),
            '2__P__CH_' + args['channel_name'] + '_aux_measure_2V5',
            global_.CHX_V_I[4], str(args['channel_index'] * 2))
    if args['view_debug_messages']:
        print '\n', global_.CHX_V_I[args['channel_index'] * 2], '-', \
            adc_meas, '=> abs():', \
            abs(global_.CHX_V_I[args['channel_index'] * 2] - adc_meas), \
            'should be <=', adc_meas * args['tolerance_voltage']
    if abs(global_.CHX_V_I[args['channel_index'] * 2] - adc_meas) <= \
            adc_meas * args['tolerance_voltage']:
        debug_message = text['green'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [V] CH_AUX_' + \
            args['channel_name'] + ' PASS' + text['default']
        args['status'].append(True)
        args['status_values'].append('{0:.4f}'.format(adc_meas))
    else:
        debug_message = text['red'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [V] CH_AUX_' + \
            args['channel_name'] + ' FAIL' + text['default']
        args['status'].append(False)
        args['status_values'].append('{0:.4f}'.format(adc_meas))
        if not args['enable_debug_mode']:
            print debug_message
            exit(1)
    if args['view_short_debug_messages']:
        print debug_message
    return args['status']


def voltage_measurement_1v25(args, text):
    """MEASURE CHA/B EXTERNAL 1V25.

    Connect channel A or B at amplified DAC output
    Set DAC to generate reference voltage
    Set both channels to high impedance mode and get samples
    Optional is possible to generate plot images and display debug messages
    Compare voltage difference between measurement and reference
    to be in reference range then print PASS or FAIL message
    """
    if args['restart_verification'] == 0:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_8__1', 'GPIO_2__1', 'EN_1V2__1'])
    if args['restart_verification'] == 1:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_7__1', 'GPIO_2__1', 'EN_1V2__1'])
    dac_ad5647r.set_output(args['dac_srs_1v25_cmd'])
    control_m1k.channels_in_hi_z()
    control_m1k.get_samples_find_average(args['device'])
    adc_meas = \
        adc_ad7091r5.voltage_input(
            2, args['calibration_factors_vin2'],
            args['adc_samples'])[0]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Performance'), '3__P__CH_' +
            args['channel_name'] + '_measure_1V25',
            global_.CHX_V_I[4], str(args['channel_index'] * 2))
    if args['view_debug_messages']:
        print '\n', global_.CHX_V_I[args['channel_index'] * 2], '-', \
            adc_meas, '=> abs():', \
            abs(global_.CHX_V_I[args['channel_index'] * 2] - adc_meas), \
            'should be <=', adc_meas * args['tolerance_voltage']
    if abs(global_.CHX_V_I[args['channel_index'] * 2] - adc_meas) <= \
            adc_meas * args['tolerance_voltage']:
        debug_message = text['green'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [V] CH_' + \
            args['channel_name'] + ' PASS' + text['default']
        args['status'].append(True)
        args['status_values'].append('{0:.4f}'.format(adc_meas))
    else:
        debug_message = text['red'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [V] CH_' + \
            args['channel_name'] + ' FAIL' + text['default']
        args['status'].append(False)
        args['status_values'].append('{0:.4f}'.format(adc_meas))
        if not args['enable_debug_mode']:
            print debug_message
            exit(1)
    if args['view_short_debug_messages']:
        print debug_message
    return args['status']


def voltage_measurement_3v75(args, text):
    """MEASURE CHA/B EXTERNAL 3V75.

    Set DAC to generate reference voltage
    Set both channels to high impedance mode and get samples
    Optional is possible to generate plot images and display debug messages
    Compare voltage difference between measurement and reference
    to be in reference range then print PASS or FAIL message
    """
    dac_ad5647r.set_output(args['dac_srs_3v75_cmd'])
    control_m1k.channels_in_hi_z()
    control_m1k.get_samples_find_average(args['device'])
    adc_meas = \
        adc_ad7091r5.voltage_input(
            2, args['calibration_factors_vin2'],
            args['adc_samples'])[0]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Performance'), '4__P__CH_' +
            args['channel_name'] + '_measure_3V75',
            global_.CHX_V_I[4], str(args['channel_index'] * 2))
    if args['view_debug_messages']:
        print '\n', global_.CHX_V_I[args['channel_index'] * 2], '-', \
            adc_meas, '=> abs():', \
            abs(global_.CHX_V_I[args['channel_index'] * 2] - adc_meas), \
            'should be <=', adc_meas * args['tolerance_voltage']
    if abs(global_.CHX_V_I[args['channel_index'] * 2] - adc_meas) <= \
            adc_meas * args['tolerance_voltage']:
        debug_message = text['green'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [V] CH_' + \
            args['channel_name'] + ' PASS' + text['default']
        args['status'].append(True)
        args['status_values'].append('{0:.4f}'.format(adc_meas))
    else:
        debug_message = text['red'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [V] CH_' + \
            args['channel_name'] + ' FAIL' + text['default']
        args['status'].append(False)
        args['status_values'].append('{0:.4f}'.format(adc_meas))
        if not args['enable_debug_mode']:
            print debug_message
            exit(1)
    if args['view_short_debug_messages']:
        print debug_message
    return args['status']


def source_0v8(args, text):
    """SOURCE CHA/B 0v8.

    Connect channel A or B at 1 Mega load and enable ADC external reference
    Set channel A or B to source reference voltage and get samples
    Set again channel A or B to source reference voltage
    and measure sourced voltage with external ADC
    Optional is possible to generate plot images and display debug messages
    Compare voltage difference between measurement and reference
    to be in reference range then print PASS or FAIL message
    """
    if args['restart_verification'] == 0:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_8__1', 'GPIO_3__1', 'EN_1V2__1'])
    if args['restart_verification'] == 1:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_7__1', 'GPIO_3__1', 'EN_1V2__1'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI,
        args['srs_0v8_setpoint'],
        global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI, args['srs_0v8_setpoint'],
        global_.Mode.HI_Z, args['device'])
    adc_meas = adc_ad7091r5.voltage_input(
        2, args['calibration_factors_vin2'], args['adc_samples'])
    if args['brake_script']:
        debug.add_break_point(
            text['orange'] + 'Measure sourced 0v8 with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Performance'), '5__P__CH_' +
            args['channel_name'] + '_source_0V8',
            global_.CHX_V_I[4], str(args['channel_index'] * 2))
    if args['view_debug_messages']:
        print '\n', 'ADC measurement', adc_meas, \
            'tolerance', args['tolerance_voltage']
    if abs(adc_meas[0] - args['srs_0v8_setpoint']) <= \
            args['tolerance_voltage']:
        debug_message = text['green'] + 'Source  ' + \
            '{0:+.4f}'.format(args['srs_0v8_setpoint']) + \
            ' [V] CH_' + args['channel_name'] + ' PASS' + text['default']
        args['status'].append(True)
        args['status_values'].append('{0:.4f}'.format(adc_meas[0]))
    else:
        debug_message = text['red'] + 'Source  ' + \
            '{0:+.4f}'.format(args['srs_0v8_setpoint']) + \
            ' [V] CH_' + args['channel_name'] + ' FAIL' + text['default']
        args['status'].append(False)
        args['status_values'].append('{0:.4f}'.format(adc_meas[0]))
        if not args['enable_debug_mode']:
            print debug_message
            exit(1)
    if args['view_short_debug_messages']:
        print debug_message
    return args['status']


def source_2v5(args, text):
    """SOURCE CHA/B 2V5.

    Set channel A or B to source reference voltage and get samples
    Set again channel A or B to source reference voltage
    and measure sourced voltage with external ADC
    Optional is possible to generate plot images and display debug messages
    Compare voltage difference between measurement and reference
    to be in reference range then print PASS or FAIL message
    """
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI, args['srs_2v5_setpoint'],
        global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI, args['srs_2v5_setpoint'],
        global_.Mode.HI_Z, args['device'])
    adc_meas = adc_ad7091r5.voltage_input(
        2, args['calibration_factors_vin2'], args['adc_samples'])
    if args['brake_script']:
        debug.add_break_point(
            text['orange'] + 'Measure sourced 2v5 with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Performance'), '6__P__CH_' +
            args['channel_name'] + '_source_2V5',
            global_.CHX_V_I[4], str(args['channel_index'] * 2))
    if args['view_debug_messages']:
        print '\n', 'ADC measurement', adc_meas, \
            'tolerance', args['tolerance_voltage']
    if abs(adc_meas[0] - args['srs_2v5_setpoint']) <= \
            args['tolerance_voltage']:
        debug_message = text['green'] + 'Source  ' + \
            '{0:+.4f}'.format(args['srs_2v5_setpoint']) + \
            ' [V] CH_' + args['channel_name'] + ' PASS' + text['default']
        args['status'].append(True)
        args['status_values'].append('{0:.4f}'.format(adc_meas[0]))
    else:
        debug_message = text['red'] + 'Source  ' + \
            '{0:+.4f}'.format(args['srs_2v5_setpoint']) + \
            ' [V] CH_' + args['channel_name'] + ' FAIL' + text['default']
        args['status'].append(False)
        args['status_values'].append('{0:.4f}'.format(adc_meas[0]))
        if not args['enable_debug_mode']:
            print debug_message
            exit(1)
    if args['view_short_debug_messages']:
        print debug_message
    return args['status']


def source_4v5(args, text):
    """SOURCE CHA/B 4V5.

    Set channel A or B to source reference voltage and get samples
    Set again channel A or B to source reference voltage
    and measure sourced voltage with external ADC
    Optional is possible to generate plot images and display debug messages
    Compare voltage difference between measurement and reference
    to be in reference range then print PASS or FAIL message
    """
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI, args['srs_4v5_setpoint'],
        global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI, args['srs_4v5_setpoint'],
        global_.Mode.HI_Z, args['device'])
    adc_meas = adc_ad7091r5.voltage_input(
        2, args['calibration_factors_vin2'], args['adc_samples'])
    if args['brake_script']:
        debug.add_break_point(
            text['orange'] + 'Measure sourced 4v5 with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Performance'), '7__P__CH_' +
            args['channel_name'] + '_source_4V5',
            global_.CHX_V_I[4], str(args['channel_index'] * 2))
    if args['view_debug_messages']:
        print '\n', 'ADC measurement', adc_meas, \
            'tolerance', args['tolerance_voltage']
    if abs(adc_meas[0] - args['srs_4v5_setpoint']) <= \
            args['tolerance_voltage']:
        debug_message = text['green'] + 'Source  ' + \
            '{0:+.4f}'.format(args['srs_4v5_setpoint']) + \
            ' [V] CH_' + args['channel_name'] + ' PASS' + text['default']
        args['status'].append(True)
        args['status_values'].append('{0:.4f}'.format(adc_meas[0]))
    else:
        debug_message = text['red'] + 'Source  ' + \
            '{0:+.4f}'.format(args['srs_4v5_setpoint']) + \
            ' [V] CH_' + args['channel_name'] + ' FAIL' + text['default']
        args['status'].append(False)
        args['status_values'].append('{0:.4f}'.format(adc_meas[0]))
        if not args['enable_debug_mode']:
            print debug_message
            exit(1)
    if args['view_short_debug_messages']:
        print debug_message
    return args['status']


def positive_current_measurement(args, text):
    """MEASURE POSITIVE CURRENT CHA/B.

    Connect channel A or B at Load and enable ADC external reference
    Set channel A or B to source voltage setpoint and get samples
    Set again channel A or B to source voltage setpoint
    and measure resulted current with external ADC and CSA
    Optional is possible to generate plot images and display debug messages
    Compare current difference between measurement and reference
    to be in reference range then print PASS or FAIL message
    """
    if args['restart_verification'] == 0:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_8__1', 'GPIO_1__1', 'EN_1V2__1'])
    if args['restart_verification'] == 1:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_7__1', 'GPIO_1__1', 'EN_1V2__1'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI, args['svmi_setpoint_poz'],
        global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI, args['svmi_setpoint_poz'],
        global_.Mode.HI_Z, args['device'])
    adc_meas = adc_ad7091r5.current_value(
        args['adc_offset_poz'], args['adc_gain_poz'],
        args['i_gain_poz'], args['adc_samples'])[0]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Performance'), '8__P__CH_' +
            args['channel_name'] + '_measure_positive_current',
            global_.CHX_V_I[4], str(args['channel_index'] * 2 + 1))
    if args['view_debug_messages']:
        print '\n', global_.CHX_V_I[args['channel_index'] * 2 + 1], '-', \
            adc_meas, '=> abs():', \
            abs(global_.CHX_V_I[args['channel_index'] * 2 + 1] - adc_meas), \
            'should be <=', abs(adc_meas * args['tolerance_current'])
    if abs(global_.CHX_V_I[args['channel_index'] * 2 + 1] - adc_meas) <= \
            abs(adc_meas * args['tolerance_current']):
        debug_message = text['green'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [A] CH_' + \
            args['channel_name'] + ' PASS' + text['default']
        args['status'].append(True)
        args['status_values'].append('{0:+.4f}'.format(adc_meas))
    else:
        debug_message = text['red'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [A] CH_' + \
            args['channel_name'] + ' FAIL' + text['default']
        args['status'].append(False)
        args['status_values'].append('{0:+.4f}'.format(adc_meas))
        if not args['enable_debug_mode']:
            print debug_message
            exit(1)
    if args['view_short_debug_messages']:
        print debug_message
    return args['status']


def negative_current_measurement(args, text):
    """MEASURE NEGATIVE CURRlENT CHA/B.

    Set channel A or B to source voltage setpoint and get samples
    Set again channel A or B to source voltage setpoint
    and measure resulted current with external ADC and CSA
    Optional is possible to generate plot images and display debug messages
    Compare current difference between measurement and reference
    to be in reference range then print PASS or FAIL message
    """
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI, args['svmi_setpoint_neg'],
        global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI, args['svmi_setpoint_neg'],
        global_.Mode.HI_Z, args['device'])
    adc_meas = adc_ad7091r5.current_value(
        args['adc_offset_neg'], args['adc_gain_neg'],
        args['i_gain_neg'], args['adc_samples'])[0]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Performance'), '9__P__CH_' +
            args['channel_name'] + '_measure_negative_current',
            global_.CHX_V_I[4], str(args['channel_index'] * 2 + 1))
    if args['view_debug_messages']:
        print '\n', global_.CHX_V_I[args['channel_index'] * 2 + 1], '-', \
            adc_meas, '=> abs():', \
            abs(global_.CHX_V_I[args['channel_index'] * 2 + 1] - adc_meas), \
            'should be <=', abs(adc_meas * args['tolerance_current'])
    if abs(global_.CHX_V_I[args['channel_index'] * 2 + 1] - adc_meas) <= \
            abs(adc_meas * args['tolerance_current']):
        debug_message = text['green'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [A] CH_' + \
            args['channel_name'] + ' PASS' + text['default']
        args['status'].append(True)
        args['status_values'].append('{0:+.4f}'.format(adc_meas))
    else:
        debug_message = text['red'] + 'Measure ' + \
            '{0:+.4f}'.format(adc_meas) + ' [A] CH_' + \
            args['channel_name'] + ' FAIL' + text['default']
        args['status'].append(False)
        args['status_values'].append('{0:+.4f}'.format(adc_meas))
        if not args['enable_debug_mode']:
            print debug_message
            exit(1)
    if args['view_short_debug_messages']:
        print debug_message
    return args['status']


def positive_current_source(args, text):
    """SOURCE POSITIVE CURRENT CHA/B.

    Set channel A or B to source reference current and get samples
    Set again channel A or B to source reference current
    and measure resulted current with external ADC and CSA
    Optional is possible to generate plot images and display debug messages
    Compare current difference between measurement and reference
    to be in reference range then print PASS or FAIL message
    """
    control_m1k.source(
        args['channel_index'], global_.Mode.SIMV, args['srs_i_setpoint_poz'],
        global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SIMV, args['srs_i_setpoint_poz'],
        global_.Mode.HI_Z, args['device'])
    adc_meas = adc_ad7091r5.current_value(
        args['adc_offset_poz'], args['adc_gain_poz'],
        args['i_gain_poz'], args['adc_samples'])[0]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Performance'), '10__P__CH_' +
            args['channel_name'] + '_source_positive_current',
            global_.CHX_V_I[4], str(args['channel_index'] * 2 + 1))
    if args['view_debug_messages']:
        print '\n', 'adc_meas', adc_meas
    if abs(adc_meas - args['srs_i_setpoint_poz']) <= \
            abs(adc_meas * args['tolerance_current']):
        debug_message = text['green'] + 'Source  ' + \
            '{0:+.4f}'.format(args['srs_i_setpoint_poz']) + \
            ' [A] CH_' + args['channel_name'] + ' PASS' + text['default']
        args['status'].append(True)
        args['status_values'].append('{0:+.4f}'.format(adc_meas))
    else:
        debug_message = text['red'] + 'Source  ' + \
            '{0:+.4f}'.format(args['srs_i_setpoint_poz']) + \
            ' [A] CH_' + args['channel_name'] + ' FAIL' + text['default']
        args['status'].append(False)
        args['status_values'].append('{0:+.4f}'.format(adc_meas))
        if not args['enable_debug_mode']:
            print debug_message
            exit(1)
    if args['view_short_debug_messages']:
        print debug_message
    return args['status']


def negative_current_source(args, text):
    """SOURCE NEGATIVE CURRENT CHA/B.

    Set channel A or B to source reference current and get samples
    Set again channel A or B to source reference current
    and measure resulted current with external ADC and CSA
    Optional is possible to generate plot images and display debug messages
    Compare current difference between measurement and reference
    to be in reference range then print PASS or FAIL message
    """
    control_m1k.source(
        args['channel_index'], global_.Mode.SIMV, args['srs_i_setpoint_neg'],
        global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SIMV, args['srs_i_setpoint_neg'],
        global_.Mode.HI_Z, args['device'])
    adc_meas = adc_ad7091r5.current_value(
        args['adc_offset_neg'], args['adc_gain_neg'],
        args['i_gain_neg'], args['adc_samples'])[0]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Performance'), '11__P__CH_' +
            args['channel_name'] + '_source_negative_current',
            global_.CHX_V_I[4], str(args['channel_index'] * 2 + 1))
    if args['view_debug_messages']:
        print '\n', 'adc_meas', adc_meas
    if abs(adc_meas - args['srs_i_setpoint_neg']) <= \
            abs(adc_meas * args['tolerance_current']):
        debug_message = text['green'] + 'Source  ' + \
            '{0:+.4f}'.format(args['srs_i_setpoint_neg']) + \
            ' [A] CH_' + args['channel_name'] + ' PASS' + text['default']
        args['status'].append(True)
        args['status_values'].append('{0:+.4f}'.format(adc_meas))
    else:
        debug_message = text['red'] + 'Source  ' + \
            '{0:+.4f}'.format(args['srs_i_setpoint_neg']) + \
            ' [A] CH_' + args['channel_name'] + ' FAIL' + text['default']
        args['status'].append(False)
        args['status_values'].append('{0:+.4f}'.format(adc_meas))
        if not args['enable_debug_mode']:
            print debug_message
            exit(1)
    if args['view_short_debug_messages']:
        print debug_message
    return args['status']


def check_current_offset(args, text):
    """Check current offset."""
    offset_status = None
    adc_meas_poz = adc_ad7091r5.current_value(
        args['adc_offset_poz'], args['adc_gain_poz'],
        args['i_gain_poz'], args['adc_samples'])[0]
    adc_meas_neg = adc_ad7091r5.current_value(
        args['adc_offset_neg'], args['adc_gain_neg'],
        args['i_gain_neg'], args['adc_samples'])[0]
    if (adc_meas_poz == 0.0) and (adc_meas_neg == 0.0):
        offset_status = text['green'] + 'Current offset OK' + \
            text['default']
    else:
        offset_status = text['red'] + 'Current offset detected' + \
            text['default']
    return offset_status + '\n'


def tft_check_status(args, text):
    """Display a table."""
    print "________________________________________"
    if args['status'][0]:
        print "| " + text['green'] + args['status_values'][0] + \
            " PASS" + text['default'],
    else:
        print "| " + text['red'] + args['status_values'][0] + \
            " FAIL" + text['default'],

    if args['status'][1]:
        print "| " + text['green'] + args['status_values'][1] + \
            " PASS" + text['default'],
    else:
        print "| " + text['red'] + args['status_values'][1] + \
            " FAIL" + text['default'],

    if args['status'][2]:
        print "|" + text['green'] + " DIO PASS " + text['default'] + "|"
    else:
        print "|" + text['red'] + " DIO FAIL " + text['default'] + "|"

    print "|_____________|_____________|__________|"
    print "|  MODE            |  CH  A  |  CH  B  |"
    print "|__________________|_________|_________|"

    print "| MEAS 2V5 REF     |",
    if args['status'][3]:
        print text['green'] + args['status_values'][2] + \
            text['default'] + "  |",
    else:
        print text['red'] + args['status_values'][2] + \
            text['default'] + "  |",
    if args['status'][14]:
        print text['green'] + args['status_values'][13] + \
            text['default'] + "  |"
    else:
        print text['red'] + args['status_values'][13] + \
            text['default'] + "  |"

    print "| MEAS 2V5 REF AUX |",
    if args['status'][4]:
        print text['green'] + args['status_values'][3] + \
            text['default'] + "  |",
    else:
        print text['red'] + args['status_values'][3] + \
            text['default'] + "  |",
    if args['status'][15]:
        print text['green'] + args['status_values'][14] + \
            text['default'] + "  |"
    else:
        print text['red'] + args['status_values'][14] + \
            text['default'] + "  |"

    print "| MEAS 1V25 REF    |",
    if args['status'][5]:
        print text['green'] + args['status_values'][4] + \
            text['default'] + "  |",
    else:
        print text['red'] + args['status_values'][4] + \
            text['default'] + "  |",
    if args['status'][16]:
        print text['green'] + args['status_values'][15] + \
            text['default'] + "  |"
    else:
        print text['red'] + args['status_values'][15] + \
            text['default'] + "  |"

    print "| MEAS 3V75 REF    |",
    if args['status'][6]:
        print text['green'] + args['status_values'][5] + \
            text['default'] + "  |",
    else:
        print text['red'] + args['status_values'][5] + \
            text['default'] + "  |",
    if args['status'][17]:
        print text['green'] + args['status_values'][16] + \
            text['default'] + "  |"
    else:
        print text['red'] + args['status_values'][16] + \
            text['default'] + "  |"

    print "| SRS 0V8          |",
    if args['status'][7]:
        print text['green'] + args['status_values'][6] + \
            text['default'] + "  |",
    else:
        print text['red'] + args['status_values'][6] + \
            text['default'] + "  |",
    if args['status'][18]:
        print text['green'] + args['status_values'][17] + \
            text['default'] + "  |"
    else:
        print text['red'] + args['status_values'][17] + \
            text['default'] + "  |"

    print "| SRS 2V5          |",
    if args['status'][8]:
        print text['green'] + args['status_values'][7] + \
            text['default'] + "  |",
    else:
        print text['red'] + args['status_values'][7] + \
            text['default'] + "  |",
    if args['status'][19]:
        print text['green'] + args['status_values'][18] + \
            text['default'] + "  |"
    else:
        print text['red'] + args['status_values'][18] + \
            text['default'] + "  |"

    print "| SRS 4V5          |",
    if args['status'][9]:
        print text['green'] + args['status_values'][8] + \
            text['default'] + "  |",
    else:
        print text['red'] + args['status_values'][8] + \
            text['default'] + "  |",
    if args['status'][20]:
        print text['green'] + args['status_values'][19] + \
            text['default'] + "  |"
    else:
        print text['red'] + args['status_values'][19] + \
            text['default'] + "  |"

    print "| MEAS +0.1A       |",
    if args['status'][10]:
        print text['green'] + args['status_values'][9] + \
            text['default'] + " |",
    else:
        print text['red'] + args['status_values'][9] + \
            text['default'] + " |",
    if args['status'][21]:
        print text['green'] + args['status_values'][20] + \
            text['default'] + " |"
    else:
        print text['red'] + args['status_values'][20] + \
            text['default'] + " |"

    print "| MEAS -0.1A       |",
    if args['status'][11]:
        print text['green'] + args['status_values'][10] + \
            text['default'] + " |",
    else:
        print text['red'] + args['status_values'][10] + \
            text['default'] + " |",
    if args['status'][22]:
        print text['green'] + args['status_values'][21] + \
            text['default'] + " |"
    else:
        print text['red'] + args['status_values'][21] + \
            text['default'] + " |"

    print "| SRS +0.1A        |",
    if args['status'][12]:
        print text['green'] + args['status_values'][11] + \
            text['default'] + " |",
    else:
        print text['red'] + args['status_values'][11] + \
            text['default'] + " |",
    if args['status'][23]:
        print text['green'] + args['status_values'][22] + \
            text['default'] + " |"
    else:
        print text['red'] + args['status_values'][22] + \
            text['default'] + " |"

    print "| SRS -0.1A        |",
    if args['status'][13]:
        print text['green'] + args['status_values'][12] + \
            text['default'] + " |",
    else:
        print text['red'] + args['status_values'][12] + \
            text['default'] + " |",
    if args['status'][24]:
        print text['green'] + args['status_values'][23] + \
            text['default'] + " |"
    else:
        print text['red'] + args['status_values'][23] + \
            text['default'] + " |"

    print "|__________________|_________|_________|"
