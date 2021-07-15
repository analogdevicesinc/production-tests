
#include "ft4232h_pin_ctrl.h"
#include "platform_drivers.h"

#define MCP_IODIR	0x00            /* init/reset:  all ones */
#define MCP_IPOL	0x01
#define MCP_GPINTEN	0x02
#define MCP_DEFVAL	0x03
#define MCP_INTCON	0x04
#define MCP_IOCON	0x05
#	define IOCON_MIRROR	(1 << 6)
#	define IOCON_SEQOP	(1 << 5)
#	define IOCON_HAEN	(1 << 3)
#	define IOCON_ODR	(1 << 2)
#	define IOCON_INTPOL	(1 << 1)
#	define IOCON_INTCC	(1)
#define MCP_GPPU	0x06
#define MCP_INTF	0x07
#define MCP_INTCAP	0x08
#define MCP_GPIO	0x09
#define MCP_OLAT	0x0a

void usage_spi_gpio_exp()
{
	fprintf(stderr, "\n\tFor SPI-GPIO-EXP mode, arguments are similar to Bitbang mode\n"
			"\t\tbut they control the pins on the GPIO expander\n");
}

int handle_mpsse_spi_gpio_exp(const char *serial, int channel, char **argv,
			      int from, int to)
{
	struct ftdi_context ftdi = {};
	spi_device sdev = {};
	mpsse *mpsse;
	int ret = EXIT_FAILURE;
	int i;
	uint8_t output = 0;
	uint8_t direction = 0;
	uint8_t regs[11 + 2] = {};

	for (i = from; i < to; i++) {
		int pin1, pin = get_pin_val(argv[i]);
		if (pin < 0) {
			fprintf(stderr, "Invalid pin name '%s'\n", argv[i]);
			return EXIT_FAILURE;
		}
		pin1 = 1 << (pin & PIN_NUM_MSK);
		if (pin & PIN_IN_MSK)
			direction |= pin1;
		else
			output |= pin1;
	}

	if (open_device(&ftdi, serial, channel))
		return EXIT_FAILURE;

	sdev.mode = SPI_MODE_0;
	sdev.chip_select = GPIOL3;

	mpsse = &(sdev.mpsse);
	mpsse->ftdi = &ftdi;
	mpsse->frequency = 1000000; /* 1 Mhz */

	if (spi_init(&sdev) < 0) {
		fprintf(stderr, "Failed to initialize SPI\n");
		goto out;
	}

	regs[0] = 0x40;
	regs[2 + MCP_OLAT] = output;
	regs[2 + MCP_IODIR] = direction;

	if (spi_write(&sdev, regs, sizeof(regs)) < 0)
		goto out;

	ret = EXIT_SUCCESS;
out:
	close_device(&ftdi);

	return ret;
}
