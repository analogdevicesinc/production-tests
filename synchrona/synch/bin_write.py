import sys

if(len(sys.argv) < 2):
    print("SERIAL NUMBER NOT PROVIDED")
    exit()

serialnum = sys.argv[1]
with open("pieeprom-2021-07-06.bin", "r+b") as fh:
    fh.seek(0x7ffe0)
    fh.write(serialnum.encode('ascii'))

