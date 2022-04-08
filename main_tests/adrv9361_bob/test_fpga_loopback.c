#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>

#define GPIO_DATA_REG(x)	(0x0 + (x) * 8)
#define GPIO_TRI_REG(x)		(0x4 + (x) * 8)

#define GPIO_P2_BADDR      	0x412A0000
#define GPIO_P13_BADDR      0x412B0000
#define GPIO_P4_P5_BADDR    0x412C0000
#define GPIO_P6_P7_BADDR    0x412D0000
#define GPIO_P2_CH1_SIZE	22
#define GPIO_P2_CH2_SIZE	22
#define GPIO_P13_CH1_SIZE	22
#define GPIO_P13_CH2_SIZE	22
#define GPIO_P4_P5_CH1_SIZE	24
#define GPIO_P4_P5_CH2_SIZE	24
#define GPIO_P6_P7_CH1_SIZE	16
#define GPIO_P6_P7_CH2_SIZE	18

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
	uint8_t i, sh_size;

	oe_d = 0;
	sh_size = size;

	//building mask according to size
	while(sh_size > 0){
		oe_d = (oe_d << 1) | 1;
		sh_size--;
	}
	//oe_d = (1 << size) - 1;

	init_oe_d = oe_d;

	//all gpio are '0' but are set as inputs so they are pulled up
	*(volatile uint32_t*)(pGpio + GPIO_TRI_REG(channel)) = oe_d;
	*(volatile uint32_t*)(pGpio + GPIO_DATA_REG(channel)) = 0x00000000;
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
	uint8_t pmod = 0;
	enum test_type{loopback, short_circuit};
	enum test_type type;

	if (argc < 2) {
		printf("Usage: %s <test_dev>\n", argv[0]);
		return -1;
	}

	if (strcmp("P2", argv[1]) == 0) {
		offset = GPIO_P2_BADDR;
		ch1_size = GPIO_P2_CH1_SIZE;
		ch2_size = GPIO_P2_CH2_SIZE;
	}
	else if (strcmp("P13", argv[1]) == 0) {
		offset = GPIO_P13_BADDR;
		ch1_size = GPIO_P13_CH1_SIZE;
		ch2_size = GPIO_P13_CH2_SIZE;
	} else if (strcmp("P4_P5", argv[1]) == 0) {
		offset = GPIO_P4_P5_BADDR;
		ch1_size = GPIO_P4_P5_CH1_SIZE;
		ch2_size = GPIO_P4_P5_CH2_SIZE;
	} else if (strcmp("P6_P7", argv[1]) == 0) {
		offset = GPIO_P6_P7_BADDR;
		ch1_size = GPIO_P6_P7_CH1_SIZE;
		ch2_size = GPIO_P6_P7_CH2_SIZE;
	} else {
		printf("Usage: %s [test_dev P2|P13|P4_P5|P6_P7]\n", argv[0]);
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
	
	ret |= test_loopback(mem, CHANNEL_1, ch1_size);
	ret |= test_loopback(mem, CHANNEL_2, ch2_size);
	
	
	close(fd);
	munmap(mem, page_offset + GPIO_TRI_REG(CHANNEL_2));

	return ret;
}
