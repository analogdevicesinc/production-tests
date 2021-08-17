from open_context_and_files import ain, aout, ctx, results_file, ps
import reset_def_values as reset
from m2kpwr.ps_functions import ps_test_negative, ps_test_positive, config_for_ps_test, ps_test_potentiometer_upper_limit, ps_test_potentiometer_lower_limit, switch_to_pot_control
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
        
        
    def _test_2_pot_lower_limit(self):
        """Verifies functionality of the positive power supply controlled with the potentiometer
        """
        test_ok = True
        test_str = " Test the potentiometers lower limit setting (1.5V and -1.5V)"
        pot_lower_limit=ps_test_potentiometer_lower_limit(ps, ain)
        for i in range(len(pot_lower_limit)):
            if pot_lower_limit[i]:
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
                
        
        return test_ok

         
    def _test_3_pot_upper_limit(self):
        """Verifies functionality of the negative power supply controlled with the potentiometer
        """
        test_ok = True
        test_str = " Test the potentiometers upper limit settig ( 15V and -15V)"
        pot_upper_limit=ps_test_potentiometer_upper_limit(ps, ain)
        for i in range(len(pot_upper_limit)):
            if pot_upper_limit[i]:
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
                
                
        logging.getLogger().info("\n\n\n*** Switch back jumper P6 from POT+ (R20) position to M2K+ position")
        logging.getLogger().info("*** Switch back jumper P7 from POT- (R19) position to M2K- position")
        logging.getLogger().info("*** Make sure the arrow of POT+ points to 1.5V")
        logging.getLogger().info("*** Make sure the arrow of POT+ points to -1.5V")
        logging.getLogger().info("*** Press enter to continue the test")
        input()
        return test_ok
    

    def _test_4_positive_power_supply(self):
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
        

    def _test_5_negative_power_supply(self):
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
    
    
    def _test_6_disable_m2k(self):
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


    

    def run_tests(self):
        self._setUpClass()
        t_res = util_test_wrapper(self._test_1_usbTypeC_power_connector, 1, "Check the USB TypeC")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_2_pot_lower_limit, 2, "Verify potentiometer lower setting")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_3_pot_upper_limit, 3, "Verify potentiometer upper setting")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_4_positive_power_supply, 4, "Verify M2K positive power supply")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_5_negative_power_supply, 5, "Verify M2K negative power supply")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_6_disable_m2k, 6, "Disable M2K power supplies")
        if not t_res:
            return t_res
        return True
