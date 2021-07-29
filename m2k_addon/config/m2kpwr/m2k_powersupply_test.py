from open_context_and_files import ain, aout, ctx, results_file, ps
import reset_def_values as reset
from m2kpwr.ps_functions import ps_test_negative, ps_test_positive, config_for_ps_test, ps_test_negative_with_potentiometer, ps_test_positive_with_potentiometer, switch_to_pot_control, test_external_connector
import m2kpwr.ps_functions as ps_functions
import logging
import sys
import time
from utils import util_yes_no, util_test_wrapper


class PowerSupplyTests():
    """Class Where are defined all test methods for Positive PowerSupply and Negative PowerSupply
    """
    def _setUpClass(self):
        #print on the terminal some info 
        #ctx.calibrate()
        logging.getLogger().info("\nPOWER SUPPLIES SEGMENT")

 
    def _test_1_usbTypeC_power_connector(self):
        usb_pwr = ps_functions.test_usbTypeC_connector()
        test_str = " Test if the USB type C connector works"
        if not usb_pwr:
            logging.getLogger().info("FAILED:" + test_str)
            return False
        logging.getLogger().info("PASSED:" +  test_str)
        return True

    def _test_2_positive_power_supply(self):
        """Verifies functionality of the positive power supply controlled with m2k
        """
        test_ok = True
        reset.analog_in(ain)
        config_for_ps_test(ps, ain)
        state = ps.anyChannelEnabled()
        test_str = " Power Supplies are not enabled"
        if not state:
            test_ok = False
            logging.getLogger().info("FAILED:" + test_str)

        test_str = " Test the positive Power Supply"
        pos_supply = ps_test_positive(ps, ain)
        for i in range(len(pos_supply)):
            if pos_supply[i]:
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
        return test_ok
        

    def _test_3_negative_power_supply(self):
        """Verifies the  functionality of the negative power supply controlled with m2k
        """
        test_ok = True
        reset.analog_in(ain)
        config_for_ps_test(ps, ain)
        state = ps.anyChannelEnabled()
        test_str = " Power Supplies are not enabled"
        if not state:
            test_ok = False
            logging.getLogger().info("FAILED:" + test_str)

        test_str = " Test the negative Power Supply"
        neg_supply=ps_test_negative(ps, ain)
        for i in range(len(neg_supply)):
            if neg_supply[i]:
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
        return test_ok
    
    
    def _test_4_disable_m2k(self):
        """Disables power supply channes as they are not further used in this test
        """
        test_ok = True
        test_str = " Disable M2k power supplies"
        switch_to_pot_control(ps)
        state = ps.anyChannelEnabled()
        if not state:
            logging.getLogger().info("PASSED:" + test_str)
        else:
            test_ok = False
            logging.getLogger().info("FAILED:" + test_str)
        return test_ok


    def _test_5_positive_power_supply_pot(self):
        """Verifies functionality of the positive power supply controlled with the potentiometer
        """
        test_ok = True
        test_str = " Test the potentiometer control of the positive Power Supply"
        pos_supply_pot=ps_test_positive_with_potentiometer(ps, ain)
        for i in range(len(pos_supply_pot)):
            if pos_supply_pot[i]:
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
        return test_ok

         
    def _test_6_negative_power_supply_pot(self):
        """Verifies functionality of the negative power supply controlled with the potentiometer
        """
        test_ok = True
        test_str = " Test the potentiometer control of the negative Power Supply"
        neg_supply_pot=ps_test_negative_with_potentiometer(ps, ain)
        for i in range(len(neg_supply_pot)):
            if neg_supply_pot[i]:
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
        return test_ok


    def run_tests(self):
        self._setUpClass()
        t_res = util_test_wrapper(self._test_1_usbTypeC_power_connector, 1, "Check the USB TypeC")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_2_positive_power_supply, 2, "Verify M2K positive power supply")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_3_negative_power_supply, 3, "Verify M2K negative power supply")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_4_disable_m2k, 4, "Disable M2K power supplies")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_5_positive_power_supply_pot, 5, "Control positive power supply with the potentiometer")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_6_negative_power_supply_pot, 6, "Control negative power supply with the potentiometer")
        if not t_res:
            return t_res
        return True
