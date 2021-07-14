import unittest
import libm2k
import logging
from digital_functions import dig_reset, set_digital_trigger,ch_0_7_digital_output,ch_8_15_digital_output
from open_context_and_files import dig, d_trig


class C_DigitalTests(unittest.TestCase):
    """Class where are defined tests for the digital segment
    """
    @classmethod
    def setUpClass(self):
        logging.getLogger().info("Analogical Segment\n")

    # #test signal shapes on  ain ch0
    def test_input8_15_output0_7_digital_channels(self):
        ch_8_15_input=ch_0_7_digital_output(dig)

        for i in range(8):
             with self.subTest(i):
                 self.assertEqual(ch_8_15_input[i],1, "Input channel: "+str(i+8))
               

    def test_input0_7_output8_15_digital_channels(self):
            ch_0_7_input=ch_8_15_digital_output(dig)
            for i in range(8):
                with self.subTest(i):
                    self.assertEqual(ch_0_7_input[i],1, "Input channel: "+str(i))
               



