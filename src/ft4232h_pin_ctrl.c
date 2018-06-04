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

#define ALL_CHANNELS	0xffff

#define PRECISION_MULT		10000	/* 0.1 mV or 100 uV */
#define PRECISION_FMT		"%04d"	/* correlate this with PRECISION_MULT */

#define BURST_EN	(AD7616_BURSTEN | AD7616_SEQEN)

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
	{"refinout", required_argument, 0, 'R'},
	{"vrange-each", required_argument, 0, 'E'},
	{"vrange-all", required_argument, 0, 'A'},
	{"no-samples", required_argument, 0, 'N'},
	{"voffset",   required_argument, 0, 'O'},
	{"gain",      required_argument, 0, 'G'},
	{"self-test", no_argument, 0, 'T'},
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

	{ "ALL", ALL_CHANNELS },
};

struct spi_read_args {
	int vchannel_idx;
	int refinout;
	int refinout_div;
	int samples;
	int voffset;
	int voffset_div;
	int gain;
	int gain_div;
	int self_test;
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
	unsigned char buf[3] = {};
	int i;

	if (open_device(&ftdi, serial, channel))
		return -1;

	if (ftdi_set_bitmode(&ftdi, 0xFF, BITMODE_BITBANG) < 0) {
		fprintf(stderr, "Failed to set bitbang mode: %s\n", ftdi_get_error_string(&ftdi));
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
		buf[2] |= 1 << pin;
	}

	if (ftdi_write_data(&ftdi, buf, sizeof(buf)) != sizeof(buf)) {
		fprintf(stderr, "Could not set pins: %s\n", ftdi_get_error_string(&ftdi));
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

static int do_conversion(ad7616_dev *dev, uint8_t *buf, int buf_len)
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

	/* Read directly from SPI, bypassing ad7616_spi_read()  */
	if (spi_read(&dev->spi_dev, buf, buf_len) < 0) {
		fprintf(stderr, "Error when reading data from SPI \n");
		return -1;
	}

	return 0;
}

static inline int dummy_conversion(ad7616_dev *dev)
{
	uint8_t buf[4 * 32];
	return do_conversion(dev, buf, sizeof(buf));
}

static inline int64_t voltage_from_buf(uint8_t *buf)
{
	uint16_t data = (*((uint16_t *)buf));
	return (int64_t) ((int16_t) ntohs(data));
}

static int32_t adc_transfer_function(int64_t voltage, int ch, const struct spi_read_args *sargs)
{
	int volt_range_enum_val;
	int64_t volt_range = 10;
	int64_t volt_range_div = 1;
	int64_t voffset_div = sargs->voffset_div;
	int64_t refinout = sargs->refinout;
	int64_t refinout_div = sargs->refinout_div;
	int64_t gain = sargs->gain;
	int64_t gain_div = sargs->gain_div;

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

	if (refinout_div == 0)
		refinout_div = 1;
	if (voffset_div == 0)
		voffset_div = 1;
	if (gain_div == 0)
		gain_div = 1;

	/* Apply transfer function (page 24 of datasheet):
	     - multiply with 1000 to get mili-Volts
	*/
	voltage = (PRECISION_MULT *
	          voltage * volt_range * /* volt range value is either 2.5, 5 or 10V, depending on how channel was set */
	          refinout * 10) /* 10 is part of 2.5V ==> 25/10 */
	          / (32768 * /* same as in the docs */
	          refinout_div * /* divisor for refinout ; if REFINOUT is 2.495V, refinout is 2495 and refinout_div is 1000 */
	          volt_range_div * /* voltage range div */
	          25); /* 10 is part of 2.5V ==> 25/10 ; we need to divide with 2.5V */

	/* Apply offset */
	voltage += (sargs->voffset * PRECISION_MULT) / voffset_div;
	voltage = (voltage * gain) / gain_div;

	return voltage;
}

static int handle_single_conversion(ad7616_dev *dev, const struct spi_read_args *sargs)
{
	int vchannel_idx = sargs->vchannel_idx;
	uint16_t vchannel_mask = vchannel_masks[vchannel_idx].i;
	uint16_t vchannel_clr_mask;
	uint8_t buf[8] = {}; /* 2 bytes VA, 2 bytes VB */
	int64_t voltage, voltage_abs;
	int i;
	int samples = sargs->samples;

	if (vchannel_idx > 7)
		vchannel_clr_mask = 0xf0;
	else
		vchannel_clr_mask = 0x0f;

	if (ad7616_write_mask(dev, AD7616_REG_CONFIG, BURST_EN, 0) < 0) {
		fprintf(stderr, "Unable to disable burst mode\n");
		return -1;
	}

	/* Select channel to read from */
	if (ad7616_write_mask(dev, AD7616_REG_CHANNEL, vchannel_clr_mask, vchannel_mask) < 0) {
		fprintf(stderr, "Unable to select voltage channel 0x%04x\n", (0x1f & vchannel_mask));
		return -1;
	}

	if (dummy_conversion(dev) < 0) {
		fprintf(stderr, "Error while doing dummy conversion\n");
		return -1;
	}

	voltage = 0;
	for (i = 0; i < samples; i++) {
		if (do_conversion(dev, buf, sizeof(buf)) < 0) {
			fprintf(stderr, "Error while doing conversion\n");
			return -1;
		}

		if (vchannel_idx > 7 && i == 1) {
			samples++;
			continue;
		}

		if (vchannel_idx > 7) {
			int b_idx = (i == 0) ? 2 : 4;
			voltage += voltage_from_buf(&buf[b_idx]);
		} else
			voltage += voltage_from_buf(&buf[0]);
	}
	voltage = voltage / (int64_t)sargs->samples;
	voltage = adc_transfer_function(voltage, vchannel_idx, sargs);
	voltage_abs = voltage < 0 ? -voltage : voltage;

	printf("%s%d."PRECISION_FMT"\n", voltage < 0 ? "-" : "",
		(int32_t)(voltage_abs / PRECISION_MULT),
		(int32_t)(voltage_abs % PRECISION_MULT));
	return 0;
}

static int handle_burst_conversion(ad7616_dev *dev, const struct spi_read_args *sargs)
{
	uint8_t buf[8 * 8] = {}; /* (2 bytes VA, 2 bytes VB) x 8 */
	int i, j;
	int64_t voltages[16] = {};
	int64_t voltage_abs;
	int samples = sargs->samples;

	/* We setup the sequencer ; it can a pair of VA & VB at the same time */
	for (i = 0; i < 7; i++)
		ad7616_write(dev, AD7616_REG_SEQUENCER_STACK(i), i | (i << 4));
	/* Last register needs SSREN bit set */
	ad7616_write(dev, AD7616_REG_SEQUENCER_STACK(7), 7 | (7 << 4) | AD7616_SSREN);

	if (ad7616_write_mask(dev, AD7616_REG_CONFIG, BURST_EN, BURST_EN) < 0) {
		fprintf(stderr, "Unable to enable burst mode\n");
		return -1;
	}

	if (dummy_conversion(dev) < 0) {
		fprintf(stderr, "Error while doing dummy conversion\n");
		return -1;
	}

	/* Collect samples of voltages */
	for (i = 0; i < samples; i++) {
		if (do_conversion(dev, buf, sizeof(buf)) < 0) {
			fprintf(stderr, "Error while doing conversion\n");
			return -1;
		}

		if (i == 1) {
			samples++;
			continue;
		}

		for (j = 0; j < 8; j++) {
			int b_idx = (j * 4) + ((i == 0) ? 2 : 4);
			voltages[j] += voltage_from_buf(&buf[j * 4]);		/* VA voltages */
			voltages[j + 8] += voltage_from_buf(&buf[b_idx]);	/* VB voltages */
		}
	}

	for (i = 0; i < ARRAY_SIZE(voltages); i++) {
		voltages[i] = voltages[i] / (int64_t)sargs->samples;
		voltages[i] = adc_transfer_function(voltages[i], i, sargs);
		voltage_abs = voltages[i] < 0 ? -voltages[i] : voltages[i];
		printf("%s%d."PRECISION_FMT" ",
			voltages[i] < 0 ? "-" : "",
			(int32_t)(voltage_abs / PRECISION_MULT),
			(int32_t)(voltage_abs % PRECISION_MULT));
	}

	printf("\n");
	return 0;
}

static int handle_self_test(ad7616_dev *dev)
{
	static uint8_t channel_a[] = { 0xaa, 0xaa };
	static uint8_t channel_b[] = { 0x55, 0x55 };
	uint8_t buf[4] = {}; /* 2 bytes VA, 2 bytes VB */
	int ret = 0, i;
	uint16_t data, diag_chan = (0xb << 4) | 0xb;

	/* Write diagnostic value for communication test */
	if (ad7616_write_mask(dev, AD7616_REG_CHANNEL, 0xff, diag_chan) < 0) {
		fprintf(stderr, "Unable to set diagnostics value on channel reg\n");
		return -1;
	}

	if (ad7616_read(dev, AD7616_REG_CHANNEL, &data)) {
		fprintf(stderr, "Unable to read channel reg\n");
		return -1;
	}

	if (data != diag_chan) {
		fprintf(stderr, "Invalid channel set; expected '%04x' got '%04x'\n",
			diag_chan, data);
		ret = -1;
	}

	if (dummy_conversion(dev) < 0) {
		fprintf(stderr, "Error while doing dummy conversion\n");
		return -1;
	}

	if (do_conversion(dev, buf, sizeof(buf)) < 0) {
		fprintf(stderr, "Error while doing conversion\n");
		return -1;
	}

	for (i = 0; i < sizeof(buf); i++)
		printf("%02X ", buf[i]);

	printf("\n");

	if (memcmp(&buf[0], channel_a, sizeof(channel_a))) {
		fprintf(stderr, "Channel A values differ from expected 0xAAAA\n");
		ret = -1;
	}

	if (memcmp(&buf[2], channel_b, sizeof(channel_b))) {
		fprintf(stderr, "Channel B values differ from expected 0x5555\n");
		ret = -1;
	}

	if (ret == 0) {
		printf("\n!!All good!!\n");
	}

	return ret;
}

static int handle_mpsse_spi(const char *serial, int channel,
			    const struct spi_read_args *sargs)
{
	ad7616_dev *dev = NULL;
	struct ftdi_context ftdi = {};
	static ad7616_init_param init = {
		.gpio_reset = RESET_PIN,
		.mode = AD7616_SW,
		.osr = AD7616_OSR_128,
		.spi_mode = SPI_MODE_2,
		.frequency = 1000000,	/* 1 Mhz */
		.endianess = 0x00,	/* MSB = 0x00, LSB = 0x08 */
	};
	int ret = EXIT_FAILURE;
	uint16_t vchannel_mask = vchannel_masks[sargs->vchannel_idx].i;

	if (open_device(&ftdi, serial, channel))
		return EXIT_FAILURE;

	memcpy(init.va, va_ranges, sizeof(init.va));
	memcpy(init.vb, vb_ranges, sizeof(init.vb));

	init.ftdi = &ftdi;

	if (ad7616_setup(&dev, &init) < 0) {
		fprintf(stderr, "Could not initialize AD7616 device\n");
		return EXIT_FAILURE;
	}

	if (sargs->self_test) {
		ret = handle_self_test(dev);
		goto out;
	}

	if (gpio_set_direction(&dev->gpio_dev, BUSY_PIN, GPIO_IN) < 0) {
		fprintf(stderr, "Error setting BUSY pin direction\n");
		goto out;
	}

	if (vchannel_mask == ALL_CHANNELS) {
		if (handle_burst_conversion(dev, sargs) == 0)
			ret = EXIT_SUCCESS;
		goto out;
	}

	if (handle_single_conversion(dev, sargs) < 0)
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

static int parse_voltage_arg(const char *arg, int *volt, int *div)
{
	const char *dot = strchr(arg, '.');
	char buf[32];
	int dot_pos, digi_cnt;
	int i, len, sign;

	if (!arg)
		return -1;

	*div = 1;
	dot = strchr(arg, '.');
	if (!dot) {
		*volt = atoi(optarg);
		return 0;
	}

	len = strlen(arg);
	strncpy(buf, arg, sizeof(buf));
	dot_pos = (dot - arg);

	buf[dot_pos] = '\0';
	sign = (buf[0] == '-') ? 1 : 0;

	digi_cnt = (len - 1 - dot_pos);
	for (i = 0; i < digi_cnt; i++)
		*div *= 10;
	*volt = atoi(&buf[sign]) * (*div) + atoi(&buf[dot_pos+1]);
	if (sign)
		*volt = -*volt;

	return 0;
}

static int convert_str_to_volt_range_enum(const char *arg)
{
	char buf[8];

	copy_to_buf_upper(buf, arg, sizeof(buf));

	if (0 == strcmp("2.5V", arg))
		return AD7616_2V5;
	else if (0 == strcmp("5V", arg))
		return AD7616_5V;
	else if (0 == strcmp("10V", arg))
		return AD7616_10V;

	fprintf(stderr, "Invalid volt range; supported values are 2.5V, 5V or 10V\n");
	return -EINVAL;
}

static int parse_ranges_all(const char *arg)
{
	int i, volt_range;
	if (!arg)
		return -1;

	volt_range = convert_str_to_volt_range_enum(arg);
	if (volt_range < 0)
		return -1;

	for (i = 0; i < ARRAY_SIZE(va_ranges); i++) {
		va_ranges[i] = volt_range;
		vb_ranges[i] = volt_range;
	}

	return 0;
}

static int parse_ranges_each(const char *arg)
{
	char *s, *p;
	int i, volt_range;

	if (!arg)
		return -1;

	s = strdup(arg);
	if (!s)
		return -1;
	i = 0;
	p = strtok(s, ",");
	while (p != NULL) {
		volt_range = convert_str_to_volt_range_enum(p);
		if (volt_range < 0)
			return -1;
		if (i > 7)
			vb_ranges[i - 8] = volt_range;
		else
			va_ranges[i] = volt_range;
		p = strtok(NULL, ",");
		i++;
	}
	free(s);

	if (i != 16) {
		fprintf(stderr, "Insuficient volt ranges provided; 16 are required\n");
		return -1;
	}

	return 0;
}

static void usage()
{
	fprintf(stderr, "ft4232h_pin_ctrl --serial <Test-Slot-X> --channel <Y> --mode <spi|bitbang>\n"
			"    [--refinout <V>]  [--vchannel <VNZ>] [--vrange-all <V>]\n"
			"    [--voffset <V>] [--gain <G>] [--vrange-each <V1,..,V16>]>\n"
			"\tWhere: X is A-to-B, the name of the serial device for testing\n"
			"\t       Y is A-to-B, the channel on the FTDI device\n"
			"\t       N is 0-to-7\n"
			"\t       Z is A or B\n\n"
			"\tFor mode Bitbang, specify pins that should be high (pin0 to pin7),\n"
			"\tall other unspecified pins will be set low.\n\n"
			"\tFor SPI, '--vchannel must be specified with values V0A to V7A or V0B to V7B\n"
			"\tto read a single channel. Or '--vchannel all' will read all voltages in one go.\n\n"
			"\t`--refinout` has a defaul value of 2.5V ; can be specified between 2.495 - 2.505 V\n\n"
			"\tVoltage ranges for channels can be updated either all at once via `--vrange-all <V>`\n"
			"\tor for each channel indididually via `--vrange-each <V1,V2,..V16>` where V1 coresponds\n"
			"\tto V0A, V2 to V1A, V8 to V0B and so on\n"
			"\tSupport voltage range values are '2.5V','5V' or '10V'\n"
			"\t\n\t"
			"\tThe tool supports applying an offset and gain to the measured voltage.\n"
			"\tThe formula is 'V = (V + VOFFSET) * GAIN'\n"
		);
}

int main(int argc, char **argv)
{
	int c, option_index = 0;
	const char *serial = NULL;
	int channel = -1;
	int vchannel_idx = 0;
	int mode = BITMODE_BITBANG;
	struct spi_read_args sargs = {
		.vchannel_idx = 0,
		.refinout = 25,
		.refinout_div = 10,
		.samples = 128,
		.voffset_div = 1,
		.gain = 1,
		.gain_div = 1,
		.self_test = 0,
	};

	optind = 0;

	while ((c = getopt_long(argc, argv, "+C:S:V:R:A:E:",
					options, &option_index)) != -1) {
		switch (c) {
			case 'T':
				sargs.self_test = 1;
				mode = BITMODE_MPSSE;
				break;
			case 'A':
				if (parse_ranges_all(optarg) < 0)
					return EXIT_FAILURE;
				break;
			case 'C':
				channel = parse_channel(optarg);
				break;
			case 'E':
				if (parse_ranges_each(optarg) < 0)
					return EXIT_FAILURE;
				break;
			case 'M':
				mode = parse_mode(optarg);
				break;
			case 'N':
				sargs.samples = atoi(optarg);
				break;
			case 'G':
				if (parse_voltage_arg(optarg, &sargs.gain, &sargs.gain_div) < 0) {
					fprintf(stderr, "Could not parse gain\n");
					return EXIT_FAILURE;
				}
				break;
			case 'O':
				if (parse_voltage_arg(optarg, &sargs.voffset, &sargs.voffset_div) < 0) {
					fprintf(stderr, "Could not parse refinout\n");
					return EXIT_FAILURE;
				}
				break;
			case 'R':
				if (parse_voltage_arg(optarg, &sargs.refinout, &sargs.refinout_div) < 0) {
					fprintf(stderr, "Could not parse refinout\n");
					return EXIT_FAILURE;
				}
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
		usage();
		return EXIT_FAILURE;
	}

	if (mode < 0) {
		fprintf(stderr, "Invalid mode set; valid are 'bitbang' or 'spi'\n");
		usage();
		return EXIT_FAILURE;
	}

	if (sargs.samples < 0) {
		fprintf(stderr, "Invalid value for samples provided\n");
		usage();
		return EXIT_FAILURE;
	}

	if (vchannel_idx < 0) {
		fprintf(stderr, "Invalid voltage channel name/selection\n");
		usage();
		return EXIT_FAILURE;
	}

	if (channel < 0) {
		fprintf(stderr, "Invalid or no channel provided\n");
		usage();
		return EXIT_FAILURE;
	}

	if (mode == BITMODE_MPSSE) {
		sargs.vchannel_idx = vchannel_idx;
		return handle_mpsse_spi(serial, channel, &sargs);
	}

	/* bitbang mode here */
	if (set_pin_values(serial, channel, argv, optind, argc) < 0) {
		fprintf(stderr, "Error when trying to set GPIO value\n");
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}
