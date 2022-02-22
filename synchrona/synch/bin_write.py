import sys

if(len(sys.argv) < 2):
    print("SERIAL NUMBER NOT PROVIDED")

serialnum = sys.argv[1]
with open("pieeprom-2021-04-29.bin", "r+b") as fh:
    fh.seek(0x7fff0)
    fh.write(serialnum.encode('ascii'))


