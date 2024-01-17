import libm2k
import time
import numpy as np
import sys
from math import pi
from scipy.signal import find_peaks

def zero_crossings(y_axis, x_axis = None, direction = 1):
    """
    Algorithm to find zero crossings.
    arguments:
    y_axis -- List containg the signal over which to find zero-crossings
    x_axis -- X-axis whose values correspond to the 'y_axis' list.
    direction -- measure crossings only for the specified direction;
              --  1 = on rising edge
              -- -1 = on falling edge
              --  0 = all
    return -- the indice for each zero-crossing
    """
    length = len(y_axis)
    if x_axis == None:
        x_axis = range(length)

    x_axis = np.asarray(x_axis)

    pos = y_axis > 0 # we declare whether 0 counts as positive or negative
    if direction == 1:
        # will count crossings on the rising edge
        # will count 0 based on what we decided above
        zero_crossings = (pos[1:] & ~pos[:-1]).nonzero()[0]
    elif direction == -1:
        # will count crossings on the falling edge
        # will count 0 based on what we decided above
        zero_crossings = (pos[:-1] & ~pos[1:]).nonzero()[0]
    elif direction == 0:
        # V1: will count value 0 as a crossing (even though it was already
        # written down);
        zero_crossings = np.where(np.diff(np.sign(y_axis)))[0]
        # V2: will count 0 based on what we decided above
        # npos = ~pos
        # zero_crossings = ((pos[:-1] & npos[1:]) | (npos[:-1] & pos[1:])).nonzero()[0]


    times = [x_axis[indice] for indice in zero_crossings]
    return times

def peakdetect_zero_crossing(y_axis, x_axis = None, direction = 1):
    """
    arguments:
    y_axis -- List containg the signal over which to find peaks
    x_axis -- X-axis whose values correspond to the 'y_axis' list
    direction -- measure crossings only for the specified direction;
              --  1 = on rising edge
              -- -1 = on falling edge
              --  0 = all
    """
    if x_axis is None:
        x_axis = list(range(len(y_axis)))

    length = len(y_axis)
    if length != len(x_axis):
        raise ValueError('Input vectors must have same length')

    # numpy array
    y_axis = np.asarray(y_axis)

    zero_indices = zero_crossings(y_axis, direction = direction)
    period_lengths = np.diff(zero_indices)

    # Works nice for square signals
    # Does not work for sinewaves or any other classical shapes
    peaks, _ = find_peaks(y_axis, prominence=(None, 0.6))
    return zero_indices, peaks

def main():
    ctx=libm2k.m2kOpen()
    if ctx is None:
        print("Connection Error: No ADALM2000 device available/connected to your PC.")
        exit(1)

    ain=ctx.getAnalogIn()
    aout=ctx.getAnalogOut()
    trig=ain.getTrigger()
    ain.reset()
    aout.reset()

    ctx.calibrateADC()
    ctx.calibrateDAC()

    ain.setKernelBuffersCount(1)
    ain_sr = 100000000
    ain.enableChannel(0,True)
    ain.enableChannel(1,True)
    ain.setSampleRate(ain_sr)
    ain.setRange(0,-10,10) # high or low gain?
    ain.setVerticalOffset(0, 0)
    ain.setVerticalOffset(1, 0)

    nb_samples = 1000

    ### Data acquisition
    data = ain.getSamples(nb_samples)

    ### Computation area
    y = data[0]

    x = np.array(list(range(nb_samples)))

    max_v = max(y)
    min_v = min(y)
    peak2peak = max_v - min_v

    zero_indices, _peaks_idx = peakdetect_zero_crossing(y, x)

    timespan = nb_samples / ain_sr
    sum = 0
    for i in range(len(zero_indices) - 1):
        sum += zero_indices[i+1] - zero_indices[i]
    samps_diff_crossings = sum / (len(zero_indices) - 1)
    timespan_crossings = samps_diff_crossings / ain_sr
    freq = 1 / timespan_crossings

    ### Plot area
    # plt.plot(y, 'b')
    # for i in zero_indices:
    #     plt.plot(i+1, y[i+1], 'go')
    #     plt.plot(i, y[i], 'ro')

    # plt.plot(min_v, 'yo')
    # plt.plot(max_v, 'yo')

    #print("period: " + str(timespan_crossings))
    if peak2peak < 1.3 and len(sys.argv) < 2:
        freq = 0
    print(int(freq))
    # print("max " + str(max_v))
    # # print("min " + str(min_v))
    # print("peak2peak ", str(peak2peak))

    # plt.show()
    libm2k.contextClose(ctx)

main()
