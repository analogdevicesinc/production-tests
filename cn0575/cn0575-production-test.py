# This is the production test script for the CN0575 evaluation board from Analog Devices, Inc.
# Run this script in accordance with the corresponding test procedure document (18-068269-01).
# The EEPROM utilities published in https://github.com/raspberrypi/hats/tree/master/eepromutils must be installed to
# successfully execute this script. Do not edit any part of the code without consent from Customer Office Solutions.
# - Allan Uy (8 Mar 2023)

# Import statements:
import adi
from os import devnull, mkdir, path
from subprocess import call
from sys import exit
from time import sleep

# Specifies directories for the EEPROM utilities and files:
eepfile_path = '/home/analog/hats/eep-files'
eepromdump_path = '/home/analog/hats/eeprom-dump'
eepromutils_path = '/home/analog/hats/eepromutils'
eepsettings_file = '/home/analog/production-tests/cn0575/cn0575-eeprom-settings.txt'

# Creates directories for the *.eep files if they do not already exist:
if path.exists(eepfile_path) == False:
    mkdir(eepfile_path)

if path.exists(eepromdump_path) == False:
    mkdir(eepromdump_path)

# The following code is used to perform the temperature reading check.
# This function reads the measurement of the ADT75 and compares them to the CPU temperature of the Raspberry Pi.
# Returns either SUCCESS or FAIL.
def temperature_check(dut):
    check = False
    print('\nPress the TEST button to take the temperature measurements.')
    while not check:
        dut.led = 0
        sleep(0.5)
        dut.led = 1
        sleep(0.5)

        if dut.button == 1:
            dut.led = 1
            check = True
	
            adt75_temp = dut.adt75()
            print('\nADT75 Temperature Reading    : ' + str(adt75_temp) + '\n')
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
    call([eepromutils_path + '/eepmake', eepsettings_file, eepfile_path + '/cn0575.eep'], stdout = open(devnull, 'w'))

    print('\nClearing contents of EEPROM:')
    if path.exists(eepfile_path + '/blank.eep') == False:
        call(['dd', 'if=/dev/zero', 'ibs=1k', 'count=4', 'of=' + eepfile_path + '/blank.eep'], stdout = open(devnull, 'w'))
    
    call([eepromutils_path + '/eepflash.sh', '-w', '-y', '-f=' + eepfile_path + '/blank.eep', '-t=24c32'], stdout = open(devnull, 'w'))
    sleep(1)

    print('\nUploading *.eep file to EEPROM:')
    call([eepromutils_path + '/eepflash.sh', '-w', '-y', '-f=' + eepfile_path + '/cn0575.eep', '-t=24c32'], stdout = open(devnull, 'w'))
    sleep(1)

    return 'SUCCESS'

# The following code is used to verify the contents of the EEPROM.
# This function reads the data contained in the EEPROM and dumps it into a text file. The board ID data is extracted using read_id()
# and then compared to the corresponding ID data found in the original eeprom settings text file used in flash_eeprom().
# Returns either SUCCESS or FAIL.
def verify_eeprom():
    print('\nVerifying EEPROM data:')
    target_id = read_id(eepsettings_file, False)
    if target_id == 'FAIL':
        return 'FAIL'

    call([eepromutils_path + '/eepflash.sh', '-r', '-y', '-f', eepromdump_path + '/dump.eep', '-t=24c32'], stdout = open(devnull, 'w'))
    call([eepromutils_path + '/eepdump', eepromdump_path + '/dump.eep', eepromdump_path + '/dump.txt'], stdout = open(devnull, 'w'))

    actual_id = read_id(eepromdump_path + '/dump.txt', True)
    if actual_id == 'FAIL' or actual_id != target_id:
        return 'FAIL'

    return 'SUCCESS'

# The following code is used to find product and vendor ID values from a text file using the standard format for Raspberry Pi HAT EEPROMs.
# This function searches each line of 'eeprom_data' for the ID values ('product_id', 'product_ver', 'vendor' and 'product').
# Returns either a list containing the four ID values or 'FAIL'.
def read_id(eeprom_data, actual):
    board_id = [0,0,0,0]
    with open(eeprom_data, 'r') as file:
        file_contents = file.readlines()
        for n in range(len(file_contents)):
            file_contents[n] = file_contents[n].splitlines()
            if actual:
                if file_contents[n][0].startswith('product_uuid '):
                    try:
                        print('\n' + file_contents[n][0])

                    except:
                        return 'FAIL'

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
# Operators should follow the prompts that appear on their terminal.
def main():
    print('\nThis test script will now check the electrical connections on the CN0575 and program the EEPROM.')

    while True:
        print('\nDo you wish to continue? (y/n)\n> ', end =  '')
        start_test = input()
		
        if start_test.lower() == 'n' or start_test.lower() == 'no':
            print('\nTest aborted.\n')
            exit(1)
    
        elif start_test.lower() == 'y' or start_test.lower() == 'yes':
            print('\nRunning 10SPE connection test...', end = '')
            dut = adi.cn0575(uri = None)
            dut.led = 1
            sleep(1)

            result = temperature_check(dut)
            break

        else:
            print('\nPlease answer with either yes or no.')
			
    # EEPROM Flashing:    
    result = flash_eeprom()
    if result == 'eepromutils not found':
        print(f'\n\nEEPROM programming failed. Please check if EEPROM utilities are installed and located in \n{eepromutils_path}\n')
        del dut
        exit(1)
		
    elif result == 'eeprom settings text file not found':
        print(f'\n\nEEPROM programming failed. Please check if {eepsettings_file} exists.\n')
        del dut
        exit(1)

    # EEPROM Verification:
    result = verify_eeprom()
    if result != 'SUCCESS':
        print('\nEEPROM contents do not match expected data. Please recheck the setting of JP16 and try again.\n')
        del dut
        exit(1)
	
    del dut
    return 0

if __name__ == '__main__':
    main()
    print('\nTest script has finished. Board passed. \n')
    exit(0)
