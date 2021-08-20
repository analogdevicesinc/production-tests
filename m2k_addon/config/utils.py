import logging 
import unittest

def util_yes_no(user_input):
	response = ""
	if user_input == "":
		out = "Are you sure?\n"
	else:
		out = user_input
	logging.getLogger().info(out)
	logging.getLogger().info("[y/N]")
	response = input()
	response = response.lower()
	if response in ["yes", "y"]:
	   return True
	else:
	   return False
			
def util_test_wrapper(test_method, test_nb, test_name, no_retry = False):
	test_ok = False
	test_str = "TEST " + str(test_nb) + " - " + test_name
	logging.getLogger().info("\n" + test_str)
	while not test_ok:
		test_ok = test_method()
		if not test_ok:
			if no_retry:
				return False
			response = util_yes_no("Test failed. Do you want to repeat the test?")
			if response:
				logging.getLogger().info("\nRETRY " + test_str)
				continue
			else:
				return False
		return True
