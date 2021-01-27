"""Wait for buttons module."""

from time import sleep

import ioxp_adp5589
from gpiozero import LED, Button

buttons = [
    {'id': 17, 'desc': 'START', 'button': None},
    {'id': 27, 'desc': 'SHUTDOWN', 'button': None},
    {'id': 23, 'desc': 'RESTART', 'button': None}
]

for b in buttons:
    b['button'] = Button(b['id'])

USB = LED(12)
USB.off()

while True:
    BUTTON_STATUS = ioxp_adp5589.get_button_status()
    ioxp_adp5589.gpo_set_port_c(['USB_GPO__1', 'LED_2__1'])
    sleep(0.01)
    ioxp_adp5589.gpo_set_port_c(['USB_GPO__0', 'LED_2__0'])
    sleep(0.01)
    if BUTTON_STATUS == '0x0':
        print "GPIO_EXP_BUTTON"
        break
    sleep(0.01)
    for b in buttons:
        if b['button'].is_pressed:
            print b['desc']
            exit(0)
