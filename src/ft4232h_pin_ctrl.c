#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <ctype.h>
#include <string.h>
#include <errno.h>
#include <ftdi.h>
#include <arpa/inet.h> /* for ntohs() */

#include "ad7616.h"

#define GNICE_VID 0x0456
#define GNICE_PID 0xf001

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(x) (sizeof(x) / sizeof(*(x)))
#endif

enum {
	CONVST_PIN = GPIOL0,
	RESET_PIN  = GPIOL1,
	BUSY_PIN   = GPIOL3,
};

static const struct option options[] = {
	{"channel", required_argument, 0, 'C'},
	{"serial",  required_argument, 0, 'S'},
	{"mode",    required_argument, 0, 'M'},
	{"vchannel", required_argument, 0, 'V'},
	{ 0, 0, 0, 0 },
};

struct map {
	const char *s;
	unsigned int i;
};

static const struct map pins[] = {
	{ "PIN0", 0 },
	{ "PIN1", 1 },
	{ "PIN2", 2 },
	{ "PIN3", 3 },
	{ "PIN4", 4 },
	{ "PIN5", 5 },
	{ "PIN6", 6 },
	{ "PIN7", 7 },
};

static const struct map modes[] = {
	{ "BITBANG", BITMODE_BITBANG },
	{ "SPI",     BITMODE_MPSSE },
};

static const struct map vchannel_masks[] = {
	{ "V0A", 0 },
	{ "V1A", 1 },
	{ "V2A", 2 },
	{ "V3A", 3 },
	{ "V4A", 4 },
	{ "V5A", 5 },
	{ "V6A", 6 },
	{ "V7A", 7 },

	{ "V0B", 0 << 4 },
	{ "V1B", 1 << 4 },
	{ "V2B", 2 << 4 },
	{ "V3B", 3 << 4 },
	{ "V4B", 4 << 4 },
	{ "V5B", 5 << 4 },
	{ "V6B", 6 << 4 },
	{ "V7B", 7 << 4 },
};

static ad7616_range va_ranges[8] = {
	AD7616_10V, AD7616_10V, AD7616_10V, AD7616_10V,
	AD7616_10V, AD7616_10V, AD7616_10V, AD7616_10V
};
static ad7616_range vb_ranges[8] = {
	AD7616_10V, AD7616_10V, AD7616_10V, AD7616_10V,
	AD7616_10V, AD7616_10V, AD7616_10V, AD7616_10V
};

static inline void copy_to_buf_upper(char *buf, const char *s, int len)
{
	int i;

	strncpy(buf, s, len);
	for (i = 0; i < strlen(buf); i++) {
		buf[i] = toupper(buf[i]);
	}
}

static int get_int_from_map(const struct map *map, int map_len, const char *arg)
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

static int get_idx_from_map(const struct map *map, int map_len, const char *arg)
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

static int open_device(struct ftdi_context *ctx, const char *serial, int channel)
{
	if (ftdi_init(ctx) < 0) {
		fprintf(stderr, "Failed to init ftdi context\n");
		return -1;
	}

	if (ftdi_set_interface(ctx, channel) < 0) {
		fprintf(stderr, "Failed to set channel %d\n", channel);
		return -1;
	}

	if (ftdi_usb_open_desc_index(ctx, GNICE_VID, GNICE_PID, NULL, serial, 0) < 0) {
		fprintf(stderr, "Failed to open device\n");
		return -1;
	}

	return 0;
}

static void close_device(struct ftdi_context *ctx)
{
	/* Note: don't call any of these ; they will reset the values
	   that we've set */
#if 0
	ftdi_set_bitmode(ctx, 0, BITMODE_RESET);
	ftdi_usb_close(ctx);
	ftdi_deinit(ctx);
#endif
}


static int set_pin_values(const char *serial, int channel, char **argv,
			  int from, int to)
{
	struct ftdi_context ftdi = {};
	unsigned char buf[2];
	int i;

	if (open_device(&ftdi, serial, channel)) {
		fprintf(stderr, "Coud not open device\n");
		return -1;
	}

	if (ftdi_set_bitmode(&ftdi, 0xFF, BITMODE_BITBANG) < 0) {
		fprintf(stderr, "Failed to set bitbang mode\n");
		return -1;
	}

	buf[0] = SET_BITS_LOW;
	for (i = from; i < to; i++) {
		int pin = get_int_from_map(pins, ARRAY_SIZE(pins), argv[i]);
		if (pin < 0) {
			fprintf(stderr, "Invalid pin name '%s'\n", argv[i]);
			return -1;
		}
		buf[1] |= 1 << pin;
	}

	if (ftdi_write_data(&ftdi, buf, sizeof(buf)) != sizeof(buf)) {
		fprintf(stderr, "Could not set pins\n");
		return -1;
	}

	close_device(&ftdi);

	return 0;
}

static int wait_busy_is(ad7616_dev *dev, uint8_t busy, int retries)
{
	uint8_t val;
	int timedout = 0;

	while (!timedout) {
		if (gpio_get_value(&dev->gpio_dev, BUSY_PIN, &val) < 0)
			return -1;
		if (busy == val)
			break;
		if (retries-- <= 0) {
			timedout = 1;
			break;
		}
		mdelay(1);
	}

	return timedout ? -1 : 0;
}

int start_conversion(ad7616_dev *dev)
{
	mdelay(1);

	if (gpio_set_value(&dev->gpio_dev, CONVST_PIN, GPIO_HIGH) < 0)
		return -1;

	mdelay(1);

	if (gpio_set_value(&dev->gpio_dev, CONVST_PIN, GPIO_LOW) < 0)
		return -1;

	if (wait_busy_is(dev, 0, 1000) < 0) {
		fprintf(stderr, "Error during BUSY wait\n");
		return -1;
	}

	return 0;
}

static inline int64_t voltage_from_buf(uint8_t *buf)
{
	uint16_t data = (*((uint16_t *)buf));
	return (int64_t) ((int16_t) ntohs(data));
}

static int32_t adc_transfer_function(int64_t voltage, int ch)
{
	int volt_range_enum_val;
	int64_t volt_range = 10;
	int64_t volt_range_div = 1;
	int64_t refinout = 25;
	int64_t refinout_div = 10;

	if (ch > 7)
		volt_range_enum_val = vb_ranges[ch - 8];
	else
		volt_range_enum_val = va_ranges[ch];

	switch (volt_range_enum_val) {
	case AD7616_2V5:
		volt_range = 25;
		volt_range_div = 10;
		break;
	case AD7616_5V:
		volt_range = 5;
		break;
	default: /* is 10V */
		break;
	}

	/* Apply transfer function (page 24 of datasheet):
	     - multiply with 1000 to get mili-Volts
	*/
	voltage = (1000 *
	          voltage * volt_range * /* volt range value is either 2.5, 5 or 10V, depending on how channel was set */
	          refinout * 10) /* 10 is part of 2.5V ==> 25/10 */
	          / (32768 * /* same as in the docs */
	          refinout_div * /* divisor for refinout ; if REFINOUT is 2.495V, refinout is 2495 and refinout_div is 1000 */
	          volt_range_div * /* voltage range div */
	          25); /* 10 is part of 2.5V ==> 25/10 ; we need to divide with 2.5V */

	return voltage;
}

static int handle_single_conversion(ad7616_dev *dev, int vchannel_idx)
{
	uint16_t vchannel_mask = vchannel_masks[vchannel_idx].i;
	uint8_t buf[4] = {}; /* 2 bytes VA, 2 bytes VB */
	int64_t voltage;

	/* Select channel to read from */
	if (ad7616_write_mask(dev, AD7616_REG_CHANNEL, 0x0f, vchannel_mask) < 0) {
		fprintf(stderr, "Unable to select voltage channel 0x%04x\n", (0x1f & vchannel_mask));
		return -1;
	}

	if (start_conversion(dev) < 0)
		return -1;

	/* Read directly from SPI, bypassing ad7616_spi_read()  */
	if (spi_read(&dev->spi_dev, buf, sizeof(buf)) < 0) {
		fprintf(stderr, "Error when reading data from SPI \n");
		return -1;
	}

	if (vchannel_idx > 7)
		voltage = voltage_from_buf(&buf[2]);
	else
		voltage = voltage_from_buf(&buf[0]);

	voltage = adc_transfer_function(voltage, vchannel_idx);

	printf("%d\n", (int32_t)voltage);
	return 0;
}

static int handle_mpsse_spi(const char *serial, int channel, int vchannel_idx)
{
	ad7616_dev *dev = NULL;
	struct ftdi_context ftdi = {};
	static ad7616_init_param init = {
		.gpio_reset = GPIOL1,
		.mode = AD7616_SW,
		.osr = AD7616_OSR_128,
		.spi_mode = SPI_MODE_2,
		.frequency = 1000000,	/* 1 Mhz */
		.endianess = 0x00,	/* MSB = 0x00, LSB = 0x08 */
	};
	int ret = EXIT_FAILURE;

	if (open_device(&ftdi, serial, channel)) {
		fprintf(stderr, "Coud not open device\n");
		return -1;
	}

	memcpy(init.va, va_ranges, sizeof(init.va));
	memcpy(init.vb, vb_ranges, sizeof(init.vb));

	init.ftdi = &ftdi;

	if (ad7616_setup(&dev, &init) < 0) {
		fprintf(stderr, "Could not initialize AD7616 device\n");
		return EXIT_FAILURE;
	}

	if (gpio_set_direction(&dev->gpio_dev, BUSY_PIN, GPIO_IN) < 0) {
		fprintf(stderr, "Error setting BUSY pin direction\n");
		return -1;
	}

	if (handle_single_conversion(dev, vchannel_idx) < 0)
		goto out;

	ret = EXIT_SUCCESS;
out:
	free(dev);
	return ret;
}

static int parse_channel(const char *arg)
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

static int parse_vchannel_idx(const char *arg)
{
	if (!arg)
		return -1;
	return get_idx_from_map(vchannel_masks, ARRAY_SIZE(vchannel_masks), arg);
}

int main(int argc, char **argv)
{
	int c, option_index = 0;
	const char *serial = NULL;
	int channel = -1;
	int vchannel_idx = 0;
	int mode = BITMODE_BITBANG;

	optind = 0;

	while ((c = getopt_long(argc, argv, "+C:S:V:",
					options, &option_index)) != -1) {
		switch (c) {
			case 'C':
				channel = parse_channel(optarg);
				break;
			case 'M':
				mode = parse_mode(optarg);
				break;
			case 'S':
				serial = optarg;
				break;
			case 'V':
				vchannel_idx = parse_vchannel_idx(optarg);
				break;
		}
	}

	if (!serial) {
		fprintf(stderr, "No serial provided for device\n");
		return EXIT_FAILURE;
	}

	if (mode < 0) {
		fprintf(stderr, "Invalid mode set; valid are 'bitbang' or 'spi'\n");
		return EXIT_FAILURE;
	}

	if (vchannel_idx < 0) {
		fprintf(stderr, "Invalid voltage channel name/selection\n");
		return EXIT_FAILURE;
	}

	if (channel < 0) {
		fprintf(stderr, "Invalid or no channel provided\n");
		return EXIT_FAILURE;
	}

	if (mode == BITMODE_MPSSE)
		return handle_mpsse_spi(serial, channel, vchannel_idx);

	/* bitbang mode here */
	if (set_pin_values(serial, channel, argv, optind, argc) < 0) {
		fprintf(stderr, "Error when trying to set GPIO value\n");
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}
