#include <errno.h>
#include <getopt.h>
#include <arpa/inet.h> /* for ntohs() */

#include "ft4232h_pin_ctrl.h"
#include "ad7616.h"

#define ALL_CHANNELS	0xffff

#define PRECISION_MULT		10000	/* 0.1 mV or 100 uV */
#define PRECISION_FMT		"%04d"	/* correlate this with PRECISION_MULT */

#define BURST_EN	(AD7616_BURSTEN | AD7616_SEQEN)

enum {
	CONVST_PIN = GPIOL0,
	RESET_PIN  = GPIOL1,
	BUSY_PIN   = GPIOL3,
};

enum {
	OPT_ADC_VCHANNEL,
	OPT_ADC_REFINOUT,
	OPT_ADC_VRANGE_EACH,
	OPT_ADC_VRANGE_ALL,
	OPT_ADC_NO_SAMPLES,
	OPT_ADC_VOFFSET,
	OPT_ADC_GAIN,
	OPT_ADC_SELFTEST,
};

static char *suboptions[] = {
	[OPT_ADC_VCHANNEL]    = "vchannel",
	[OPT_ADC_REFINOUT]    = "refinout",
	[OPT_ADC_VRANGE_EACH] = "vrange-each",
	[OPT_ADC_VRANGE_ALL]  = "vrange-all",
	[OPT_ADC_NO_SAMPLES]  = "no-samples",
	[OPT_ADC_VOFFSET]     = "voffset",
	[OPT_ADC_GAIN]        = "gain",
	[OPT_ADC_SELFTEST]    = "self-test",

	NULL,
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

static int handle_mpsse_spi_with_args(const char *serial, int channel,
				      struct spi_read_args *sargs)
{
	ad7616_dev *dev = NULL;
	struct ftdi_context ftdi = {};
	static ad7616_init_param init = {
		.gpio_reset = RESET_PIN,
		.spi_chip_select = CS_PIN,
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
		*volt = atoi(arg);
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
	p = strtok(s, ":");
	while (p != NULL) {
		volt_range = convert_str_to_volt_range_enum(p);
		if (volt_range < 0)
			return -1;
		if (i > 7)
			vb_ranges[i - 8] = volt_range;
		else
			va_ranges[i] = volt_range;
		p = strtok(NULL, ":");
		i++;
	}
	free(s);

	if (i < 16) {
		fprintf(stderr, "Insuficient volt ranges provided; 16 are required\n");
		return -1;
	}

	return 0;
}

void usage_spi_adc()
{
	fprintf(stderr, "\n\tFor SPI-ADC, subptions are:\n"
			"\t\tvchannel=<chan> -  must be specified with values V0A to V7A or V0B to V7B\n"
			"\t\t\tto read a single channel. Or 'all' will read all voltages in one go.\n"
			"\t\trefinout=<xxx> - has a defaul value of 2.5V ; can be specified between 2.495 - 2.505 V\n"
			"\t\tvrange-all=<xxx> - to configure a single voltage range for all channels\n"
			"\t\t\tValues are '2.5V', '5V' or '10V'"
			"\t\tvrange-each=<x:x:..:x> - to configure 16 voltage ranges, one for each channel;\n"
			"\t\t\tmust be separated by colon (':')\n"
			"\t\tno-samples - do multiple measurements and do an average\n"
			"\t\tvoffset - voltage offset to apply\n "
			"\t\tgain - voltage gain to apply\n"
			"\t\tself-test - run a self-test of the ADC\n\n"
			"\tThe tool supports applying an offset and gain to the measured voltage.\n"
			"\tThe formula is 'V = (V + VOFFSET) * GAIN'\n"
		);
}

int handle_mpsse_spi_adc(const char *serial, int channel, char *subopts)
{
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
	char *value;

	if (!subopts) {
		fprintf(stderr, "No sub-options for SPI-EEPROM provided\n");
		return EXIT_FAILURE;
	}

	while (*subopts != '\0') {
		const char *saved = subopts;
		switch (getsubopt(&subopts, suboptions, &value)) {
			case OPT_ADC_SELFTEST:
				sargs.self_test = 1;
				break;
			case OPT_ADC_VRANGE_ALL:
				if (parse_ranges_all(value) < 0) {
					usage_spi_adc();
					return EXIT_FAILURE;
				}
				break;
			case OPT_ADC_VRANGE_EACH:
				if (parse_ranges_each(value) < 0) {
					usage_spi_adc();
					return EXIT_FAILURE;
				}
				break;
			case OPT_ADC_NO_SAMPLES:
				sargs.samples = atoi(value);
				break;
			case OPT_ADC_GAIN:
				if (parse_voltage_arg(value, &sargs.gain, &sargs.gain_div) < 0) {
					fprintf(stderr, "Could not parse gain\n");
					usage_spi_adc();
					return EXIT_FAILURE;
				}
				break;
			case OPT_ADC_VOFFSET:
				if (parse_voltage_arg(value, &sargs.voffset, &sargs.voffset_div) < 0) {
					fprintf(stderr, "Could not parse refinout\n");
					usage_spi_adc();
					return EXIT_FAILURE;
				}
				break;
			case OPT_ADC_REFINOUT:
				if (parse_voltage_arg(value, &sargs.refinout, &sargs.refinout_div) < 0) {
					fprintf(stderr, "Could not parse refinout\n");
					usage_spi_adc();
					return EXIT_FAILURE;
				}
				break;
			case OPT_ADC_VCHANNEL:
				sargs.vchannel_idx = parse_vchannel_idx(value);
				break;
			default:
				fprintf(stderr, "Unknown suboption `%s' for SPI-ADC mode\n", saved);
				usage_spi_adc();
				return EXIT_FAILURE;
		}
	}

	if (sargs.samples <= 0) {
		fprintf(stderr, "Invalid value for samples provided\n");
		usage_spi_adc();
		return EXIT_FAILURE;
	}

	if (sargs.vchannel_idx < 0) {
		fprintf(stderr, "Invalid voltage channel name/selection\n");
		usage_spi_adc();
		return EXIT_FAILURE;
	}

	return handle_mpsse_spi_with_args(serial, channel, &sargs);
}
