#ifndef __FT4232H_PIN_CTRL_H__
#define __FT4232H_PIN_CTRL_H__

#include <stdio.h>
#include <stdlib.h>
#include <ftdi.h>
#include <string.h>

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(x) (sizeof(x) / sizeof(*(x)))
#endif

struct map {
	const char *s;
	unsigned int i;
};

void copy_to_buf_upper(char *buf, const char *s, int len);
int get_int_from_map(const struct map *map, int map_len, const char *arg);
int get_idx_from_map(const struct map *map, int map_len, const char *arg);
int parse_channel(const char *arg);

int open_device(struct ftdi_context *ctx, const char *serial, int channel);
void close_device(struct ftdi_context *ctx);

int set_pin_values(const char *serial, int channel, char **argv,
		   int from, int to);
int handle_mpsse_spi_adc(const char *serial, int channel, char *subopts);
int handle_mpsse_spi_eeprom(const char *serial, int channel, char *subopts);

void usage_bitbang();
void usage_spi_adc();
void usage_spi_eeprom();

#endif /* __FT4232H_PIN_CTRL_H__ */
