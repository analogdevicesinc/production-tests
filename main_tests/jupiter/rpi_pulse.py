import RPi.GPIO as GPIO
import time


GPIO.setmode(GPIO.BCM)

GPIO.setup(24, GPIO.OUT)
GPIO.output(24,1)
time.sleep(100/1000)
GPIO.output(24,0)


GPIO.cleanup()
