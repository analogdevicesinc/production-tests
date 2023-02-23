# Test script for [EVAL-CN0577-FMCZ](https://www.analog.com/en/design-center/reference-designs/circuits-from-the-lab/cn0577.html)  

- Program FMC ID EEPROM with serial number. 

- Prompt the test operator to short the input to ground
    - Verify RMS noise less than 0.002 counts. 

- Prompt the user to connect an ADALM2000 test jig to analog inputs. 
- Play back a 90% full-scale sinewave at 20kHz, capture a block of 256k samples per channel.
    - Verify DC component less than 0.1
    - Subtract DC offset from data record, apply window
    - Take FFT of data (via sin_params.py functions), verify:
        - location of fundamental between bin 510 and 514 (correct bin = 512)
        - fundamental amplitude between 2 and 2.8 (correct fundamental amplitude = 2.048)
        - Total Harmonic Distortion less than -65 
        - SNR better than 50  
   - Switch in a 100:1 attenuator, same FFT tests:
        - location of fundamental between bin 510 and 514 (correct bin = 512)
        - fundamental amplitude between 0.012 and 0.014 
        - Total Harmonic Distortion less than -65 
        - SNR better than 35
