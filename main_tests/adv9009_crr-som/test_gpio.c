#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include "phys_addr.h"

#define GPIO_DATA_REG(x)	(0x0 + (x) * 8)
#define GPIO_TRI_REG(x)		(0x4 + (x) * 8)

#define GPIO_0_FMC_CH1_SIZE	32
#define GPIO_0_FMC_CH2_SIZE	32
#define GPIO_1_FMC_CH1_SIZE	4
#define GPIO_1_FMC_CH2_SIZE	0

#define CHANNEL_1	0
#define CHANNEL_2	1

/**
 * Test for electrical shorts. The function is walking a '0' on each
 * of the lines while leaving the others in pull-up state. If more than
 * one '0' is found when reading back, that indicates a short.
 * @param pGpio - pointer to gpio instance
 * @param channel - gpio channel
 * @param size - width of channel
 * @return 0 if no short was found. Else -255 reported
 */
int test_short(void* pGpio, uint8_t channel, uint8_t size) {
	uint32_t oe_d, or_d, read_d, init_oe_d;
	uint8_t i;

	oe_d = (1 << size) - 1;
	or_d = 0;

	init_oe_d = oe_d;
	//all gpio are '0' but are set as inputs so they are pulled up
	*(volatile uint32_t*)(pGpio + GPIO_TRI_REG(channel)) = oe_d;
	
	for(i = 0; i < size; i++) {
	/* to drive signal to '0' it is set as output. to return to
	 *  pull up state it is set as an input
	 *  oe_d must be shifted left after each iteration
	*/
		oe_d = ((oe_d << 1) | or_d) & init_oe_d;
		or_d = ((or_d << 1) | 1);
		*(volatile uint32_t*)(pGpio + GPIO_TRI_REG(channel)) = oe_d;
		//long wait for pull-up to have time to settle
		usleep(100000);
		//reading back gpio lines
		read_d = *(volatile uint32_t*)(pGpio + GPIO_DATA_REG(channel));

		//check if read data matches expected data
		if((read_d != oe_d)) {
			printf("short test fails\r\n");
			return -255;
		}
		read_d = *(volatile uint32_t*)(pGpio + GPIO_DATA_REG(channel));
	}
	return 0;
}

/**
 * Test for electrical continuity. Signals are now connected in pairs by the
 * FMC loopback The function is walking a '0' on one signal and expexts to
 * find '0' only on it's pair.
 * @param pGpio - pointer to gpio instance
 * @param channel - gpio channel
 * @param size - width of channel
 * @return -255 if loopback test fails, 0 otherwise.
 */
int test_loopback(void* pGpio, uint8_t channel, uint8_t size) {
	uint32_t init_oe_d, oe_d, read_d, oe_d_aux, exp_d;
	uint8_t i;

	oe_d = 0;

	//building mask according to size
	oe_d = (1 << size) - 1;

	init_oe_d = oe_d;

	//all gpio are '0' but are set as inputs so they are pulled up
	*(volatile uint32_t*)(pGpio + GPIO_TRI_REG(channel)) = oe_d;
	//initial mask is applied to make sure no extra bits are used
	oe_d = 0xFFFFFFFE & init_oe_d;

	for(i = 0; i < size/2; i++)  {
		/* to drive signal to '0' it is set as output. to return to
		*  pull up state it is set as an input
		*  oe_d must be shifted left after each iteration
		*/
		*(volatile uint32_t*)(pGpio + GPIO_TRI_REG(channel)) = oe_d;
		//long wait for pull-up to have time to settle
		usleep(100000);
		read_d = *(volatile uint32_t*)(pGpio + GPIO_DATA_REG(channel));
		//building expected data
		exp_d = oe_d & ((oe_d << 1) | 0x1);

		//check if read data matches expected data
		if(read_d != exp_d)  {
			printf("loopback test fails!\r\n");
			return -255;
		}
		//getting next set of output data ready.
		oe_d_aux = oe_d << 2;
		oe_d = (oe_d_aux | 0x3) & init_oe_d;
	}
	return 0;
}

int main(int argc, char *argv[]) {
	off_t offset;
	uint32_t size, value, ret = 0;
	uint8_t ch1_size,ch2_size;
	enum test_type{loopback, short_circuit};
	enum test_type type;

	if (argc < 3) {
		printf("Usage: %s <test_dev> <mode>\n", argv[0]);
		return -1;
	}

	if (strcmp("FMC_GPIO0", argv[1]) == 0) {
		offset = FMC_GPIO_0_BADDR;
		ch1_size = GPIO_0_FMC_CH1_SIZE;
		ch2_size = GPIO_0_FMC_CH2_SIZE;
	}
	else if (strcmp("FMC_GPIO1", argv[1]) == 0) {
		offset = FMC_GPIO_1_BADDR;
		ch1_size = GPIO_1_FMC_CH1_SIZE;
		ch2_size = GPIO_1_FMC_CH2_SIZE;
	} else if (strcmp("PMOD", argv[1]) == 0) {
		printf("Currently not implemented\n");
		return -1;
	} else {
		printf("Usage: %s [test_dev FMC_GPIO0|FMC_GPIO1|PMOD]\n", argv[0]);
		return -1;
	}
	
	if (strcmp("loopback", argv[2]) == 0)
		type = loopback;
	else if (strcmp("short_circuit", argv[2]) == 0)
		type = short_circuit;
	else {
		printf("Usage: %s [mode loopback|short_circuit]\n", argv[0]);
		return -1;
	}
	
	// Truncate offset to a multiple of the page size, or mmap will fail.
	size_t pagesize = sysconf(_SC_PAGE_SIZE);
	off_t page_base = (offset / pagesize) * pagesize;
	off_t page_offset = offset - page_base;

	int fd = open("/dev/mem", O_RDWR|O_SYNC);
	void* mem = mmap(NULL, page_offset + GPIO_TRI_REG(CHANNEL_2), PROT_READ | PROT_WRITE,
			    MAP_SHARED, fd, page_base);

	if (mem == MAP_FAILED) {
		perror("Can't map memory");
		return -1;
	}
	
	if (type == loopback) {
		ret |= test_loopback(mem, CHANNEL_1, ch1_size);
		ret |= test_loopback(mem, CHANNEL_2, ch2_size);
	} else {
		ret |= test_short(mem, CHANNEL_1, ch1_size);
		ret |= test_short(mem, CHANNEL_2, ch2_size);
	}
	
	close(fd);
	munmap(mem, page_offset + GPIO_TRI_REG(CHANNEL_2));

	return ret;
}
