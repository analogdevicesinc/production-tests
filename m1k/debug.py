"""Module used for debugging."""

import os
import signal
import sys


def plot(directory, file_name, data_list, highlight=''):
    """Generate plot images."""
    import matplotlib.pyplot as plt
    from pylab import arange

    plt.subplot(2, 2, 1)
    plt.plot(arange(0.0, len(data_list[0]), 1), data_list[0])
    plt.ylabel('[V]')
    plt.xlabel('Samples')
    plt.title('Channel A voltage')
    plt.grid(True)
    if highlight == '0':
        plt.subplot(2, 2, 1).set_axis_bgcolor('#16BA42')

    plt.subplot(2, 2, 3)
    plt.plot(arange(0.0, len(data_list[1]), 1), data_list[1])
    plt.ylabel('[A]')
    plt.xlabel('Samples')
    plt.title('Channel A current')
    plt.grid(True)
    if highlight == '1':
        plt.subplot(2, 2, 3).set_axis_bgcolor('#16BA42')

    plt.subplot(2, 2, 2)
    plt.plot(arange(0.0, len(data_list[2]), 1), data_list[2])
    plt.ylabel('[V]')
    plt.xlabel('Samples')
    plt.title('Channel B voltage')
    plt.grid(True)
    if highlight == '2':
        plt.subplot(2, 2, 2).set_axis_bgcolor('#16BA42')

    plt.subplot(2, 2, 4)
    plt.plot(arange(0.0, len(data_list[3]), 1), data_list[3])
    plt.ylabel('[A]')
    plt.xlabel('Samples')
    plt.title('Channel B current')
    plt.grid(True)
    if highlight == '3':
        plt.subplot(2, 2, 4).set_axis_bgcolor('#16BA42')

    plt.subplots_adjust(
        left=0.05, bottom=0.05, right=0.95, top=0.95, wspace=0.15, hspace=0.2)
    manager = plt.get_current_fig_manager()
    manager.resize(*manager.window.maxsize())

    if not os.path.exists(directory):
        os.makedirs(directory)

    figure = plt.gcf()
    figure.set_size_inches(22, 11)
    plt.savefig(directory + '/' + file_name + '.png', dpi=100)
    plt.close()

# plt.show()


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
