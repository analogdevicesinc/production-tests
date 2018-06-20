#include <getopt.h>

#include "ft4232h_pin_ctrl.h"
#include "platform_drivers.h"

enum {
	OPT_EEPROM_ADDR,
	OPT_EEPROM_READ,
	OPT_EEPROM_WRITE,
	OPT_EEPROM_RDSR,
	OPT_EEPROM_WRSR,
	OPT_EEPROM_CS,
};

static char *suboptions[] = {
	[OPT_EEPROM_ADDR]  = "addr",
	[OPT_EEPROM_READ]  = "read",
	[OPT_EEPROM_WRITE] = "write",
	[OPT_EEPROM_RDSR]  = "rdsr",
	[OPT_EEPROM_WRSR]  = "wrsr",
	[OPT_EEPROM_CS]    = "cs",

	NULL,
};

struct spi_eeprom_args {
	int op;
	unsigned int addr;
	uint8_t data[16];	/* up to 16 bytes can be written at once */
	int data_len;		/* how much data to R/W */
	struct {
		int channel;
		int pin;
		struct ftdi_context ctx;
	} cs;
};

enum eeprom_opcodes {
	EEPROM_READ  = 0x03,
	EEPROM_WRITE = 0x02,
	EEPROM_WRDI  = 0x04,
	EEPROM_WREN  = 0x06,
	EEPROM_RDSR  = 0x05,
	EEPROM_WRSR  = 0x01,
	EEPROM_INVALID = 0xFF,
};

static int eeprom_cs(struct spi_eeprom_args *eargs, int hi)
{
	uint8_t buf[3] = { SET_BITS_LOW, 0, 0 }; /* active low */

	if (eargs->cs.channel < 0)
		return 0;

	if (hi)
		buf[1] = buf[2] = (1 << eargs->cs.pin);

	if (ftdi_write_data(&eargs->cs.ctx, buf, sizeof(buf)) < 0)
		return -1;

	return 0;
}

/* CS needs to be enabled when calling this */
static int eeprom_read_rdsr(spi_device *dev, struct spi_eeprom_args *eargs)
{
	uint8_t sr[1] = { EEPROM_RDSR };

	if (spi_write(dev, sr, sizeof(sr)) < 0)
		return -1;

	if (spi_read(dev, sr, sizeof(sr)) < 0)
		return -1;

	return sr[0];
}

static int eeprom_wren(spi_device *dev, struct spi_eeprom_args *eargs, int en)
{
	uint8_t wren[1] = {};
	int ret = -1;

	if (eeprom_cs(eargs, 0) < 0)
		return -1;

	wren[0] = en ? EEPROM_WREN : EEPROM_WRDI;
	if (spi_write(dev, wren, sizeof(wren)) < 0)
		goto out;

	ret = 0;
out:
	if (eeprom_cs(eargs, 1) < 0)
		return -1;

	return ret;
}

static int eeprom_write_wrsr(spi_device *dev, struct spi_eeprom_args *eargs)
{
	uint8_t sr[2] = { EEPROM_WRSR, 0 };
	int ret = -1;

	if (eeprom_wren(dev, eargs, 1) < 0)
		return -1;

	if (eeprom_cs(eargs, 0) < 0)
		return -1;

	sr[1] = eargs->data[0];
	if (spi_write(dev, sr, sizeof(sr)) < 0)
		goto out;

	ret = 0;
out:
	if (eeprom_cs(eargs, 1) < 0)
		return -1;

	if (eeprom_wren(dev, eargs, 0) < 0)
		ret = -1;

	return ret;
}

static int eeprom_read_data(spi_device *dev, struct spi_eeprom_args *eargs)
{
	uint8_t cmd[2] = { EEPROM_READ, 0 };
	uint8_t read_buf[512] = {};
	int ret = -1;

	if (eeprom_cs(eargs, 0) < 0)
		return -1;

	cmd[0] |= (0x100 & eargs->addr) >> 5;
	cmd[1] = eargs->addr;
	if (spi_write(dev, cmd, sizeof(cmd)) < 0)
		goto out;

	if (spi_read(dev, read_buf, eargs->data_len) < 0)
		goto out;

	printf("%s\n", read_buf);

	ret = 0;
out:
	if (eeprom_cs(eargs, 1) < 0)
		return -1;

	return ret;
}

static int eeprom_write_data(spi_device *dev, struct spi_eeprom_args *eargs)
{
	uint8_t cmd[2 + 512] = { EEPROM_WRITE, 0 };
	int ret = -1;

	if (eeprom_wren(dev, eargs, 1) < 0)
		return -1;

	if (eeprom_cs(eargs, 0) < 0)
		goto out;

	cmd[0] |= (0x100 & eargs->addr) >> 5;
	cmd[1] = eargs->addr;
	memcpy(&cmd[2], eargs->data, eargs->data_len);
	if (spi_write(dev, cmd, eargs->data_len + 2) < 0)
		goto out;

	ret = 0;
out:
	if (eeprom_cs(eargs, 1) < 0)
		ret = -1;

	if (eeprom_wren(dev, eargs, 0) < 0)
		return -1;

	return ret;
}

static int eeprom_read_rdsr_print(spi_device *dev, struct spi_eeprom_args *eargs)
{
	int sr;
	int ret = EXIT_FAILURE;

        if (eeprom_cs(eargs, 0) < 0)
                return EXIT_FAILURE;

	sr = eeprom_read_rdsr(dev, eargs);
	if (sr < 0) {
		fprintf(stderr, "Failed to read Status Register\n");
		goto out;
	}
	printf("0x%02x\n", sr);

	ret = EXIT_SUCCESS;
out:
	if (eeprom_cs(eargs, 1) < 0)
		return EXIT_FAILURE;
	return ret;
}

static int handle_mpsse_spi_eeprom_with_args(const char *serial, int channel,
					     struct spi_eeprom_args *eargs)
{
	struct ftdi_context ftdi = {};
	spi_device sdev = {};
	mpsse *mpsse;
	int ret = EXIT_FAILURE;

	if (open_device(&ftdi, serial, channel))
		return EXIT_FAILURE;

	if (eargs->cs.channel > -1) {
		if (open_device(&eargs->cs.ctx, serial, eargs->cs.channel))
			return EXIT_FAILURE;

		if (ftdi_set_bitmode(&eargs->cs.ctx, 0xFF, BITMODE_BITBANG) < 0) {
			fprintf(stderr, "Failed to set bitbang mode: %s\n",
				ftdi_get_error_string(&eargs->cs.ctx));
			return EXIT_FAILURE;
		}

		if (eeprom_cs(eargs, 1) < 0) {
			fprintf(stderr, "Failed to set CS to high\n");
			return EXIT_FAILURE;
		}
	}

	sdev.mode = SPI_MODE_0;
	sdev.chip_select = -1; /* don't use chip select */

	mpsse = &(sdev.mpsse);
	mpsse->ftdi = &ftdi;
	mpsse->frequency = 1000000; /* 1 Mhz */

	if (spi_init(&sdev) < 0) {
		fprintf(stderr, "Failed to initialize SPI\n");
		goto out;
	}
	mpsse->pstart |= 8;     /* keep CS high */
	mdelay(10);

	switch (eargs->op) {
	case OPT_EEPROM_RDSR:
		ret = eeprom_read_rdsr_print(&sdev, eargs);
		break;
	case OPT_EEPROM_WRSR:
		ret = eeprom_write_wrsr(&sdev, eargs);
		break;
	case OPT_EEPROM_READ:
		ret = eeprom_read_data(&sdev, eargs);
		break;
	case OPT_EEPROM_WRITE:
		ret = eeprom_write_data(&sdev, eargs);
		break;
	default:
		fprintf(stderr, "Invalid operation '%d'\n", eargs->op);
		ret = EXIT_FAILURE;
		break;
	}

out:
	close_device(&ftdi);
	return ret;
}

static int parse_cs_subopt(const char *value, int *channel, int *pin)
{
	char *copy = strdup(value);
	char *p;

	p = strchr(copy, ':');
	if (!p)
		goto err;

	*p = '\0';
	p++;

	if ((*channel = parse_channel(copy)) < 0)
		goto err;

	*pin = atoi(p);

	return 0;
err:
	fprintf(stderr, "Failed to parse 'cs' suboption; must be \n");
	return -1;

}

void usage_spi_eeprom()
{
	fprintf(stderr, "\n\tFor SPI-EEPROM mode, the sub-options are:\n"
			"\t\taddr=<xxxx> - specify an EEPROM address to read/write\n"
			"\t\twrite=<xxxx> - string to write; must be null-terminated\n"
			"\t\tread=<xxxx> - number of bytes to read; it will displayed up to the null-char\n"
			"\t\tcs=<chan>:<pin> - specify FTDI channel and pin number which to be used\n"
			"\t\t\t\tas chip-select; may be omitted\n");
}

int handle_mpsse_spi_eeprom(const char *serial, int channel, char *subopts)
{
	int subopt_idx = 0;
	struct spi_eeprom_args eargs = {
		.op = -1,
		.cs = {
			.channel = -1,
		},
	};
	char *value;

	if (!subopts) {
		fprintf(stderr, "No sub-options for SPI-EEPROM provided\n");
		return EXIT_FAILURE;
	}

	while (*subopts != '\0') {
		const char *saved = subopts;
		value = NULL;
		subopt_idx = getsubopt(&subopts, suboptions, &value);
		switch (subopt_idx) {
			case OPT_EEPROM_CS:
				if (!value) {
					fprintf(stderr, "No value provided for 'cs' subopt\n");
					return EXIT_FAILURE;
				}
				if (parse_cs_subopt(value, &eargs.cs.channel, &eargs.cs.pin) < 0) {
					usage_spi_eeprom();
					return EXIT_FAILURE;
				}
				break;
			case OPT_EEPROM_ADDR:
				if (!value) {
					fprintf(stderr, "No value provided for 'addr' subopt\n");
					return EXIT_FAILURE;
				}
				eargs.addr = strtoul(value, NULL, 0);
				break;
			case OPT_EEPROM_WRSR:
				if (!value) {
					fprintf(stderr, "No value provided for 'wrsr' subopt\n");
					return EXIT_FAILURE;
				}
				eargs.op = subopt_idx;
				eargs.data[0] = (uint8_t)strtoul(value, NULL, 0);
				eargs.data_len = 1;
				break;
			case OPT_EEPROM_WRITE:
				if (!value) {
					fprintf(stderr, "No value provided for 'write' subopt\n");
					return EXIT_FAILURE;
				}
				eargs.op = subopt_idx;
				eargs.data_len = min(strlen(value) + 1, sizeof(eargs.data));
				memcpy(eargs.data, value, eargs.data_len);
				break;
			case OPT_EEPROM_RDSR:
				eargs.data_len = 1;
				/* FALLTHROUGH */
			case OPT_EEPROM_READ:
				if (subopt_idx == OPT_EEPROM_READ) {
					if (!value) {
						fprintf(stderr, "No value provided for 'read' subopt\n");
						return EXIT_FAILURE;
					}
					eargs.data_len = min(strtoul(value, NULL, 10), 512);
				}
				eargs.op = subopt_idx;
				break;
			default:
				fprintf(stderr, "Unknown suboption '%s' for SPI-EEPROM mode\n", saved);
				usage_spi_eeprom();
				return EXIT_FAILURE;
		}
	}

	return handle_mpsse_spi_eeprom_with_args(serial, channel, &eargs);
}
