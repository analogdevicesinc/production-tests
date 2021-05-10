"""Module used for debugging."""

import os
import signal
import sys


def log_samples(directory, file_name, data_list, highlight=''):
    """Log samples."""
    print file_name
    with open(str(file_name) + ".csv", "w") as results_file:
        results_file.write(
            'Ch_A_Voltage' + ',' +
            'Ch_A_Current' + ',' +
            'Ch_B_Voltage' + ',' +
            'Ch_B_Current' + '\n')
        for index in range(len(data_list[0])):
            results_file.write(
                str(data_list[0][index]) + ',' +
                str(data_list[1][index]) + ',' +
                str(data_list[2][index]) + ',' +
                str(data_list[3][index]) + '\n')


def add_break_point(message):
    """Stop script execution until user press 'ENTER' key."""
    print
    while True:
        output(message)
        if not wait_for_input('', 1)[0]:
            break


def check_input(info_text, time):
    """Check keyboard input."""
    keyboard_input = wait_for_input(info_text, time)
    if not keyboard_input[0]:
        print 'Keyboard input:', keyboard_input[1]
        try:
            print 'check_input'
        except ValueError:
            pass
    else:
        pass


def wait_for_input(text, time):
    """Wait for keyboard input."""
    signal.signal(signal.SIGALRM, signal_handler)
    signal.alarm(time)
    try:
        keyboard_input = raw_input(text)
        sys.stdout.write('\r' + text)
        signal.alarm(0)
        timeout = False
    except KeyboardInterrupt:
        pass
    except:
        timeout = True
        signal.alarm(0)
        keyboard_input = ''
    return timeout, keyboard_input


def signal_handler():
    """Signal handler function."""
    raise Exception('')


def output(string_text):
    """Print text on a single line in terminal."""
    return sys.stdout.write('\r' + string_text)
