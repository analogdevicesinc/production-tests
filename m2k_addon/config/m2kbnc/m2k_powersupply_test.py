import unittest
from open_context_and_files import ain, aout, ctx, results_file, ps
import reset_def_values as reset
from ps_functions import ps_test_negative, ps_test_positive, config_for_ps_test, ps_test_negative_with_potentiometer, ps_test_positive_with_potentiometer, switch_to_pot_control, test_external_connector
import ps_functions as ps_functions
import logging
import sys
import libm2k


class PowerSupplyTests(unittest.TestCase):
    """Class Where are defined all test methods for Positive PowerSupply and Negative PowerSupply
    """
    @classmethod
    def setUpClass(self):
        #print on the terminal some info 
        logging.getLogger().info("\n\nPower Supplies\n")

    
        #input() #wait for user input
   


    def test_1_enable_m2k(self):
        """Verifies if the Power Supply object was succesfully retrieved from the context
        Enables analog channels to test the output voltages
        """
        reset.analog_in(ain)
        config_for_ps_test(ps, ain)
        state=ps.anyChannelEnabled()
        with self.subTest(msg='Test if the Power Supplies are enabled'):
            self.assertTrue(state,'Power supplies were not enabled')


    def test_2_positive_power_supply(self):
        """Verifies functionality of the positive power supply controlled with m2k
         
        """
        logging.getLogger().info("\n*** Positive supply \n")
        logging.getLogger().info("\n*** If LED POS turns on press 1 then press eneter to continue the test \n")
        ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_1, 5)
        pos_supply=input()
        ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_1,False)

        with self.subTest(msg='Test the positive Power Supply '):

            self.assertEqual(pos_supply,str(1),  'Pos supply is not working' )

    def test_3_negative_power_supply(self):
        """Verifies the  functionality of the negative power supply controlled with m2k
        """
        logging.getLogger().info("\n*** Negative supply supply \n")
        logging.getLogger().info("\n*** If LED NEG turns on press 1 then pres enter to continue the test\n")
        ps.pushChannel(libm2k.ANALOG_IN_CHANNEL_2, -5)
        neg_supply=input()
        ps.enableChannel(libm2k.ANALOG_IN_CHANNEL_2,False)
        with self.subTest(msg='Test the negative  Power Supply'):
            self.assertEqual(neg_supply,str(1),  'Neg supply is not working' )
    
    
   