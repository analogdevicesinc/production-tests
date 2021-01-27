"""Module used to calibrate M1K board.

_______________________________________________________________________________
|             |                                       |                       |
| restart_    |           Operations                  |    Expected result    |
| calibration |                                       |                       |
|_____________|_______________________________________|_______________________|
|             |                                       |                       |
|             | Channel A measure 2V5                 |                       |
|      0      | external reference and GND,           |                       |
|             | write factors in                      |                       |
|             | calibration text file                 |  Channel A&B          |
|_____________|_______________________________________|  measure voltage      |
|             |                                       |  should be calibrated |
|             | Channel B measure 2V5                 |                       |
|      1      | external reference and GND,           |                       |
|             | append factors in calibration         |                       |
|             | text file and upload file on M1K      |                       |
|_____________|_______________________________________|_______________________|
|             |                                       |                       |
|             | Channel A source 2V5                  |                       |
|      2      | and 0V without load,                  |                       |
|             | write factors in                      |                       |
|             | calibration text file                 |  Channel A&B          |
|_____________|_______________________________________|  ource voltage        |
|             |                                       |  should be calibrated |
|             | Channel B source 2V5                  |                       |
|      3      | and 0V without load,                  |                       |
|             | append factors in calibration         |                       |
|             | text file and upload file on M1K      |                       |
|_____________|_______________________________________|_______________________|
|             |                                       |                       |
|             | Channel A measure positive            |                       |
|             | and negative current,                 |                       |
|      4      | perform calculations or measurements, |                       |
|             | write factors in                      |                       |
|             | calibration text file                 |  Channel A&B          |
|_____________|_______________________________________|  measure current      |
|             |                                       |  should be calibrated |
|             | Channel B measure positive,           |                       |
|             | negative and zero current             |                       |
|      5      | perform calculations or measurements, |                       |
|             | append factors in calibration         |                       |
|             | text file and upload file on M1K      |                       |
|_____________|_______________________________________|_______________________|
|             |                                       |                       |
|             | Channel A source positive,            |                       |
|             | negative and zero current,            |                       |
|      6      | perform calculations or measurements, |                       |
|             | write factors in                      |                       |
|             | calibration text file                 |  Channel A&B          |
|_____________|_______________________________________|  source current       |
|             |                                       |  should be calibrated |
|             | Channel B source positive,            |                       |
|             | negative and zero current,            |                       |
|      7      | perform calculations or measurements, |                       |
|             | append factors in calibration         |                       |
|             | text file and upload file on M1K      |                       |
|_____________|_______________________________________|_______________________|
"""

import calibration_file
import control_m1k
import debug
import global_
import ioxp_adp5589

global_.init()


def measure_chx_external_2v5(args, text):
    """MEASURE CHA/B EXTERNAL 2V5.

    Disconnect channels from GND and 2V5 using internal M1K switches
    Connect channel A or B at external reference
    Set both channels to HI_Z mode and get samples
    Get voltage mean value for current channel
    Display FAIL or PASS message, if FAIL exit
    Optional is possible to generate plot images and display debug messages
    """
    control_m1k.set_switches_chs_2v5_gnd(
        'open', 'open', 'open', 'open', args['device'])
    if args['restart_calibration'] == 0:
        ioxp_adp5589.gpo_set_ac(['GPIO_0__1', 'GPIO_8__1'])
    if args['restart_calibration'] == 1:
        ioxp_adp5589.gpo_set_ac(['GPIO_0__1', 'GPIO_7__1'])
    control_m1k.channels_in_hi_z()
    control_m1k.get_external_2v5_samples(args['device'])
    if args['brake_script']:
        debug.add_break_point(
            text['orange'] + 'Measure external 2V5 with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    args['chx_2v5_ex_ref_raw'][args['channel_index']] = \
        global_.CHX_2V5_EX_REF[args['channel_index'] * 2]
    if 2.4 > global_.CHX_2V5_EX_REF[args['channel_index'] * 2] < 2.6:
        print text['red'] + 'FAIL measure external 2.5V channel ' + \
            args['channel_name'] + ':\t' + \
            str(global_.CHX_2V5_EX_REF[args['channel_index'] * 2]) + \
            text['default']
        exit(1)
    else:
        print text['green'] + 'PASS measure reference channel ' + \
            args['channel_name'] + ': ' + \
            str('{0:.4f}'.format(
                global_.CHX_2V5_EX_REF[args['channel_index'] * 2])) + \
            text['default']
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Calibration'), '1__CH_' +
            args['channel_name'] + '_measure_External_2V5',
            global_.CHX_2V5_EX_REF[4], str(args['channel_index'] * 2))
    if args['view_debug_messages']:
        print 'ST_0.', args['channel_name'], \
            text['turquoise'] + 'Mean of buffer data:' + text['default'], \
            args['chx_2v5_ex_ref_raw']
    calibration_file.write_in_log(
        args['log_name'], 'a+', 'Measure external 2V5 with channel ' +
        args['channel_name'] + ' -> [chx_2v5_ex_ref_raw]')
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['chx_2v5_ex_ref_raw'], '\n')
    return args['chx_2v5_ex_ref_raw']


def measure_chx_gnd(args, text):
    """MEASURE CHA/B GND.

    Disconnect M1K from calibration board
    Connect channels at GND using internal M1K switches
    Set both channels to high impedance mode and get samples
    Get voltage and current mean value for current channel
    Optional is possible to generate plot images and display debug messages
    """
    ioxp_adp5589.gpo_set_ac([''])
    control_m1k.set_switches_chs_2v5_gnd(
        'open', 'close', 'open', 'close', args['device'])
    control_m1k.channels_in_hi_z()
    control_m1k.get_samples_find_average(args['device'])
    if args['brake_script']:
        debug.add_break_point(
            text['orange'] +
            'Measure GND value with channel ' + args['channel_name'] +
            ' ... Press ENTER to continue... ' + text['default'])
    args['chx_v_i_gnd_raw'][args['channel_index'] *
                            2] = global_.CHX_V_I[args['channel_index'] * 2]
    args['chx_v_i_gnd_raw'][args['channel_index'] * 2 +
                            1] = global_.CHX_V_I[args['channel_index'] * 2 + 1]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Calibration'), '2__CH_' +
            args['channel_name'] + '_measure_GND',
            global_.CHX_V_I[4], str(args['channel_index'] * 2))
    if args['view_debug_messages']:
        print 'ST_1.', args['channel_name'], \
            text['turquoise'] + 'Mean of buffer data:' + text['default'], \
            args['chx_v_i_gnd_raw']
    calibration_file.write_in_log(
        args['log_name'], 'a+', 'Measure GND value with channel ' +
        args['channel_name'] + ' -> [chx_v_i_gnd_raw]')
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['chx_v_i_gnd_raw'], '\n')
    return args['chx_v_i_gnd_raw']


def source_chx_0v_without_load(args, text):
    """SOURCE CHA/B 0V WITHOUT LOAD.

    Disconnect channels from GND and 2V5 using internal M1K switches
    Source 0V using channel A or B and get samples
    Get voltage and current mean value for current channel
    Optional is possible to generate plot images and display debug messages
    """
    control_m1k.set_switches_chs_2v5_gnd(
        'open', 'open', 'open', 'open', args['device'])
    control_m1k.source_0v(
        args['channel_index'], global_.Mode.SVMI, 0.0, global_.Mode.HI_Z,
        args['device'])
    control_m1k.get_samples_find_average(args['device'])
    if args['brake_script']:
        control_m1k.source_0v(
            args['channel_index'], global_.Mode.SVMI, 0.0, global_.Mode.HI_Z,
            args['device'])
        debug.add_break_point(
            text['orange'] + 'Source 0V with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    args['chx_f0v_raw'][args['channel_index'] *
                        2] = global_.CHX_V_I[args['channel_index'] * 2]
    args['chx_f0v_raw'][args['channel_index'] * 2 +
                        1] = global_.CHX_V_I[args['channel_index'] * 2 + 1]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Calibration'), '3__CH_' +
            args['channel_name'] + '_source_0V',
            global_.CHX_V_I[4], str(args['channel_index'] * 2))
    if args['view_debug_messages']:
        print 'ST_3.', args['channel_name'], \
            text['turquoise'] + 'Mean of buffer data:' + text['default'], \
            args['chx_f0v_raw']
    calibration_file.write_in_log(
        args['log_name'], 'a+', 'Source 0V with channel ' +
        args['channel_name'] + ' -> [chx_f0v_raw]')
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['chx_f0v_raw'], '\n')
    return args['chx_f0v_raw']


def source_chx_2v5_without_load(args, text):
    """SOURCE CHA/B 2V5 WITHOUT LOAD.

    Source 2V5 using channel A or B without measuring M1K 2V5 and get samples
    Get voltage and current mean value for current channel
    Optional is possible to generate plot images and display debug messages
    """
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI, 2.5,
        global_.Mode.HI_Z, args['device'], args['do_not_get_m1k_2v5_val'])
    control_m1k.get_samples_find_average(args['device'])
    if args['brake_script']:
        control_m1k.source(
            args['channel_index'], global_.Mode.SVMI, 2.5,
            global_.Mode.HI_Z, args['device'], args['do_not_get_m1k_2v5_val'])
        debug.add_break_point(
            text['orange'] + 'Source 2V5 with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    args['chx_f2v5_raw'][args['channel_index'] *
                         2] = global_.CHX_V_I[args['channel_index'] * 2]
    args['chx_f2v5_raw'][args['channel_index'] * 2 +
                         1] = global_.CHX_V_I[args['channel_index'] * 2 + 1]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Calibration'),
            '4__CH_' + args['channel_name'] +
            '_source_2V5', global_.CHX_V_I[4], str(args['channel_index'] * 2))
    if args['view_debug_messages']:
        print 'ST_4.', args['channel_name'], \
            text['turquoise'] + 'Mean of buffer data:' + text['default'], \
            args['chx_f2v5_raw']
    calibration_file.write_in_log(
        args['log_name'], 'a+', 'Source 2V5 with channel ' +
        args['channel_name'] + ' -> [chx_f2v5_raw]')
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['chx_f2v5_raw'], '\n')
    return args['chx_f2v5_raw']


def measure_chx_positive_current(args, text):
    """MEASURE CHA/B POSITIVE CURRENT.

    Connect channel A or B at Load, keep M1K powered on, enable REF ADC
    Source a voltage to result a positive current and get samples
    Measure 2V5 reference using channel in SVMI mode
    Source a voltage to result same positive current and get samples
    Measure sourced voltage using channel in HI_Z mode
    Get voltage and current mean value for current channel
    Optional is possible to generate plot images and display debug messages
    """
    if args['restart_calibration'] == 4:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_8__1', 'GPIO_1__1', 'EN_1V2__1'])
    if args['restart_calibration'] == 5:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_7__1', 'GPIO_1__1', 'EN_1V2__1'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI,
        args['svmi_setpoint_poz'],
        global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    if args['brake_script']:
        control_m1k.source(
            args['channel_index'], global_.Mode.SVMI,
            args['svmi_setpoint_poz'],
            global_.Mode.HI_Z, args['device'])
        debug.add_break_point(
            text['orange'] +
            'Measure positive current and M1K 2V5 with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    if args['restart_calibration'] == 4:
        args['m1k_2v5'][args['channel_index'] * 5] = global_.CHX_V_I[2]
    if args['restart_calibration'] == 5:
        args['m1k_2v5'][args['channel_index'] * 5] = global_.CHX_V_I[0]
    ioxp_adp5589.gpo_set_ac(
        ['GPIO_7__1', 'GPIO_8__1', 'GPIO_1__1', 'EN_1V2__1'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI,
        args['svmi_setpoint_poz'],
        global_.Mode.HI_Z, args['device'],
        args['do_not_get_m1k_2v5_val'])
    control_m1k.get_samples_find_average(args['device'])
    if args['brake_script']:
        control_m1k.source(
            args['channel_index'], global_.Mode.SVMI,
            args['svmi_setpoint_poz'],
            global_.Mode.HI_Z, args['device'],
            args['do_not_get_m1k_2v5_val'])
        debug.add_break_point(
            text['orange'] +
            'Measure positive current and M1K CHX with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    if args['restart_calibration'] == 4:
        args['m1k_hi_z_chx'][args['channel_index'] *
                             2] = global_.CHX_V_I[2] + args['comp_poz']
    if args['restart_calibration'] == 5:
        args['m1k_hi_z_chx'][args['channel_index'] *
                             2] = global_.CHX_V_I[0] + args['comp_poz']
    args['chx_s5v_raw'][args['channel_index'] *
                        2] = global_.CHX_V_I[args['channel_index'] * 2]
    args['chx_s5v_raw'][args['channel_index'] * 2 +
                        1] = global_.CHX_V_I[args['channel_index'] * 2 + 1]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Calibration'), '5__CH_' +
            args['channel_name'] + '_measure_positive_current',
            global_.CHX_V_I[4], str(args['channel_index'] * 2 + 1))
    if args['view_debug_messages']:
        print 'ST_5.', args['channel_name'], \
            text['turquoise'] + 'Mean of buffer data:' + text['default'], \
            args['chx_s5v_raw'], '\n\t' + \
            text['purple'] + 'M1K_2V5' + text['default'], \
            args['m1k_2v5'], '\n\t' + \
            text['orange'] + 'M1K_HI_Z_CHX' + text['default'], \
            args['m1k_hi_z_chx']
    calibration_file.write_in_log(
        args['log_name'], 'a+',
        'Measure positive current and M1K CHX with channel ' +
        args['channel_name'] + ' -> [chx_s5v_raw] [m1k_hi_z_chx] [m1k_2v5]')
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['chx_s5v_raw'])
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['m1k_hi_z_chx'])
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['m1k_2v5'], '\n')
    return args['chx_s5v_raw'], args['m1k_hi_z_chx'], args['m1k_2v5']


def measure_chx_negative_current(args, text):
    """MEASURE CHA/B NEGATIVE CURRENT.

    Connect channel A or B at Load, keep M1K powered on, enable REF ADC
    Source a voltage to result a negative current and get samples
    Measure 2V5 reference using channel in SVMI mode
    Source a voltage to result same negative current and get samples
    Measure sourced voltage using channel in HI_Z mode
    Get voltage and current mean value for current channel
    Optional is possible to generate plot images and display debug messages
    """
    if args['restart_calibration'] == 4:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_8__1', 'GPIO_1__1', 'EN_1V2__1'])
    if args['restart_calibration'] == 5:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_7__1', 'GPIO_1__1', 'EN_1V2__1'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI,
        args['svmi_setpoint_neg'],
        global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    if args['brake_script']:
        control_m1k.source(
            args['channel_index'], global_.Mode.SVMI,
            args['svmi_setpoint_neg'],
            global_.Mode.HI_Z, args['device'])
        debug.add_break_point(
            text['orange'] +
            'Measure negative current and M1K 2V5 with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    if args['restart_calibration'] == 4:
        args['m1k_2v5'][args['channel_index'] * 5 + 1] = global_.CHX_V_I[2]
    if args['restart_calibration'] == 5:
        args['m1k_2v5'][args['channel_index'] * 5 + 1] = global_.CHX_V_I[0]
    ioxp_adp5589.gpo_set_ac(
        ['GPIO_7__1', 'GPIO_8__1', 'GPIO_1__1', 'EN_1V2__1'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SVMI,
        args['svmi_setpoint_neg'],
        global_.Mode.HI_Z, args['device'],
        args['do_not_get_m1k_2v5_val'])
    control_m1k.get_samples_find_average(args['device'])
    if args['brake_script']:
        control_m1k.source(
            args['channel_index'], global_.Mode.SVMI,
            args['svmi_setpoint_neg'],
            global_.Mode.HI_Z, args['device'],
            args['do_not_get_m1k_2v5_val'])
        debug.add_break_point(
            text['orange'] +
            'Measure negative current and M1K CHX with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    if args['restart_calibration'] == 4:
        args['m1k_hi_z_chx'][args['channel_index'] *
                             2 + 1] = global_.CHX_V_I[2] + args['comp_neg']
    if args['restart_calibration'] == 5:
        args['m1k_hi_z_chx'][args['channel_index'] *
                             2 + 1] = global_.CHX_V_I[0] + args['comp_neg']
    args['chx_s0v_raw'][args['channel_index'] *
                        2] = global_.CHX_V_I[args['channel_index'] * 2]
    args['chx_s0v_raw'][args['channel_index'] * 2 +
                        1] = global_.CHX_V_I[args['channel_index'] * 2 + 1]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Calibration'), '6__CH_' +
            args['channel_name'] + '_measure_negative_current',
            global_.CHX_V_I[4], str(args['channel_index'] * 2 + 1))
    if args['view_debug_messages']:
        print 'ST_6.', args['channel_name'], \
            text['turquoise'] + 'Mean of buffer data:' + text['default'], \
            args['chx_s0v_raw'], '\n\t' + \
            text['purple'] + 'M1K_2V5' + \
            text['default'], args['m1k_2v5'], '\n\t' + \
            text['orange'] + 'M1K_HI_Z_CHX' + text['default'], \
            args['m1k_hi_z_chx']
    calibration_file.write_in_log(
        args['log_name'], 'a+',
        'Measure negative current and M1K CHX with channel ' +
        args['channel_name'] + ' -> [chx_s0v_raw] [m1k_hi_z_chx] [m1k_2v5]')
    calibration_file.write_in_log(args['log_name'], 'a+', args['chx_s0v_raw'])
    calibration_file.write_in_log(args['log_name'], 'a+', args['m1k_hi_z_chx'])
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['m1k_2v5'], '\n')
    return args['chx_s0v_raw'], args['m1k_hi_z_chx'], args['m1k_2v5']


def source_chx_0a_current(args, text):
    """SOURCE CHA/B 0A CURRENT.

    Connect channel A or B at Load, keep M1K powered on, enable REF ADC
    Source 0 A current and get samples
    Measure resulted voltage using channel in HI_Z mode
    Get voltage and current mean value for current channel
    Optional is possible to generate plot images and display debug messages
    """
    if args['restart_calibration'] == 6:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_8__1', 'GPIO_1__1', 'EN_1V2__1'])
    if args['restart_calibration'] == 7:
        ioxp_adp5589.gpo_set_ac(
            ['GPIO_7__1', 'GPIO_1__1', 'EN_1V2__1'])
    control_m1k.source(
        args['channel_index'], global_.Mode.SIMV, 0.0,
        global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    if args['brake_script']:
        control_m1k.source(
            args['channel_index'], global_.Mode.SIMV, 0.0,
            global_.Mode.HI_Z, args['device'])
        debug.add_break_point(
            text['orange'] + 'Source 0A with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    if args['restart_calibration'] == 6:
        args['m1k_2v5'][args['channel_index'] * 5 + 2] = global_.CHX_V_I[2]
    if args['restart_calibration'] == 7:
        args['m1k_2v5'][args['channel_index'] * 5 + 2] = global_.CHX_V_I[0]
    args['chx_s0a_raw'][args['channel_index'] *
                        2] = global_.CHX_V_I[args['channel_index'] * 2]
    args['chx_s0a_raw'][args['channel_index'] * 2 +
                        1] = global_.CHX_V_I[args['channel_index'] * 2 + 1]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Calibration'), '7__CH_' +
            args['channel_name'] + '_measure_0A_current',
            global_.CHX_V_I[4], str(args['channel_index'] * 2 + 1))
    if args['view_debug_messages']:
        print 'ST_7.', args['channel_name'], \
            text['turquoise'] + 'Mean of buffer data:' + text['default'], \
            args['chx_s0a_raw'], '\n\t' + \
            text['purple'] + 'M1K_2V5' + text['default'], \
            args['m1k_2v5']
    calibration_file.write_in_log(
        args['log_name'], 'a+', 'Source 0A with channel ' +
        args['channel_name'] + ' -> [chx_s0a_raw] [m1k_2v5]')
    calibration_file.write_in_log(args['log_name'], 'a+', args['chx_s0a_raw'])
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['m1k_2v5'], '\n')
    return args['chx_s0a_raw'], args['m1k_2v5']


def source_chx_positive_current(args, text):
    """SOURCE CHA/B POSITIVE CURRENT.

    Connect channel A or B at Load, keep M1K powered on, enable REF ADC
    Source a positive current and get samples
    Measure resulted voltage using channel in HI_Z mode
    Get voltage and current mean value for current channel
    Optional is possible to generate plot images and display debug messages
    """
    control_m1k.source(
        args['channel_index'], global_.Mode.SIMV, args['srs_i_setpoint_poz'],
        global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    if args['brake_script']:
        control_m1k.source(
            args['channel_index'], global_.Mode.SIMV,
            args['srs_i_setpoint_poz'], global_.Mode.HI_Z,
            args['device'])
        debug.add_break_point(
            text['orange'] +
            'Source positive current with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    if args['restart_calibration'] == 6:
        args['m1k_2v5'][args['channel_index'] * 5 + 3] = global_.CHX_V_I[2]
    if args['restart_calibration'] == 7:
        args['m1k_2v5'][args['channel_index'] * 5 + 3] = global_.CHX_V_I[0]
    args['chx_s_poz_raw'][args['channel_index'] *
                          2] = global_.CHX_V_I[args['channel_index'] * 2]
    args['chx_s_poz_raw'][args['channel_index'] * 2 +
                          1] = global_.CHX_V_I[args['channel_index'] * 2 + 1]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Calibration'), '8__CH_' +
            args['channel_name'] + '_source_positive_current',
            global_.CHX_V_I[4], str(args['channel_index'] * 2 + 1))
    if args['view_debug_messages']:
        print 'ST_8.', args['channel_name'], \
            text['turquoise'] + 'Mean of buffer data:' + text['default'], \
            args['chx_s_poz_raw'], '\n\t' + \
            text['purple'] + 'M1K_2V5' + text['default'], \
            args['m1k_2v5']
    calibration_file.write_in_log(
        args['log_name'], 'a+', 'Source positive current with channel ' +
        args['channel_name'] + ' -> [chx_s_poz_raw] [m1k_2v5]')
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['chx_s_poz_raw'])
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['m1k_2v5'], '\n')
    return args['chx_s_poz_raw'], args['m1k_2v5']


def source_chx_negative_current(args, text):
    """SOURCE CHA/B NEGATIVE CURRENT.

    Connect channel A or B at Load, keep M1K powered on, enable REF ADC
    Source a negative current and get samples
    Measure resulted voltage using channel in HI_Z mode
    Get voltage and current mean value for current channel
    Optional is possible to generate plot images and display debug messages
    """
    control_m1k.source(
        args['channel_index'], global_.Mode.SIMV,
        args['srs_i_setpoint_neg'], global_.Mode.HI_Z, args['device'])
    control_m1k.get_samples_find_average(args['device'])
    if args['brake_script']:
        control_m1k.source(
            args['channel_index'], global_.Mode.SIMV,
            args['srs_i_setpoint_neg'], global_.Mode.HI_Z,
            args['device'])
        debug.add_break_point(
            text['orange'] +
            'Source negative current with channel ' +
            args['channel_name'] + ' ... Press ENTER to continue... ' +
            text['default'])
    if args['restart_calibration'] == 6:
        args['m1k_2v5'][args['channel_index'] * 5 + 4] = global_.CHX_V_I[2]
    if args['restart_calibration'] == 7:
        args['m1k_2v5'][args['channel_index'] * 5 + 4] = global_.CHX_V_I[0]
    args['chx_s_neg_raw'][args['channel_index'] *
                          2] = global_.CHX_V_I[args['channel_index'] * 2]
    args['chx_s_neg_raw'][args['channel_index'] * 2 +
                          1] = global_.CHX_V_I[args['channel_index'] * 2 + 1]
    if args['create_plots']:
        debug.plot(
            str(args['device_id'] + '/Calibration'), '9__CH_' +
            args['channel_name'] + '_source_negative_current',
            global_.CHX_V_I[4], str(args['channel_index'] * 2 + 1))
    if args['view_debug_messages']:
        print 'ST_9.', args['channel_name'], \
            text['turquoise'] + 'Mean of buffer data:' + text['default'], \
            args['chx_s_neg_raw'], '\n\t' + \
            text['purple'] + 'M1K_2V5' + text['default'], \
            args['m1k_2v5']
    calibration_file.write_in_log(
        args['log_name'], 'a+', 'Source negative current with channel ' +
        args['channel_name'] + ' -> [chx_s_neg_raw] [m1k_2v5]')
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['chx_s_neg_raw'])
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['m1k_2v5'], '\n')
    return args['chx_s_neg_raw'], args['m1k_2v5']


def calculate_currents(args, text):
    """Calculate positive and negative reference currents."""
    if args['view_debug_messages']:
        print text['purple'], '\n' + \
            'Current calculation for SVMI mode for channel', \
            args['channel_name'], 'with compensated voltage:'
    args['calculated_i_poz_ref'][args['channel_index']] = (
        args['m1k_hi_z_chx'][args['channel_index'] * 2] -
        args['m1k_2v5'][args['channel_index'] * 5]) / args['r_ch_srs']
    if args['view_debug_messages']:
        print '{:0>4.4f} = ({:0>4.4f} - {:0>4.4f}) / {:0>4.4f}'.format(
            args['calculated_i_poz_ref'][args['channel_index']],
            args['m1k_hi_z_chx'][args['channel_index'] * 2],
            args['m1k_2v5'][args['channel_index'] * 5],
            args['r_ch_srs']),
        print '\t => \t{:0>4.4f} = {:0>4.4f} / {:0>4.4f}'.format(
            args['calculated_i_poz_ref'][args['channel_index']],
            args['m1k_hi_z_chx'][args['channel_index'] * 2] -
            args['m1k_2v5'][args['channel_index'] * 5],
            args['r_ch_srs'])
    args['calculated_i_neg_ref'][args['channel_index']] = (
        args['m1k_hi_z_chx'][args['channel_index'] * 2 + 1] -
        args['m1k_2v5'][args['channel_index'] * 5 + 1]) / args['r_ch_snk']
    if args['view_debug_messages']:
        print '{:0>4.4f} = ({:0>4.4f} - {:0>4.4f}) / {:0>4.4f}'.format(
            args['calculated_i_neg_ref'][args['channel_index']],
            args['m1k_hi_z_chx'][args['channel_index'] * 2 + 1],
            args['m1k_2v5'][args['channel_index'] * 5 + 1],
            args['r_ch_snk']),
        print '\t => \t{:0>4.4f} = {:0>4.4f} / {:0>4.4f}'.format(
            args['calculated_i_neg_ref'][args['channel_index']],
            args['m1k_hi_z_chx'][args['channel_index'] * 2 + 1] -
            args['m1k_2v5'][args['channel_index'] * 5 + 1],
            args['r_ch_snk'])
        print text['default']
    calibration_file.write_in_log(
        args['log_name'], 'a+',
        'Current calculation for SVMI mode for channel ' +
        args['channel_name'] +
        ' -> [calculated_i_poz_ref] [calculated_i_neg_ref]')
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['calculated_i_poz_ref'])
    calibration_file.write_in_log(
        args['log_name'], 'a+', args['calculated_i_neg_ref'], '\n')
    return args['calculated_i_poz_ref'], args['calculated_i_neg_ref']
