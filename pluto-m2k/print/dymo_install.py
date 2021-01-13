
import sys
import subprocess

# Check if a supported printer is connected

cmd = "sudo lsusb | grep Dymo-CoStar"
do = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
(output, err) = do.communicate()
status = do.wait()
if status != 0:
	print "No Dymo printer detected. Check the USB connection."
	sys.exit(1)
else:
	printer_name = output.rstrip().split("Dymo-CoStar Corp. ",1)[1]
	print "Detected Printer's Name:", printer_name
	if printer_name != "LabelWriter 450":
		print "This printer is not supported."
		sys.exit(1)

# Find the address of the printer

do = subprocess.Popen("sudo lpinfo -v | grep DYMO", stdout=subprocess.PIPE, shell=True)
(output, err) = do.communicate()
status = do.wait()
if status != 0:
	print "The printer is disconnected. Check the USB connection."
	sys.exit(1)
else:
	printer_address = output.rstrip().split("direct ",1)[1]
	print "Detected Printer's Address:", printer_address

# Configure the detected printer

cmd = "sudo lpadmin -p dymo -v " + printer_address + " -P /usr/share/cups/model/lw450.ppd"
do = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
(output, err) = do.communicate()
status = do.wait()
if status != 0:
	print "Something went wrong configuring the printer."
	sys.exit(1)

# Start the printer

cmd = "sudo cupsenable dymo"
do = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
(output, err) = do.communicate()
status = do.wait()
if status != 0:
	print "Something went wrong starting the printer."
	sys.exit(1)

# Instruct the printer to accept print jobs

cmd = "sudo cupsaccept dymo"
do = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
(output, err) = do.communicate()
status = do.wait()
if status != 0:
	print "Something went wrong accepting jobs."
	sys.exit(1)

# Set this printer as the user's default one

cmd = "sudo lpoptions -d dymo"
do = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
(output, err) = do.communicate()
status = do.wait()
if status != 0:
	print "Something went wrong setting the default printer."
	sys.exit(1)
