import libm2k
import time
import numpy as np
import math
import sys
from scipy import signal

available_sample_rates= [750, 7500, 75000, 750000, 7500000, 75000000]
max_rate = available_sample_rates[-1] # last sample rate = max rate
min_nr_of_points=10
max_buffer_size = 500000
digital_ch=1                                                                                                                                                                  
clock_ch = 0


def get_best_ratio(ratio):
    max_it=max_buffer_size/ratio
    best_ratio=ratio
    best_fract=1

    for i in range(1,int(max_it)):
        new_ratio = i*ratio
        (new_fract, _) = math.modf(new_ratio)
        if new_fract < best_fract:
            best_fract = new_fract
            best_ratio = new_ratio
        if new_fract == 0:
            break

    return best_ratio,best_fract


def get_samples_count(rate, freq):
    ratio = rate/freq
    if ratio<min_nr_of_points and rate < max_rate:
        return 0
    if ratio<2:
        return 0

    ratio,fract = get_best_ratio(ratio)
    # ratio = number of periods in buffer
    # fract = what is left over - error

    size=int(ratio)
    while size & 0x03:
        size=size<<1
    while size < 1024:
        size=size<<1
    return size

def get_optimal_sample_rate(freq):
    for rate in available_sample_rates:
        buf_size = get_samples_count(rate,freq)
        if buf_size:
            return rate

def square_buffer_generator(channel, freq, ampl, offset, phase):
    buffer = []
    sample_rate = get_optimal_sample_rate(freq)
    nr_of_samples = get_samples_count(sample_rate, freq)
    samples_per_period = sample_rate / freq
    phase_in_samples = ((phase/360) * samples_per_period)
    for i in range(nr_of_samples):
       samp = math.sin(((i + phase_in_samples)/samples_per_period) * 2*math.pi)
       #samp = signal.square()
       buffer.append(offset + ampl * (1 if samp > 0 else 0))
    #print("Generating done")
    return sample_rate, buffer


# def pps_buffer_generator(channel, freq, ampl, offset, phase):
#     buffer = []
#     duty_idx = 0
#     sample_rate = get_optimal_sample_rate(freq)
#     nr_of_samples = get_samples_count(sample_rate, freq)
#     nr_of_samples = 750
#     samples_per_period = sample_rate / freq
#     print(sample_rate)
#     print(nr_of_samples)
#     t = np.linspace(offset, ampl, nr_of_samples, endpoint=True)
#     buffer = signal.square(2*np.pi*freq*t, duty=0.01)
#     duty = samples_per_period / 100
#     phase_in_samples = ((phase/360) * samples_per_period)
#     for i in range(nr_of_samples):
#        samp = math.sin(((i + phase_in_samples)/samples_per_period) * 2*math.pi)
#        buffer.append(offset + ampl * (1 if samp >= 0 and duty_idx < int(duty) else 0))
#        duty_idx = (duty_idx + 1) if samp > 0 else 0
#     print(buffer)
#     return sample_rate, buffer

def pps2_buffer_generator(channel, freq, ampl, offset, phase, duty=50):
    buffer = []
    duty_idx = 0
    sample_rate = max_rate
    osr = max_rate / get_optimal_sample_rate(freq)
    nr_of_samples = get_samples_count(sample_rate/osr, freq)
    samples_per_period = (sample_rate / osr) / freq
    nr_samples_duty = samples_per_period * (duty / 100) #2% duty
    phase_in_samples = ((phase/360) * samples_per_period)

    # print("samps per period " + str(samples_per_period))
    # print("nr of samples " + str(nr_of_samples))
    # print("nr of duty samples " + str(nr_samples_duty))
    # print("sample_rate " + str(sample_rate))
    # print("freq " + str(freq))
    # print("osr " + str(osr))
    t = []
    for i in range(nr_of_samples):
        t.append(i / (sample_rate / osr))
    t =  np.array(t)
    buffer = offset + ampl * (signal.square(2 * np.pi * freq * t, duty=(duty / 100)) / 2 + 0.5)
    return sample_rate, buffer, osr

def sin_buffer_generator(channel, freq, ampl, offset, phase):
    buffer = []
    sample_rate = get_optimal_sample_rate(freq)
    nr_of_samples = get_samples_count(sample_rate, freq)
    samples_per_period = sample_rate / freq
    phase_in_samples = ((phase/360) * samples_per_period)
    for i in range(nr_of_samples):
       samp = math.sin(((i + phase_in_samples)/samples_per_period) * 2*math.pi)
       buffer.append(offset + ampl * samp)
    #print("Generating done")
    return sample_rate, buffer

ctx = libm2k.m2kOpen()
aout = ctx.getAnalogOut()
dig = ctx.getDigital()

# Prevent bad initial config
dig.reset()
aout.reset()

ctx.calibrateADC()
ctx.calibrateDAC()

# AnalogOut setup
aout.setCyclic(True)
aout.enableChannel(clock_ch, True)

if(len(sys.argv) < 2):
    print("Usage: python3 m2k-test.py [sig_mod]")
    print("Where [sig_mod] from [ sin | pps | sqr ]")
    sleep_time=0
else:
    if sys.argv[1] == "pps":
        samp_rate, buffer, osr = pps2_buffer_generator(0, 1, 3, 0, 0, 1)
        sleep_time=12
        aout.setOversamplingRatio(clock_ch, int(osr))
    elif sys.argv[1] == "sin":
        samp_rate, buffer =  sin_buffer_generator(0, 10000000, 1.2, 0.6, 0)
        sleep_time=5
        aout.setOversamplingRatio(clock_ch, 1)
    elif sys.argv[1] == "sqr":
        samp_rate, buffer = sin_buffer_generator(0, 10000000, 1.8, 0.9, 0)
        sleep_time=7
        aout.setOversamplingRatio(clock_ch, 1)
    else:
        print("Usage [sig_mod] from [ sin | pps | sqr ]")
    
    aout.setSampleRate(clock_ch, samp_rate)
    aout.push(clock_ch, buffer)
    
time.sleep(sleep_time)

aout.stop()
libm2k.contextClose(ctx)
