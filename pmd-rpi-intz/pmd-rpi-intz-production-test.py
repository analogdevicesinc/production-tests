# This is the production test script for the PMD-RPI-INTZ evaluation board from Analog Devices, Inc.
# Run this script in accordance with the corresponding test procedure document (18-065962-01).
# The EEPROM utilities published in https://github.com/raspberrypi/hats/tree/master/eepromutils must be installed to
# successfully execute this script. Do not edit any part of the code without consent from Customer Office Solutions.
# - Allan Uy (3 Jan 2022)

# Import statements:
from gpiozero import InputDevice, OutputDevice
from os import devnull, mkdir, path
from subprocess import call
from sys import exit
from time import sleep

# Programs the following GPIO pins as Input. Two sets (A and B) are used to alternate high and low between adjacent pins.
read = []
input_pins_A = (19,20,25,5,26,27)
for n in range(len(input_pins_A)):
    read.append(InputDevice(input_pins_A[n]))

input_pins_B = (21,18,12,6,13,17,22,4)
for n in range(len(input_pins_B)):
    read.append(InputDevice(input_pins_B[n]))

# Programs the following GPIO pins as Output. Two sets (A and B) are used to alternate high and low between adjacent pins.
write = []
output_pins_A = (8,9,7,3)
for n in range(len(output_pins_A)):
    write.append(OutputDevice(output_pins_A[n]))

output_pins_B = (10,11,2)
for n in range(len(output_pins_B)):
    write.append(OutputDevice(output_pins_B[n]))

# Specifies directories for the EEPROM utilities and files:
eepfile_path = '/home/analog/hats/eep-files'
eepromdump_path = '/home/analog/hats/eeprom-dump'
eepromutils_path = '/home/analog/hats/eepromutils'
eepsettings_file = '/home/analog/production-tests/pmd-rpi-intz/pmd-rpi-intz-eeprom-settings.txt'

# Creates directories for the *.eep files if they do not already exist:
if path.exists(eepfile_path) == False:
    mkdir(eepfile_path)

if path.exists(eepromdump_path) == False:
    mkdir(eepromdump_path)

# The following code is used to perform the GPIO connectivity test.
# This function reads the logic level at each input pin and compares them to their expected states.
# The value of 'test_number' is used to determine the expected state for each pin (1: A = High, B = Low; 2: A = Low, B = High).
# Returns either SUCCESS or the GPIO number of a failing pin.
def connection_check(test_number):
    if test_number == 1:
        for n in range(len(read)):
            if n < len(input_pins_A) and read[n].value != 1:
                return input_pins_A[n]

            elif n >= len(input_pins_A) and read[n].value != 0:
                return input_pins_B[n - len(input_pins_A)]

    elif test_number == 2:
        for n in range(len(read)):
            if n < len(input_pins_A) and read[n].value != 0:
                return input_pins_A[n]

            elif n >= len(input_pins_A) and read[n].value != 1:
                return input_pins_B[n - len(input_pins_A)]

    return 'SUCCESS'

# The following code is used to flash the EEPROM of the PMD-RPI-INTZ.
# This function generates an *.eep file based on the eeprom settings file, clears any existing data in the EEPROM 
# and then flashes it with the data from the *.eep file. Returns either SUCCESS or a 'file not found' error message.
def flash_eeprom():
    print('Generating *.eep file...', end = '')
    if path.exists(eepromutils_path + '/eepflash.sh') == False or path.exists(eepromutils_path + '/eepmake') == False:
        return 'eepromutils not found'

    elif path.exists(eepsettings_file) == False:
        return 'eeprom settings text file not found'

    sleep(1)
    print('.............OK!')
    call([eepromutils_path + '/eepmake', eepsettings_file, eepfile_path + '/pmd_rpi_intz.eep'], stdout = open(devnull, 'w'))

    print('\nClearing contents of EEPROM:')
    if path.exists(eepfile_path + '/blank.eep') == False:
        call(['dd', 'if=/dev/zero', 'ibs=1k', 'count=4', 'of=' + eepfile_path + '/blank.eep'], stdout = open(devnull, 'w'))
    
    call([eepromutils_path + '/eepflash.sh', '-w', '-y', '-f=' + eepfile_path + '/blank.eep', '-t=24c32'], stdout = open(devnull, 'w'))
    sleep(1)

    print('\nUploading *.eep file to EEPROM:')
    call([eepromutils_path + '/eepflash.sh', '-w', '-y', '-f=' + eepfile_path + '/pmd_rpi_intz.eep', '-t=24c32'], stdout = open(devnull, 'w'))
    sleep(1)

    return 'SUCCESS'

# The following code is used to verify the contents of the EEPROM.
# This function reads the data contained in the EEPROM and dumps it into a text file. The board ID data is extracted using read_id()
# and then compared to the corresponding ID data found in the original eeprom settings text file used in flash_eeprom().
# Returns either SUCCESS or FAIL.
def verify_eeprom():
    print('\nVerifying EEPROM data:')
    target_id = read_id(eepsettings_file)
    if target_id == 'FAIL':
        return 'FAIL'

    call([eepromutils_path + '/eepflash.sh', '-r', '-y', '-f', eepromdump_path + '/dump.eep', '-t=24c32'], stdout = open(devnull, 'w'))
    call([eepromutils_path + '/eepdump', eepromdump_path + '/dump.eep', eepromdump_path + '/dump.txt'], stdout = open(devnull, 'w'))

    actual_id = read_id(eepromdump_path + '/dump.txt')
    if actual_id == 'FAIL' or actual_id != target_id:
        return 'FAIL'

    return 'SUCCESS'

# The following code is used to find product and vendor ID values from a text file using the standard format for Raspberry Pi HAT EEPROMs.
# This function searches each line of 'eeprom_data' for the ID values ('product_id', 'product_ver', 'vendor' and 'product').
# Returns either a list containing the four ID values or 'FAIL'.
def read_id(eeprom_data):
    board_id = [0,0,0,0]
    with open(eeprom_data, 'r') as file:
        file_contents = file.readlines()
        for n in range(len(file_contents)):
            file_contents[n] = file_contents[n].splitlines()
            if file_contents[n][0].startswith('product_id '):
                try:
                    id_index = file_contents[n][0].index('0x')

                except:
                    return 'FAIL'

                board_id[0] = file_contents[n][0][id_index:id_index + 6]

            elif file_contents[n][0].startswith('product_ver '):
                try:
                    id_index = file_contents[n][0].index('0x')

                except:
                    return 'FAIL'

                board_id[1] = file_contents[n][0][id_index:id_index + 6]

            elif file_contents[n][0].startswith('vendor '):
                try:
                    id_index = file_contents[n][0].index('"') + 1
                    id_rindex = file_contents[n][0].rindex('"')

                except:
                    return 'FAIL'

                board_id[2] = file_contents[n][0][id_index:id_rindex]

            elif file_contents[n][0].startswith('product '):
                try:
                    id_index = file_contents[n][0].index('"') + 1
                    id_rindex = file_contents[n][0].rindex('"')

                except:
                    return 'FAIL'

                board_id[3] = file_contents[n][0][id_index:id_rindex]

    return board_id

# The following code is the start of the main test.
# Operators should enter yes/no (case sensitive) for each prompt. This is the same format used by eepromutils.
def main():
    print('\nThis test script will now check the elctrical connections on the PMD-RPI-INTZ\nand program the EEPROM. Please ensure that the test jig is connected to the\nboard under test, as shown in the test procedure (18-065962-01).')

    while True:
        print('\nDo you wish to continue? (y/n)\n> ', end =  '')
        start_test = input()

        if start_test.lower() == 'n' or start_test.lower() == 'no':
            print('\nTest aborted.\n')
            exit(1)
    
        elif start_test.lower() == 'y' or start_test.lower() == 'yes':
            print('\nRunning connectivity check...', end = '')

            # Connectivity Check No. 1 (A Pins = High; B Pins = Low):
            for n in range(len(output_pins_A)):
                write[n].on()

            for n in range(len(output_pins_B)):
                write[len(output_pins_A) + n].off()

            result = connection_check(1)
            if result in input_pins_A:
                print('\n\nTest failed at GPIO' + str(result) + ' (expected high).\nPlease recheck hardware connections and try again.\n')
                exit(1)

            elif result in input_pins_B:
                print('\n\nTest failed at GPIO' + str(result) + ' (expected low).\nPlease recheck hardware connections and try again.\n')
                exit(1)

            sleep(1)

            # Connectivity Check No. 2 (A Pins = Low; B Pins = High):
            for n in range(len(output_pins_A)):
                write[n].off()

            for n in range(len(output_pins_B)):
                write[len(output_pins_A) + n].on()

            result = connection_check(2)
            if result in input_pins_A:
                print('\n\nTest failed at GPIO' + str(result) + ' (expected low).\nPlease recheck hardware connections and try again.\n')
                exit(1)

            elif result in input_pins_B:
                print('\n\nTest failed at GPIO' + str(result) + ' (expected high).\nPlease recheck hardware connections and try again.\n')
                exit(1)

            sleep(1)
            print('........OK!')
            break

        else:
            print('\nPlease answer with either yes or no.')

    # EEPROM Flashing:    
    result = flash_eeprom()
    if result == 'eepromutils not found':
        print(f'\n\nEEPROM programming failed. Please check if EEPROM utilities are installed and located in \n{eepromutils_path}\n')
        exit(1)

    elif result == 'eeprom settings text file not found':
        print(f'\n\nEEPROM programming failed. Please check if {eepsettings_file} exists.\n')
        exit(1)

    # EEPROM Verification:
    result = verify_eeprom()
    if result != 'SUCCESS':
        print('\nEEPROM contents do not match expected data. Please recheck the setting of JP26 and try again.\n')
        exit(1)

    return 0

if __name__ == '__main__':
    main()
    print('\nTest script has finished.\n')
    exit(0)
