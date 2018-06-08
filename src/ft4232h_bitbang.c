#include "ft4232h_pin_ctrl.h"

#define PIN_IN_MSK	0x8000
#define PIN_NUM_MSK	0x07

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

	if (open_device(&ftdi, serial, channel))
		return EXIT_FAILURE;

	if (ftdi_set_bitmode(&ftdi, 0xFF, BITMODE_BITBANG) < 0) {
		fprintf(stderr, "Failed to set bitbang mode: %s\n", ftdi_get_error_string(&ftdi));
		return EXIT_FAILURE;
	}

	buf[0] = SET_BITS_LOW;
	for (i = from; i < to; i++) {
		int pin = get_int_from_map(pins, ARRAY_SIZE(pins), argv[i]);
		if (pin < 0) {
			fprintf(stderr, "Invalid pin name '%s'\n", argv[i]);
			return -1;
		}
		buf[1] |= 1 << (pin & PIN_NUM_MSK);
		buf[2] |= (pin & PIN_IN_MSK) ? 0 : (1 << pin);
	}

	if (ftdi_write_data(&ftdi, buf, sizeof(buf)) != sizeof(buf)) {
		fprintf(stderr, "Could not set pins: %s\n", ftdi_get_error_string(&ftdi));
		return EXIT_FAILURE;
	}

	close_device(&ftdi);

	return EXIT_SUCCESS;
}

void usage_bitbang()
{
	fprintf(stderr,	"\n\tFor mode Bitbang, specify pins that should be high (pin0 to pin7),\n"
			"\tall other unspecified pins will be set low.\n"
		);
}
