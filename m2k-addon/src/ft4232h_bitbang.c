#include "ft4232h_pin_ctrl.h"
#include "platform_drivers.h"

static const struct map pins[] = {
	{ "PIN0", 0 },
	{ "PIN1", 1 },
	{ "PIN2", 2 },
	{ "PIN3", 3 },
	{ "PIN4", 4 },
	{ "PIN5", 5 },
	{ "PIN6", 6 },
	{ "PIN7", 7 },

	{ "PIN0I", 0 | PIN_IN_MSK },
	{ "PIN1I", 1 | PIN_IN_MSK },
	{ "PIN2I", 2 | PIN_IN_MSK },
	{ "PIN3I", 3 | PIN_IN_MSK },
	{ "PIN4I", 4 | PIN_IN_MSK },
	{ "PIN5I", 5 | PIN_IN_MSK },
	{ "PIN6I", 6 | PIN_IN_MSK },
	{ "PIN7I", 7 | PIN_IN_MSK },
};

int set_pin_values(const char *serial, int channel, char **argv,
		   int from, int to)
{
	struct ftdi_context ftdi = {};
	unsigned char buf[3] = {};
	int i;

	buf[0] = SET_BITS_LOW;
	for (i = from; i < to; i++) {
		int pin = get_pin_val(argv[i]);
		if (pin < 0) {
			fprintf(stderr, "Invalid pin name '%s'\n", argv[i]);
			return EXIT_FAILURE;
		}
		if (pin & PIN_IN_MSK)
			continue;
		pin = 1 << (pin & PIN_NUM_MSK);
		buf[1] |= pin;
		buf[2] |= pin;
	}

	if (open_device(&ftdi, serial, channel))
		return EXIT_FAILURE;

	if (ftdi_set_bitmode(&ftdi, 0xFF, BITMODE_BITBANG) < 0) {
		fprintf(stderr, "Failed to set bitbang mode: %s\n", ftdi_get_error_string(&ftdi));
		return EXIT_FAILURE;
	}

	if (ftdi_write_data(&ftdi, buf, sizeof(buf)) != sizeof(buf)) {
		fprintf(stderr, "Could not set pins: %s\n", ftdi_get_error_string(&ftdi));
		return EXIT_FAILURE;
	}

	close_device(&ftdi);

	return EXIT_SUCCESS;
}

int get_pin_val(const char *name)
{
	return get_int_from_map(pins, ARRAY_SIZE(pins), name);
}

void usage_bitbang()
{
	fprintf(stderr,	"\n\tFor mode Bitbang, specify pins that should be high (pin0 to pin7),\n"
			"\tall other unspecified pins will be set low.\n"
			"\tFor Wait-Gpio, specify a single pin name on which to wait before exiting\n"
		);
}

int handle_mpsse_wait_gpio(const char *serial, int channel, char **argv,
			   int from, int to)
{
	struct ftdi_context ftdi = {};
	uint8_t pin_val = 0;
	uint8_t pin_msk = 0;
	int i, ret;

	if (from >= to) {
		fprintf(stderr, "No pin(s) specified to wait for\n");
		usage_bitbang();
		return EXIT_FAILURE;
	}

	for (i = from; i < to; i++) {
		int pin = get_int_from_map(pins, ARRAY_SIZE(pins), argv[i]);
		if (pin < 0) {
			fprintf(stderr, "Invalid pin name '%s'\n", argv[i]);
			return EXIT_FAILURE;
		}
		pin_msk |= 1 << (pin & PIN_NUM_MSK);
	}

	if (open_device(&ftdi, serial, channel))
		return EXIT_FAILURE;

	while ((ret = ftdi_read_pins(&ftdi, &pin_val)) >= 0) {
		uint8_t pin_val1 = pin_val;
		pin_val = (~pin_val) & pin_msk;
		/* we need to negate `pin_val` ; we get stuff that's active low */
		if (pin_val) {
			printf("Button pressed 0x%02x\n", pin_val);
			printf("Pin states 0x%02x\n", pin_val1);
			break;
		}
		mdelay(100);
	}

	close_device(&ftdi);

	return ret < 0 ? EXIT_FAILURE : EXIT_SUCCESS;
}
