#
# Copyright (c) 2019 Analog Devices Inc.
#
# This file is part of libm2k
# (see http://www.github.com/analogdevicesinc/libm2k).
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 2.1 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

# This example will generate a binary counter on the first N_BITS of the
# digital interface and read them back - no additional connection required
import time
import libm2k

n_bits=15

m2k1= "ip:192.168.2.1" #ADALM2000-A
m2k2= "ip:192.168.3.1" #ADALM2000-B reconfigured

def pin_check(name, indexw, indexr): 
    
    level=1
    dig.setValueRaw(indexw, level)  
    read_pin= dig2.getValueRaw(indexr)
    # print(name, "=", read_pin)
    if (read_pin==1):
        # print("PIN HIGH OKAY")
        high_check=1
    else: 
        print(name,"PIN HIGH NOT OKAY")
        high_check=0
        failed_tests.append("pin "+ name + " failed")

    # time.sleep(1)

    level=0
    dig.setValueRaw(indexw, level)  
    read_pin= dig2.getValueRaw(indexr)
    # print(name, "=", read_pin)
    if (read_pin==0):
        # print("PIN LOW OKAY")
        low_check=1
    else: 
        print(name, "PIN LOW NOT OKAY")
        low_check=0
        failed_tests.append("pin "+ name + " failed")

    # time.sleep(1)

    if (high_check==1) and (low_check==1):
        print(name, "PASS")
        return failed_tests
    else:
        print(name, "FAIL\n")
        return failed_tests
        


ctx=libm2k.m2kOpen(m2k1)
if ctx is None:
	print("Connection Error: No ADALM2000-A device available/connected to your PC.")
	exit(1)

ctx2=libm2k.m2kOpen(m2k2)
if ctx2 is None:
	print("Connection Error: No ADALM2000-B device available/connected to your PC.")
	exit(1)

dig=ctx.getDigital()
dig.reset()

dig2=ctx2.getDigital()
dig2.reset()

#Setting voltage neede by the FTHR-PMOD-INTZ
#M2K1 for 3V3: connect m2k1 V+ to 3V3 pin of FTHR-PMOD-INTZ, GND to GND 
ps1=ctx.getPowerSupply()
ps1.reset()
ps1.enableChannel(0,True)
ps1.pushChannel(0,3.3)
print("ADALM2000-A voltage supply running with 3V3")

#M2K2 for 5V: connect m2k2 V+ to 5V pin of FTHR-PMOD-INTZ, GND to GND 
ps2=ctx2.getPowerSupply()
ps2.reset()
ps2.enableChannel(0,True)
ps2.pushChannel(0,5)
print("ADALM2000-B voltage supply running with 5V")

dig.setSampleRateIn(10000) #Set the sample rate for all digital input channels.
dig.setSampleRateOut(10000) #Set the sample rate for all digital output channels.

for i in range(n_bits):
    dig.setDirection(i,libm2k.DIO_OUTPUT) #Set the direction of the given digital channel.
    dig.enableChannel(i,True)

failed_tests = []
sn = input("Enter board serial number:")

while(1):
    # pin_check('PIN', 0, 7)
    print("\nTesting SPI pins. . .")
    
    #pin_check(pin_name, m2k_write_pin, m2k_read_pin)
    failed_tests = pin_check('CS', 0, 0)
    failed_tests = pin_check('MOSI', 1, 1)
    failed_tests = pin_check('MISO', 2, 2)
    failed_tests = pin_check('SCLK', 3, 3)
    failed_tests = pin_check('D13', 4, 4)
    failed_tests = pin_check('D12', 5, 5)
    failed_tests = pin_check('D11', 6, 6)
    failed_tests = pin_check('D10', 7, 7)
    
    print("\nTesting I2C pins. . .")

    failed_tests = pin_check('D6_a', 8, 8)
    failed_tests = pin_check('D6_b', 8, 9)
    failed_tests = pin_check('D5_a', 9, 10)
    failed_tests = pin_check('D5_b', 9, 11)
    failed_tests = pin_check('SCL1', 10, 12)
    failed_tests = pin_check('SCL2', 10, 13)
    failed_tests = pin_check('SDA1', 11, 14)
    failed_tests = pin_check('SDA2', 11, 15)

    if len(failed_tests) == 0:
        print("\n\nBoard PASSES!!")
    else:
        print("\n\nBoard FAILED the following tests:")
        for failure in failed_tests:
            print(failure)
        print("\nNote failures and set aside for debug.\nMake sure to secure pin connections with the ADALM2000 before repeating the test.")

    record = open("fthr-pmod-intz_report.csv","a")
    record.write(sn + "," + str(failed_tests) + "\n")
    record.close() 

    next=input("Enter e to end test, r to repeat test:")
    failed_tests = []
    if next=="e":
        del m2k1
        del m2k2
        ps1.pushChannel(0,0)
        ps2.pushChannel(0,0)
        del ps1
        del ps2
        exit()
