import sys
import libm2k
from shapefile import shape_gen, ref_shape_gen, shape_name
from analog_functions import  test_amplitude, test_shape,  test_offset
from analog_functions import  set_samplerates_for_shapetest
from analog_functions import compare_in_out_frequency
import reset_def_values as reset
from open_context_and_files import ctx, ain, aout, trig
from utils import util_yes_no, util_test_wrapper
import logging

class AnalogTests():
    """Class Where are defined all test methods for AnalogIn, AnalogOut, AnalogTrigger
    
    """
    def _setUpClass(self, is_bnc):
        #print on the terminal some info 
        logging.getLogger().info("\nANALOG SEGMENT")
        #if is_bnc:
         #   logging.getLogger().info("Make sure that BNC cables connect the following:")
          #  logging.getLogger().info("W1 ====> 1+")
          #  logging.getLogger().info("W2 ====> 2+")
          #  logging.getLogger().info("Press enter to continue")
          #  input()


    def _test_1_analog_objects(self):
        """Verify through open_context() function if the analog objects AnalogIn, AnalogOut and Trigger were successfully retrieved.
    """
        test_str = " test if AnalogIn, AnalogOut and Trigger objects were retrieved"
        if not ain or not aout or not trig:
            logging.getLogger().info("FAILED:" + test_str)
            return False
        logging.getLogger().info("PASSED:" +  test_str)
        return True

    # def test_2_calibration(self):

    #     """Verify trough calibrate(ctx) function if the ADC and the DAC were calibrated.
    #     """
    #     with self.subTest(msg='Test if ADC and DAC were succesfully calibrated'):
    #         self.assertEqual(calibration,(True,True),'Calibration failed')


    def _test_2_shapes_ch0(self):
        """Verifies that all the elements of a correlation vector  returned by test_shape() are greater than 0.85.
        A correlation coefficient greater 0.7 indicates that there is a strong positive linear relationship between two signals.
        """
        test_ok = True
        reset.analog_in(ain)
        reset.analog_out(aout)
        reset.trigger(trig)
        out0_buffer_samples, out1_buffer_samples, ch0_sample_ratio, ch1_sample_ratio, in0_buffer_samples, in1_buffer_samples=set_samplerates_for_shapetest(ain, aout)
        shapename=shape_name()#names of generated signals
        buffer0=shape_gen(out0_buffer_samples)
        ref_shape_buf0=ref_shape_gen(in0_buffer_samples)

        #coorrelation coefficient vector for signals acquired on channel0 
        #correlation coeff >0.7 there is a strong positive linear relationship between the 2 signals
        corr_shape_vect0, phase_diff_vect0, timeout_error = test_shape(libm2k.ANALOG_IN_CHANNEL_1, buffer0, ref_shape_buf0, ain, aout,
                                                        trig, ch0_sample_ratio, shapename)

        for i in range(len(corr_shape_vect0)):
            test_str = " sent " + str(shapename[i]) + " signal shape on aout ch0 and received on ain ch0"
            if corr_shape_vect0[i] > 0.85:
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
        return test_ok and not timeout_error


    def _test_3_shapes_ch1(self):
        """Verifies that all the elements of a correlation vector returned by test_shape()  are greater than 0.85.
        """
        test_ok = True
        reset.analog_in(ain)
        reset.analog_out(aout)
        reset.trigger(trig)
        out0_buffer_samples, out1_buffer_samples, ch0_sample_ratio, ch1_sample_ratio, in0_buffer_samples, in1_buffer_samples=set_samplerates_for_shapetest(ain, aout)
        shapename=shape_name()#names of generated signals
        buffer1=shape_gen(out1_buffer_samples)
        ref_shape_buf1=ref_shape_gen(in1_buffer_samples)
        corr_shape_vect1, phase_diff_vect1, timeout_error = test_shape(libm2k.ANALOG_IN_CHANNEL_2, buffer1, ref_shape_buf1, ain, aout,
                                                        trig, ch1_sample_ratio, shapename)
        for i in range(len(corr_shape_vect1)):
            test_str = " sent " + str(shapename[i]) + " signal shape on aout ch1 and received on ain ch1"
            if corr_shape_vect1[i] > 0.85:
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
        return test_ok and not timeout_error


    def _test_4_amplitude(self):
        """Verifies that all the elements of a vector that holds the amplitude coefficients are greater than 0.9. The vector is returned by test_amplitude()
        """
        test_ok = True
        reset.analog_in(ain)
        reset.analog_out(aout)
        reset.trigger(trig)
        out0_buffer_samples, out1_buffer_samples, ch0_sample_ratio, ch1_sample_ratio, in0_buffer_samples, in1_buffer_samples=set_samplerates_for_shapetest(ain, aout)
        buffer0=shape_gen(out0_buffer_samples)
        ref_shape_buf0=ref_shape_gen(in0_buffer_samples)
        buffer1=shape_gen(out1_buffer_samples)
        ref_shape_buf1=ref_shape_gen(in1_buffer_samples)
        amp_coeff_ch0, timeout_error_ch0 = test_amplitude(buffer0[0], ref_shape_buf0[0], in0_buffer_samples, ain, aout,
                                       libm2k.ANALOG_IN_CHANNEL_1, trig)
        amp_coeff_ch1, timeout_error_ch1 = test_amplitude(buffer1[0], ref_shape_buf1[0], in1_buffer_samples, ain, aout,
                                       libm2k.ANALOG_IN_CHANNEL_2, trig)
        amplitude_coefficients=(amp_coeff_ch0, amp_coeff_ch1)

        for i in range(2):
            test_str = " Test different signal amplitudes on ch " + str(i)
            # TODO check if this works fine
            if amplitude_coefficients[i] > (0.9, 0.9):
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
        return test_ok and not timeout_error_ch0 and not timeout_error_ch1

    def _test_5_offset(self):
        """Verifies that all the elements of a vector that holds the offset coefficients are greater than 0.9. The vector is returned by test_offset()
        """
        test_ok = True
        reset.analog_in(ain)
        reset.analog_out(aout)
        reset.trigger(trig)
        out0_buffer_samples, out1_buffer_samples, ch0_sample_ratio, ch1_sample_ratio, in0_buffer_samples, in1_buffer_samples=set_samplerates_for_shapetest(ain, aout)
        buffer0=shape_gen(out0_buffer_samples)
        offset_ch0, timeout_error_ch0 = test_offset(buffer0[0], in0_buffer_samples, ain, aout, trig, libm2k.ANALOG_IN_CHANNEL_1)
        offset_ch1, timeout_error_ch1 = test_offset(buffer0[0], in1_buffer_samples, ain, aout, trig, libm2k.ANALOG_IN_CHANNEL_2)
        offset_coefficients=(offset_ch0, offset_ch1)
        logging.getLogger().info("offset_coefficients")

        logging.getLogger().info(offset_coefficients)

        for i in range(2):
            test_str = " Test different signal offsets on ch " + str(i)
            if offset_coefficients[i] > 0.95:
                logging.getLogger().info("PASSED:" + test_str)
            else:
                test_ok = False
                logging.getLogger().info("FAILED:" + test_str)
                logging.getLogger().info("CHECK JUMPERS POSITION")
        return test_ok and not timeout_error_ch0 and not timeout_error_ch1

    def _test_6_frequency(self):
        """Verifies if a frequency sent on aout channels is the same on ain channels, for different values of the ADC and DAC sample rates.
        Frequencies are compared in compare_in_out_frequency().
        """
        test_ok = True
        reset.analog_in(ain)
        reset.analog_out(aout)
        reset.trigger(trig)   
        timeout_error0, freq_test_ch0 = compare_in_out_frequency(libm2k.ANALOG_IN_CHANNEL_1, ain, aout, trig)
        timeout_error1, freq_test_ch1 = compare_in_out_frequency(libm2k.ANALOG_IN_CHANNEL_2, ain, aout, trig)
        frequency_test = [freq_test_ch0, freq_test_ch1]

        for i in range(2):
            test_str = " Test if in and out frequencies correspond on channel " + str(i)
            for i_freq in range(len(frequency_test[i])):
                if frequency_test[i][i_freq]:
                    logging.getLogger().info("PASSED:" + test_str)
                else:
                    test_ok = False
                    logging.getLogger().info("FAILED:" + test_str)
        return test_ok and not timeout_error0 and not timeout_error1

    def run_tests(self, is_bnc = True):
        self._setUpClass(is_bnc)
        t_res = util_test_wrapper(self._test_1_analog_objects, 1, "Check AnalogIn, AnalogOut & Trigger obj", True)
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_2_shapes_ch0, 2, "Shape tests CH0")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_3_shapes_ch1, 3, "Shape tests CH1")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_4_amplitude, 4, "Amplitude tests for both channels")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_5_offset, 5, "Offset tests for both channels")
        if not t_res:
            return t_res
        t_res = util_test_wrapper(self._test_6_frequency, 6, "Frequency tests for both channels")
        if not t_res:
            return t_res
        return True
    



