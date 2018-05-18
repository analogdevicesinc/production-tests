/***************************************************************************//**
* @file platform_drivers.c
* @brief Implementation of Platform Drivers.
* @author DBogdan (dragos.bogdan@analog.com)
********************************************************************************
* Copyright 2014-2016(c) Analog Devices, Inc.
*
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright
* notice, this list of conditions and the following disclaimer in
* the documentation and/or other materials provided with the
* distribution.
* - Neither the name of Analog Devices, Inc. nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
* - The use of this software may or may not infringe the patent rights
* of one or more patent holders. This license does not release you
* from the requirement that you obtain separate licenses from these
* patent holders to use this software.
* - Use of the software either in source or binary form, must be run
* on or directly connected to an Analog Devices Inc. component.
*
* THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES "AS IS" AND ANY EXPRESS OR
* IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, NON-INFRINGEMENT,
* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL ANALOG DEVICES BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
* LIMITED TO, INTELLECTUAL PROPERTY RIGHTS, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
* CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
* OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
* OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************/

/******************************************************************************/
/***************************** Include Files **********************************/
/******************************************************************************/
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ftdi.h>
#include "platform_drivers.h"

/******************************************************************************/
/************************ Variables/Constants Definitions *********************/
/******************************************************************************/
enum mpsse_commands
{
	INVALID_COMMAND         = 0xAB,
	ENABLE_ADAPTIVE_CLOCK   = 0x96,
	DISABLE_ADAPTIVE_CLOCK  = 0x97,
	ENABLE_3_PHASE_CLOCK    = 0x8C,
	DISABLE_3_PHASE_CLOCK   = 0x8D,
	TCK_X5                  = 0x8A,
	TCK_D5                  = 0x8B,
	CLOCK_N_CYCLES          = 0x8E,
	CLOCK_N8_CYCLES         = 0x8F,
	PULSE_CLOCK_IO_HIGH     = 0x94,
	PULSE_CLOCK_IO_LOW      = 0x95,
	CLOCK_N8_CYCLES_IO_HIGH = 0x9C,
	CLOCK_N8_CYCLES_IO_LOW  = 0x9D,
	TRISTATE_IO             = 0x9E,
};

/* Common clock rates */
enum clock_rates
{
	ONE_HUNDRED_KHZ  = 100000,
	FOUR_HUNDRED_KHZ = 400000,
	ONE_MHZ          = 1000000,
	TWO_MHZ          = 2000000,
	FIVE_MHZ         = 5000000,
	SIX_MHZ          = 6000000,
	TEN_MHZ          = 10000000,
	TWELVE_MHZ       = 12000000,
	FIFTEEN_MHZ      = 15000000,
	THIRTY_MHZ       = 30000000,
	SIXTY_MHZ        = 60000000
};

enum pins
{
	SK      = 1,
	DO      = 2,
	DI      = 4,
	CS      = 8 ,
	GPIO0   = 16,
	GPIO1   = 32,
	GPIO2   = 64,
	GPIO3   = 128
};

#define DEFAULT_TRIS	(SK | DO | CS | GPIO0 | GPIO1 | GPIO2 | GPIO3)  /* SK/DO/CS and GPIOs are outputs, DI is an input */
#define DEFAULT_PORT	(SK | CS)                                       /* SK and CS are high, all others low */
#define SPI_RW_SIZE	(63 * 1024)
#define CMD_SIZE	3
#define SPI_TRANSFER_SIZE	512

static int32_t spi_init_ftdi_mpsse(spi_device *dev)
{
	mpsse *mpsse = &dev->mpsse;
	struct ftdi_context *ctx = mpsse->ftdi;

	if (ftdi_set_bitmode(ctx, 0, BITMODE_RESET) < 0) {
		fprintf(stderr, "Failed to set MPSSE mode\n");
		return -1;
	}

	if (ftdi_set_bitmode(ctx, 0, BITMODE_MPSSE) < 0) {
		fprintf(stderr, "Failed to set MPSSE mode\n");
		return -1;
	}
	mpsse->xsize = SPI_RW_SIZE;

	return 0;
}

static uint16_t freq2div(uint32_t system_clock, uint32_t freq)
{
        return (((system_clock / freq) / 2) - 1);
}

static int32_t spi_set_mpsse_clock(spi_device *dev)
{
	struct ftdi_context *ctx = dev->mpsse.ftdi;
	uint32_t freq = dev->mpsse.frequency;
	uint32_t system_clock = 0;
	uint16_t divisor = 0;
	unsigned char buf[3] = {0};

	if (freq > SIX_MHZ) {
		buf[0] = TCK_X5;
		system_clock = SIXTY_MHZ;
	} else {
		buf[0] = TCK_D5;
		system_clock = TWELVE_MHZ;
	}

	if (ftdi_write_data(ctx, buf, 1) != 1) {
		fprintf(stderr, "Error when writing clock setting (1)\n");
		return -1;
	}

	if (freq <= 0)
		divisor = 0xFFFF;
	else
		divisor = freq2div(system_clock, freq);

	buf[0] = TCK_DIVISOR;
	buf[1] = (divisor & 0xFF);
	buf[2] = ((divisor >> 8) & 0xFF);

	if (ftdi_write_data(ctx, buf, 3) != 3) {
		fprintf(stderr, "Error when writing clock setting (2)\n");
		return -1;
	}

	return 0;
}

/* Set the low bit pins high/low */
static int set_bits_low(mpsse *mpsse, int port)
{
	unsigned char buf[3] = { 0 };
	int ret;

	buf[0] = SET_BITS_LOW;
	buf[1] = port;
	buf[2] = mpsse->tris;

	ret = ftdi_write_data(mpsse->ftdi, buf, sizeof(buf));
	if (ret < 0)
		fprintf(stderr, "%s: error: %s", __func__, ftdi_get_error_string(mpsse->ftdi));
	return ret;
}

static int32_t spi_set_mpsse_spi_mode(spi_device *dev)
{
	unsigned char buf[3] = { 0 };
	mpsse *mpsse = &dev->mpsse;
	struct ftdi_context *ctx = mpsse->ftdi;

	/* Read and write commands need to include endianess */
	mpsse->txrx = MPSSE_DO_WRITE | MPSSE_DO_READ | mpsse->endianess;

	/* Clock, data out, chip select pins are outputs; all others are inputs. */
	mpsse->tris = DEFAULT_TRIS;

	/* Clock and chip select pins idle high; all others are low */
	mpsse->pidle = mpsse->pstart = mpsse->pstop = DEFAULT_PORT;

	/* During reads and writes the chip select pin is brought low */
	mpsse->pstart &= ~CS;

	/* Disable FTDI internal loopback */
	buf[0] = LOOPBACK_END;
	if (ftdi_write_data(ctx, buf, 1) != 1)
		fprintf(stderr, "Could not disable loopback\n");

	/* Ensure adaptive clock is disabled */
	buf[0] = DISABLE_ADAPTIVE_CLOCK;
	if (ftdi_write_data(ctx, buf, 1) != 1)
		fprintf(stderr, "Could not disable adaptive clock\n");

	switch (dev->mode) {
	case SPI_MODE_0:
		/* SPI mode 0 clock idles low */
		mpsse->pidle &= ~SK;
		mpsse->pstart &= ~SK;
		mpsse->pstop &= ~SK;
		/* SPI mode 0 propogates data on the falling edge and read data on the rising edge of the clock */
		mpsse->txrx |= MPSSE_WRITE_NEG;
		mpsse->txrx &= ~MPSSE_READ_NEG;
		break;
	case SPI_MODE_3:
		/* SPI mode 3 clock idles high */
		mpsse->pidle |= SK;
		mpsse->pstart |= SK;
		/* Keep the clock low while the CS pin is brought high to ensure we don't accidentally clock out an extra bit */
		mpsse->pstop &= ~SK;
		/* SPI mode 3 propogates data on the falling edge and read data on the rising edge of the clock */
		mpsse->txrx |= MPSSE_WRITE_NEG;
		mpsse->txrx &= ~MPSSE_READ_NEG;
		break;
	case SPI_MODE_1:
		/* SPI mode 1 clock idles low */
		mpsse->pidle &= ~SK;
		/* Since this mode idles low, the start condition should ensure that the clock is low */
		mpsse->pstart &= ~SK;
		/* Even though we idle low in this mode, we need to keep the clock line high when we set the CS pin high to prevent
		 * an unintended clock cycle from being sent by the FT2232. This way, the clock goes high, but does not go low until
		 * after the CS pin goes high.
		 */
		mpsse->pstop |= SK;
		/* Data read on falling clock edge */
		mpsse->txrx |= MPSSE_READ_NEG;
		mpsse->txrx &= ~MPSSE_WRITE_NEG;
		break;
	case SPI_MODE_2:
		/* SPI 2 clock idles high */
		mpsse->pidle |= SK;
		mpsse->pstart |= SK;
		mpsse->pstop |= SK;
		/* Data read on falling clock edge */
		mpsse->txrx |= MPSSE_READ_NEG;
		mpsse->txrx &= ~MPSSE_WRITE_NEG;
		break;
	default:
		fprintf(stderr, "Invalid spi mode %d\n", dev->mode);
		return -1;
	}

	if (set_bits_low(mpsse, mpsse->pidle) < 0) {
		fprintf(stderr, "Error when initializing port\n");
		return -1;
	}

	return 0;
}

static int spi_start(spi_device *dev)
{
	int ret;
	mpsse *mpsse = &dev->mpsse;

	switch (dev->mode) {
	case SPI_MODE_3:
		/*
		 * Hackish work around to properly support SPI mode 3.
		 * SPI3 clock idles high, but needs to be set low before sending out
		 * data to prevent unintenteded clock glitches from the FT2232.
		 */
		ret = set_bits_low(mpsse, (mpsse->pstart & ~SK));
		break;
	case SPI_MODE_1:
		/*
		 * Hackish work around to properly support SPI mode 1.
		 * SPI1 clock idles low, but needs to be set high before sending out
		 * data to preven unintended clock glitches from the FT2232.
		 */
		ret = set_bits_low(mpsse, (mpsse->pstart | SK));
		break;
	default:
		ret = set_bits_low(mpsse, mpsse->pstart);
		break;
	}
	if (ret >= 0)
		dev->transfer_in_progress = true;
	return ret;
}

static int spi_stop(spi_device *dev)
{
	mpsse *mpsse = &dev->mpsse;
	int ret = -1;
	if (set_bits_low(mpsse, mpsse->pstop) < 0)
		goto out;
	if (set_bits_low(mpsse, mpsse->pidle) < 0)
		goto out;
	ret = 0;
out:
	dev->transfer_in_progress = false;
	return ret;
}

/***************************************************************************//**
* @brief spi_init
*******************************************************************************/
int32_t spi_init(spi_device *dev)
{
	if (spi_init_ftdi_mpsse(dev) < 0)
		return -1;

	if (spi_set_mpsse_clock(dev) < 0)
		return -1;

	if (spi_set_mpsse_spi_mode(dev) < 0)
		return -1;

	//usleep(25000); /* wait some time for setup */
	//ftdi_usb_purge_buffers(dev->mpsse.ftdi);

	return 0;
}

/* Builds a buffer of commands + data blocks */
static uint8_t *build_block_buffer(mpsse *mpsse, uint8_t cmd, unsigned char *data, int size, int *buf_size)
{
	unsigned char *buf = NULL;
	int i = 0, j = 0, k = 0, dsize = 0, num_blocks = 0, total_size = 0, xfer_size = 0;
	uint16_t rsize = 0;

	*buf_size = 0;

	xfer_size = mpsse->xsize;

	num_blocks = (size / xfer_size);
	if(size % xfer_size)
		num_blocks++;

	/* The total size of the data will be the data size + the write command */
	total_size = size + (CMD_SIZE * num_blocks);

	buf = calloc(1, total_size);
	if (!buf)
		return NULL;

	for(j = 0; j < num_blocks; j++) {
		dsize = size - k;
		if (dsize > xfer_size)
			dsize = xfer_size;

		/* The reported size of this block is block size - 1 */
		rsize = dsize - 1;

		/* Copy in the command for this block */
		buf[i++] = cmd;
		buf[i++] = (rsize & 0xFF);
		buf[i++] = ((rsize >> 8) & 0xFF);

		/* On a write, copy the data to transmit after the command */
		memcpy(buf + i, data + k, dsize);

		/* i == offset into buf */
		i += dsize;
		/* k == offset into data */
		k += dsize;

		*buf_size = i;
	}

	return buf;
}

static uint8_t *spi_transfer(mpsse *mpsse, uint8_t *data, int len)
{
	uint8_t *retbuf, *txdata;
	int n = 0, data_size = 0, rxsize, ret;

	retbuf = calloc(1, len);
	if (!retbuf)
		return NULL;

	while (n < len) {
		/* When sending and recieving, FTDI chips don't seem to like large data blocks. Limit the size of each block to SPI_TRANSFER_SIZE */
		rxsize = len - n;
		if (rxsize > SPI_TRANSFER_SIZE)
			rxsize = SPI_TRANSFER_SIZE;

		txdata = build_block_buffer(mpsse, mpsse->txrx, (unsigned char *) (data + n), rxsize, &data_size);
		if (!txdata)
			return NULL;

		if (ftdi_write_data(mpsse->ftdi, txdata, data_size) != data_size) {
			free(txdata);
			return NULL;
		}
		free(txdata);

		ret = ftdi_read_data(mpsse->ftdi, retbuf + n, rxsize);
		if (ret < 0)
			return NULL;

		n += ret;
	}

	return retbuf;
}

/***************************************************************************//**
* @brief spi_read
*******************************************************************************/
int32_t spi_read(spi_device *dev, uint8_t *data, int len)
{
	mpsse *mpsse = &dev->mpsse;
	uint8_t *buf;
	int ret = -1;

	if (spi_start(dev) < 0)
		return -1;

	buf = spi_transfer(mpsse, data, len);
	if (!buf)
		goto out;

	memcpy(data, buf, len);
	free(buf);

	ret = 0;
out:
	if (spi_stop(dev) < 0)
		return -1;

	return ret;
}

/***************************************************************************//**
* @brief spi_write
*******************************************************************************/
int32_t spi_write(spi_device *dev, uint8_t *data, int len)
{
	mpsse *mpsse = &dev->mpsse;
	uint8_t *buf;
	int ret = -1;

	if (spi_start(dev) < 0)
		return -1;

	buf = spi_transfer(mpsse, data, len);
	if (!buf)
		goto out;
	free(buf);

	ret = 0;
out:
	if (spi_stop(dev) < 0)
		return -1;

	return ret;
}

/***************************************************************************//**
 * @brief gpio_init
*******************************************************************************/
int32_t gpio_init(gpio_device *dev)
{
	return 0;
}

/***************************************************************************//**
 * @brief gpio_direction
*******************************************************************************/
int32_t gpio_set_direction(gpio_device *dev, uint8_t pin, uint8_t direction)
{
	mpsse *mpsse = &dev->spi_dev->mpsse;
	uint8_t bit = (1 << pin);

	if (pin > GPIOL3)
		return -EINVAL;

	if (dev->spi_dev->transfer_in_progress)
		return -EBUSY;

	if (direction)
		mpsse->tris |= bit;
	else
		mpsse->tris &= ~bit;

	return set_bits_low(mpsse, mpsse->pidle);
}

/***************************************************************************//**
 * @brief gpio_set_value
*******************************************************************************/
int32_t gpio_set_value(gpio_device *dev, uint8_t pin, uint8_t data)
{
	mpsse *mpsse = &dev->spi_dev->mpsse;
	uint8_t bit = (1 << pin);

	if (pin > GPIOL3)
		return -EINVAL;

	if (dev->spi_dev->transfer_in_progress)
		return -EBUSY;

	if (data) {
		mpsse->pstart |= bit;
		mpsse->pidle |= bit;
		mpsse->pstop |= bit;
	} else {
		mpsse->pstart &= ~bit;
		mpsse->pidle &= ~bit;
		mpsse->pstop &= ~bit;
	}

	return set_bits_low(mpsse, mpsse->pidle);
}

/***************************************************************************//**
 * @brief gpio_get_value
*******************************************************************************/
int32_t gpio_get_value(gpio_device *dev, uint8_t pin, uint8_t *data)
{
	mpsse *mpsse = &dev->spi_dev->mpsse;
	uint8_t bit = (1 << pin);
	uint8_t val = 0;

	if (pin > GPIOL3)
		return -EINVAL;

	if (!data)
		return -EINVAL;

	if (ftdi_read_pins(mpsse->ftdi, &val) < 0)
		return -1;

	*data = !!(val & bit);

	return 0;
}

/***************************************************************************//**
* @brief mdelay
*******************************************************************************/
void mdelay(uint32_t msecs)
{
	usleep(msecs * 1000);
}
