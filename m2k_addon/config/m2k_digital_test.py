import unittest
import libm2k
import logging
from digital_functions import dig_reset, set_digital_trigger,ch_0_7_digital_output,ch_8_15_digital_output
from open_context_and_files import dig, d_trig
from utils import util_yes_no, util_test_wrapper

class DigitalTests():
    """Class where are defined tests for the digital segment
    """
    def _setUpClass(self):
        logging.getLogger().info("\nDIGITAL SEGMENT\n")

    def _test_input8_15_output0_7_digital_channels(self):
        test_ok = True
        ch_8_15_input = ch_0_7_digital_output(dig)

        for i in range(8):
            test_str = " Test output " + str(i) + "; input " + str(i + 8)
            if ch_8_15_input[i] == 1:
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
        return test_ok
               

    def _test_input0_7_output8_15_digital_channels(self):
        test_ok = True
        ch_0_7_input=ch_8_15_digital_output(dig)
        
        for i in range(8):
            test_str = " Test output " + str(i + 8) + "; input " + str(i)
            if ch_0_7_input[i] == 1:
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
        return test_ok


    def run_tests(self):
        self._setUpClass()
        t_res = util_test_wrapper(self._test_input8_15_output0_7_digital_channels, 1, "Digital output 0-7, input 8-15")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_input0_7_output8_15_digital_channels, 2, "Digital output 8-15, input 0-7")
        if not t_res:
            return t_res
        return True

