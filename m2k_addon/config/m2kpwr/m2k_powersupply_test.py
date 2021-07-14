import unittest
from open_context_and_files import ain, aout, ctx, results_file, ps
import reset_def_values as reset
from ps_functions import ps_test_negative, ps_test_positive, config_for_ps_test, ps_test_negative_with_potentiometer, ps_test_positive_with_potentiometer, switch_to_pot_control, test_external_connector
import ps_functions as ps_functions
import logging
import sys
import time



class A_PowerSupplyTests(unittest.TestCase):
    """Class Where are defined all test methods for Positive PowerSupply and Negative PowerSupply
    """
    @classmethod
    def setUpClass(self):
        #print on the terminal some info 
        #ctx.calibrate()
        logging.getLogger().info("\n\n*** Power Supplies ***\n")

    
        #input() #wait for user input
   # def test_1_external_power_connector(self):
    #    ext_pwr=ps_functions.test_external_connector()
       # with self.subTest(msg='Test if the external connector  works'):
           # self.assertEqual(ext_pwr,'1','The board is supplied')
#
    def test_2_usbTypeC_power_connector(self):

        usb_pwr=ps_functions.test_usbTypeC_connector()
        with self.subTest(msg='Test if the USB type C connector works'):
            self.assertIsNotNone(usb_pwr,'The board is supplied')


    def test_3_enable_m2k(self):
        """Verifies if the Power Supply object was succesfully retrieved from the context
        Enables analog channels to test the output voltages
        """
        reset.analog_in(ain)
        config_for_ps_test(ps, ain)
        state=ps.anyChannelEnabled()
        with self.subTest(msg='Test if the Power Supplies are enabled'):
            self.assertTrue(state,'Power supplies were not enabled')


    def test_4_positive_power_supply(self):
        """Verifies functionality of the positive power supply controlled with m2k
         
        """

        
        pos_supply=ps_test_positive(ps, ain, results_file)
        
        with self.subTest(msg='Test the positive Power Supply '):

            self.assertTrue(all(pos_supply),  'Pos supply values not in range' )

    def test_5_negative_power_supply(self):
        """Verifies the  functionality of the negative power supply controlled with m2k
        """
    
        neg_supply=ps_test_negative(ps, ain,results_file)
        with self.subTest(msg='Test the negative  Power Supply'):
            self.assertTrue(all(neg_supply),  'Neg supply values not in range' )
    
    
    def test_6_disable_m2k(self):
        """Disables power supply channes as they are not further used in this test
        """
        switch_to_pot_control(ps)
        state=ps.anyChannelEnabled()
        
        with self.subTest(msg='Disable M2k power supplies'):
            self.assertFalse(state,  'The supplies were not disabled' )


    def test_7_positive_power_supply_pot(self):
        """Verifies functionality of the positive power supply controlled with the potentiometer
        """
        pos_supply_pot=ps_test_positive_with_potentiometer(ps, ain, results_file)
        with self.subTest(msg='Test the potentiometer control of the positive Power Supply'):

            self.assertEqual(all(pos_supply_pot), 1,  'Pos Supply values not in range' )        
            
    def test_8_negative_power_supply_pot(self):
        """Verifies functionality of the negative power supply controlled with the potentiometer
        """
        neg_supply_pot=ps_test_negative_with_potentiometer(ps, ain,results_file)

        
        with self.subTest(msg='Test the potentiometer control of the negative  Power Supply'):
            self.assertEqual(all(neg_supply_pot), 1,  'Neg supply values not in range' )