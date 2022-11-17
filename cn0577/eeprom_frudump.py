# importing os module 
import os

def input_data(sn):
    path_EEPROM ="/sys/devices/soc0/fpga-axi@0/41620000.i2c/i2c-1/1-0050/eeprom"
    path_masterfile = "cn0577master.bin"

    os.system('fru-dump -i '+ path_masterfile + " -o " + path_EEPROM + " -s " + sn)
    # print("Succesfully loaded the FMC ID EEPROM with serial number:" + sn)
