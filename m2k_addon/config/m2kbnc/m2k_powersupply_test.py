import unittest
from open_context_and_files import ain, aout, ctx, ps
import reset_def_values as reset
from m2kbnc.ps_functions import ps_test_negative, ps_test_positive, config_for_ps_test, ps_test_negative_with_potentiometer, ps_test_positive_with_potentiometer, switch_to_pot_control, test_external_connector
#import m2kbnc.ps_functions as ps_functions
import logging
import sys
import libm2k
from utils import util_yes_no, util_test_wrapper


class PowerSupplyTests():
    """Class Where are defined all test methods for Positive PowerSupply and Negative PowerSupply
    """
    def _setUpClass(self):
        #print on the terminal some info 
        logging.getLogger().info("\nPOWER SUPPLIES SEGMENT\n")
        #input() #wait for user input
   

    def _test_1_enable_m2k(self):
        """Verifies if the Power Supply object was succesfully retrieved from the context
        Enables analog channels to test the output voltages
        """
        test_ok = True
        reset.analog_in(ain)
        config_for_ps_test(ps, ain)
        state=ps.anyChannelEnabled()
        test_str = " Test if the Power Supplies are enabled"
        if state:
            logging.getLogger().info("PASSED:" + test_str)
        else:
            test_ok = False
            logging.getLogger().info("FAILED:" + test_str)
        return test_ok


    def _test_2_positive_power_supply(self):
        """Verifies functionality of the positive power supply controlled with m2k
         
        """
        test_ok = True
        #logging.getLogger().info("*** Positive supply")
        logging.getLogger().info("*** Is LED POS ON? [Y/n]")
        test_str = " Test the positive Power Supply"
        ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_1, True)
        ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_1, 5)
 
        pos_supply = input()
        pos_supply = pos_supply.lower()
        ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_1, False)
        if pos_supply in ["no", "n"]:
            test_ok = False
            logging.getLogger().info("FAILED:" + test_str)
        else:
            logging.getLogger().info("PASSED:" + test_str)
        return test_ok


    def _test_3_negative_power_supply(self):
        """Verifies the  functionality of the negative power supply controlled with m2k
        """
        test_ok = True
        #logging.getLogger().info("*** Negative supply")
        logging.getLogger().info("*** Is LED NEG ON? [Y/n]")
        test_str = " Test the positive Negative Supply"
        ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_2, True)
        ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_2, -5)
 
        neg_supply = input()
        neg_supply = neg_supply.lower()
        ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_2, False)
        if neg_supply in ["no", "n"]:
            test_ok = False
            logging.getLogger().info("FAILED:" + test_str)
        else:
            logging.getLogger().info("PASSED:" + test_str)
        return test_ok


    def run_tests(self):
        self._setUpClass()
        t_res = util_test_wrapper(self._test_1_enable_m2k, 1, "Power supplies enabled")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_2_positive_power_supply, 2, "Positive power supply")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_3_negative_power_supply, 3, "Negative power supply")
        if not t_res:
            return t_res
        return True
