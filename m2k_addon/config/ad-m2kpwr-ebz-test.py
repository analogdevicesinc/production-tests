#! /usr/bin/python3
import libm2k
import HtmlTestRunner
import logging
import sys
import RPi.GPIO as GPIO
from m2k_analog_test import AnalogTests
from m2k_digital_test import DigitalTests
from m2kpwr.m2k_powersupply_test import PowerSupplyTests
from open_context_and_files import ctx, results_dir, open_context, create_dir


logger = logging.getLogger()
logger.level = logging.DEBUG
logger.addHandler(logging.StreamHandler(sys.stdout))

def run_test_suite():
    """ Test suite that contains all available tests.
    When run it will create a HTML report of the tests, along with plot files and csv files with results
    """
    m2kbnc_ps_tests = PowerSupplyTests()
    test_ps = m2kbnc_ps_tests.run_tests()
    if not test_ps:
        return test_ps
    
    m2kbnc_analog_tests = AnalogTests()
    test_ain = m2kbnc_analog_tests.run_tests(False)
    if not test_ain:
        return test_ain
    
    m2kbnc_digital_tests = DigitalTests()
    test_dig = m2kbnc_digital_tests.run_tests()
    if not test_dig:
    
        return test_dig
    return True


def main():
    """Main file where tests for all segments are called. The test classes are organized in a test suite.

    """
    logging.getLogger().info("\n*** Connect the AD-M2KPWR-EBZ to the test setup"
                            "\n*** Set the switch S1 on the TEST JIG board in position A" 
                            "\n*** Make sure the jumpers are in positions M2K+ and M2K-"
                            "\n*** Make sure the potentiometers are in positions 1.5V and -1.5V" 
                            "\n*** Press enter to continue the tests")
    input()
    test_result = run_test_suite()
    GPIO.cleanup()
    libm2k.contextClose(ctx, True)
    if not test_result:
        raise ValueError("")

main()
