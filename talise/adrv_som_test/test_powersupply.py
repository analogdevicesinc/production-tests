#!/user/bin/python

import iio
import sys

def main():
        ctx=iio.LocalContext()
        dev=ctx.find_device('ams')
	
        chn=dev.find_channel(sys.argv[1])
	if (len(sys.argv) == 3):
		voltage_mv=(float(chn.attrs['raw'].value) * float(chn.attrs['scale'].value) * float(sys.argv[3]))
	else:
		voltage_mv=(float(chn.attrs['raw'].value) * float(chn.attrs['scale'].value))

	if (voltage_mv > float(sys.argv[2])) & (voltage_mv < float(sys.argv[3])):
		exit(0)
	else:
		exit(1)
main()
