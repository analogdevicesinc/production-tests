#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <ctype.h>
#include <string.h>
#include <ftdi.h>

#define GNICE_VID 0x0456
#define GNICE_PID 0xf001

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(x) (sizeof(x) / sizeof(*(x)))
#endif

static const struct option options[] = {
	{"channel", required_argument, 0, 'C'},
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

static int get_int_from_map(const struct map *map, int map_len, const char *arg)
{
	int i;
	char buf[16];

	if (!arg || !map)
		return -1;

	strncpy(buf, arg, sizeof(buf));
	for (i = 0; i < strlen(buf); i++) {
		buf[i] = toupper(buf[i]);
	}

	for (i = 0; i < map_len; i++) {
		if (!strcmp(map[i].s, buf))
			return map[i].i;
	}

	return -1;
}

static int open_device(struct ftdi_context *ctx, int channel)
{
	int ret;

	if (ftdi_init(ctx)) {
		fprintf(stderr, "Failed to init ftdi context\n");
		return -1;
	}

	if (ftdi_set_interface(ctx, channel)) {
		fprintf(stderr, "Failed to set channel %d", channel);
		return -1;
	}

	if (ftdi_usb_open_desc_index(ctx, GNICE_VID, GNICE_PID, NULL, "Test-Slot-A", 0)) {
		fprintf(stderr, "Failed to open device\n");
		return -1;
	}

	if(ftdi_usb_reset(ctx))
		fprintf(stderr,"%s\n",ftdi_get_error_string(ctx));

	if(ftdi_usb_purge_buffers(ctx)) //clean buffers
		fprintf(stderr,"%s\n",ftdi_get_error_string(ctx));

	if(ftdi_write_data_set_chunksize(ctx,65536)) //64k transfer size
		fprintf(stderr,"%s\n",ftdi_get_error_string(ctx));

	if(ftdi_read_data_set_chunksize(ctx,4096)) //64k transfer size
		fprintf(stderr,"%s\n",ftdi_get_error_string(ctx));

	if(ftdi_set_event_char(ctx,0,0)) //disable event chars
		fprintf(stderr,"%s\n",ftdi_get_error_string(ctx));

	if(ftdi_set_error_char(ctx,0,0)) //disable error chars
		fprintf(stderr,"%s\n",ftdi_get_error_string(ctx));

	if(ftdi_set_latency_timer(ctx,2)) //Set the latency timer to 1mS (default is 16mS)
		fprintf(stderr,"%s\n",ftdi_get_error_string(ctx));

	if(ftdi_set_baudrate(ctx,921600)) 
		fprintf(stderr,"%s\n",ftdi_get_error_string(ctx));

	if(ftdi_setflowctrl(ctx,SIO_RTS_CTS_HS)) //set flow control
		fprintf(stderr,"%s\n",ftdi_get_error_string(ctx));

	if ((ret = ftdi_set_bitmode( ctx, 0x00, BITMODE_RESET )) < 0 )
	{
		fprintf(stderr, "can't set bitmode to %x: %d (%s)\n", BITMODE_RESET, ret, ftdi_get_error_string(ctx));
		fprintf( stderr, "RESET\n" );
		return EXIT_FAILURE;
	}

	if (ftdi_set_bitmode(ctx, 0xF0, BITMODE_BITBANG)) {
		fprintf(stderr, "Failed to set bitbang mode\n");
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


static int set_pin_values(int channel, char **argv, int from, int to)
{
	struct ftdi_context ftdi = {};
	char buf[2];
	int i;

	if (open_device(&ftdi, channel)) {
		fprintf(stderr, "Coud not open device\n");
		return -1;
	}

	buf[0] = SET_BITS_LOW;
	for (i = from; i < to; i++) {
		int pin = get_int_from_map(pins, ARRAY_SIZE(pins), argv[i]);
		buf[1] |= 1 << pin;
	}

	if (ftdi_write_data(&ftdi, buf, sizeof(buf)) != sizeof(buf)) {
		fprintf(stderr, "Could not set pins\n");
		return -1;
	}

	close_device(&ftdi);

	return 0;
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

int main(int argc, char **argv)
{
	struct mpsse_context *io = NULL;
	int c, option_index = 0;
	int channel = -1;
	int gval;

	optind = 0;

	while ((c = getopt_long(argc, argv, "+C:G:",
					options, &option_index)) != -1) {
		switch (c) {
			case 'C':
				channel = parse_channel(optarg);
				break;
		}
	}

	if (channel < 0) {
		fprintf(stderr, "Invalid or no channel provided\n");
		return EXIT_FAILURE;
	}

	if (set_pin_values(channel, argv, optind, argc) < 0) {
		fprintf(stderr, "Error when trying to set GPIO value\n");
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}
