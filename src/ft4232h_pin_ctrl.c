#include <ctype.h>
#include <getopt.h>

#include "ft4232h_pin_ctrl.h"
#include "ad7616.h"

#define GNICE_VID 0x0456
#define GNICE_PID 0xf001

enum {
	BITBANG,
	SPI_ADC,
	SPI_EEPROM,
	WAIT_GPIO,
};

enum {
	OPT_CHANNEL,
	OPT_SERIAL,
	OPT_MODE,
	OPT_MODE_OPTS,
};

static const struct option options[] = {
	[OPT_CHANNEL] = {"channel", required_argument, 0, 0},
	[OPT_SERIAL]  = {"serial",  required_argument, 0, 0},
	[OPT_MODE]    = {"mode",    required_argument, 0, 0},
	[OPT_MODE_OPTS] = {"opts",  required_argument, 0, 0},

	{ 0, 0, 0, 0 },
};

static const struct map modes[] = {
	{ "BITBANG", BITBANG },
	{ "SPI-ADC", SPI_ADC },
	{ "SPI-EEPROM", SPI_EEPROM },
	{ "WAIT-GPIO", WAIT_GPIO },
};

void copy_to_buf_upper(char *buf, const char *s, int len)
{
	int i;

	strncpy(buf, s, len);
	for (i = 0; i < strlen(buf); i++) {
		buf[i] = toupper(buf[i]);
	}
}

int get_int_from_map(const struct map *map, int map_len, const char *arg)
{
	int i;
	char buf[16];

	if (!arg || !map)
		return -1;

	copy_to_buf_upper(buf, arg, sizeof(buf));

	for (i = 0; i < map_len; i++) {
		if (!strcmp(map[i].s, buf))
			return map[i].i;
	}

	return -1;
}

int get_idx_from_map(const struct map *map, int map_len, const char *arg)
{
	int i;
	char buf[16];

	if (!arg || !map)
		return -1;

	copy_to_buf_upper(buf, arg, sizeof(buf));

	for (i = 0; i < map_len; i++) {
		if (!strcmp(map[i].s, buf))
			return i;
	}

	return -1;
}

int open_device(struct ftdi_context *ctx, const char *serial, int channel)
{
	if (ftdi_init(ctx) < 0) {
		fprintf(stderr, "Failed to init ftdi context: %s\n", ftdi_get_error_string(ctx));
		return -1;
	}

	if (ftdi_set_interface(ctx, channel) < 0) {
		fprintf(stderr, "Failed to set channel %d: %s\n", channel, ftdi_get_error_string(ctx));
		return -1;
	}

	if (ftdi_usb_open_desc_index(ctx, GNICE_VID, GNICE_PID, NULL, serial, 0) < 0) {
		fprintf(stderr, "Failed to open device: %s\n",ftdi_get_error_string(ctx));
		return -1;
	}

	return 0;
}

void close_device(struct ftdi_context *ctx)
{
	/* Note: don't call any of these ; they will reset the values
	   that we've set */
#if 0
	ftdi_set_bitmode(ctx, 0, BITMODE_RESET);
	ftdi_usb_close(ctx);
	ftdi_deinit(ctx);
#endif
}

int parse_channel(const char *arg)
{
	char c;
	if (!arg)
		return -1;

	c = *arg;
	if (c >= 'a' && c <= 'd')
		return (c - 'a' + 1);

	if (c >= 'A' && c <= 'D')
		return (c - 'A' + 1);

	return -1;
}

static int parse_mode(const char *arg)
{
	if (!arg)
		return -1;
	return get_int_from_map(modes, ARRAY_SIZE(modes), arg);
}

static void usage()
{
	fprintf(stderr, "ft4232h_pin_ctrl --serial <serial> --channel <X> --mode <bitbang|spi-adc|spi-eeprom|wait-gpio>\n"
			"\tWhere: X is A-to-D, the channel on the FTDI device\n");
	usage_bitbang();
	usage_spi_adc();
	usage_spi_eeprom();
}

int main(int argc, char **argv)
{
	int option_index = 0;
	const char *serial = NULL;
	char *subopts = NULL;
	int channel = -1;
	int ret;
	int mode = -1;

	optind = 0;

	while (getopt_long_only(argc, argv, "", options, &option_index) != -1) {
		switch (option_index) {
			case OPT_SERIAL:
				serial = optarg;
				break;
			case OPT_MODE:
				mode = parse_mode(optarg);
				break;
			case OPT_MODE_OPTS:
				subopts = optarg;
				break;
			case OPT_CHANNEL:
				channel = parse_channel(optarg);
				break;
		}
	}

	if (!serial) {
		fprintf(stderr, "No serial provided for device\n");
		usage();
		return EXIT_FAILURE;
	}

	if (channel < 0) {
		fprintf(stderr, "Invalid or no FTDI channel provided\n");
		usage();
		return EXIT_FAILURE;
	}

	switch (mode) {
		case BITBANG:
			ret = set_pin_values(serial, channel, argv, optind, argc);
			break;
		case SPI_ADC:
			ret = handle_mpsse_spi_adc(serial, channel, subopts);
			break;
		case SPI_EEPROM:
			ret = handle_mpsse_spi_eeprom(serial, channel, subopts);
			break;
		case WAIT_GPIO:
			if (optind >= argc) {
				usage();
				break;
			}
			ret = handle_mpsse_wait_gpio(serial, channel, argv, optind, argc);
			break;
		default:
			fprintf(stderr, "Invalid mode; valid are <bitbang|spi-adc|spi-eeprom>\n");
			ret = EXIT_FAILURE;
			break;
	}
	if (ret != EXIT_SUCCESS)
		usage();

	return ret;
}
