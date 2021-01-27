"""Module used to create M1K board calibration file.

____________________________________________________________________________
|   CALIBRATION    |             |             |             |             |
|     STAGES       | 1-ST stage  | 2-ND stage  | 3-RD stage  | 4-TH stage  |
|__________________|_____________|_____________|_____________|_____________|
| Measure voltage  |             |             |             |             |
|   calibration    |    Write    |    Write    |    Write    |    Write    |
|     factors      |   computed  |   computed  |   computed  |   computed  |
|   channel A&B    |   factors   |   factors   |   factors   |   factors   |
|__________________|_____________|_____________|_____________|_____________|
| Measure current  |             |             |             |             |
|   calibration    |    Write    |    Write    |    Write    |    Write    |
|     factors      |   default   |   default   |   computed  |   computed  |
|   channel A&B    |   factors   |   factors   |   factors   |   factors   |
|__________________|_____________|_____________|_____________|_____________|
| Source voltage   |             |             |             |             |
|   calibration    |    Write    |    Write    |    Write    |    Write    |
|     factors      |   default   |   computed  |   computed  |   computed  |
|   channel A&B    |   factors   |   factors   |   factors   |   factors   |
|__________________|_____________|_____________|_____________|_____________|
| Source current   |             |             |             |             |
|   calibration    |    Write    |    Write    |    Write    |    Write    |
|    factors       |   default   |   default   |   default   |   computed  |
|   channel A&B    |   factors   |   factors   |   factors   |   factors   |
|__________________|_____________|_____________|_____________|_____________|
"""


def extract_data_from_log(file_name, line_number):
    """Extract mean on buffer data from a log file."""
    with open(file_name, 'r') as text_file:
        read_lines = text_file.readlines()
    for char in ' []':
        read_lines[line_number - 1] = \
            read_lines[line_number - 1].replace(char, '')
    resulted_list = read_lines[line_number - 1].split(',')
    return resulted_list


def write_in_log(file_name, mode, data, extra_content=''):
    """Write mean on buffer data in a log file."""
    with open(file_name, mode) as log_file:
        log_file.write(str(data) + '\n' + extra_content)


def create_log(file_name):
    """Create a log file."""
    with open(file_name, 'w+') as log_file:
        log_file.write('')


def replace_line(file_name, line_number, replace_string, debug=False):
    """Replace line from text file."""
    with open(file_name, 'r') as text_file:
        read_lines = text_file.readlines()
    with open(file_name, 'w') as text_file:
        for i, line in enumerate(read_lines, 1):
            if i == line_number:
                text_file.writelines(replace_string + '\n')
            else:
                text_file.writelines(line)
    if debug:
        with open(file_name, 'r') as text_file:
            read_lines = text_file.readlines()
            print read_lines[line_number - 1]


def copy_text_file(source, dest):
    """Copy text file."""
    with open(source, 'r') as srs, open(dest, 'w') as dst:
        dst.write(srs.read())


def measure_voltage_factors(index, calib_file, factors):
    """Write calibration factors for measure voltage."""
    replace_line(calib_file, 3 + index * 26, '<0.0000, {0:.4f}>'.format(
        factors['chx_v_i_gnd_raw'][index]))
    replace_line(calib_file, 4 + index * 26, '<{0:.4f}, {1:.4f}>'.format(
        factors['ex_2v5_ref'], factors['chx_2v5_ex_ref_raw'][index]))


def measure_current_factors(index, calib_file, factors):
    """Write calibration factors for measure current."""
    replace_line(calib_file, 9 + index * 26, '<0.0000, {0:.4f}>'.format(
        factors['chx_f0v_raw'][index * 2 + 1]))
    replace_line(calib_file, 10 + index * 26, '<{0:.4f}, {1:.4f}>'.format(
        factors['calculated_i_poz_ref'][index],
        factors['chx_s5v_raw'][index * 2 + 1]))
    replace_line(calib_file, 11 + index * 26, '<{0:.4f}, {1:.4f}>'.format(
        factors['calculated_i_neg_ref'][index],
        factors['chx_s0v_raw'][index * 2 + 1]))


def source_voltage_factors(index, calib_file, factors):
    """Write calibration factors for source voltage."""
    replace_line(calib_file, 16 + index * 26, '<0.0000, {0:.4f}>'.format(
        factors['chx_f0v_raw'][index * 2]))
    replace_line(calib_file, 17 + index * 26, '<2.5000, {0:.4f}>'.format(
        factors['chx_f2v5_raw'][index * 2]))


def source_current_factors(index, calib_file, factors):
    """Write calibration factors for source current."""
    replace_line(calib_file, 22 + index * 26, '<0.0000, {0:.4f}>'.format(
        factors['chx_s0a_raw'][index * 2 + 1]))
    replace_line(calib_file, 23 + index * 26, '<{0:.4f}, {1:.4f}>'.format(
        factors['srs_i_setpoint_poz'],
        factors['chx_s_poz_raw'][index * 2 + 1]))
    replace_line(calib_file, 24 + index * 26, '<{0:.4f}, {1:.4f}>'.format(
        factors['srs_i_setpoint_neg'],
        factors['chx_s_neg_raw'][index * 2 + 1]))


def update(channel_index, calib_file, stages, data):
    """Update calibration file."""
    if stages['first_stage']:
        measure_voltage_factors(channel_index, calib_file, data)
    if stages['second_stage']:
        source_voltage_factors(channel_index, calib_file, data)
    if stages['third_stage']:
        measure_current_factors(channel_index, calib_file, data)
    if stages['fourth_stage']:
        source_current_factors(channel_index, calib_file, data)
