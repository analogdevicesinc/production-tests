#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include <stdbool.h>
#include "phys_addr.h"

#define CLK0_REG_ADDR	0x40
#define CLK1_REG_ADDR	0x44
#define CLK2_REG_ADDR	0x48
#define CLK3_REG_ADDR	0x4C

#define AXI_CLK_SPEED_MHZ	100

int register_read(unsigned char *ptr, char reg_offset) {
	return 0;
}

int register_write(unsigned char mmap_ptr, char reg_offset, char mask) {
	return 0;
}

int main(int argc, char *argv[]) {
	off_t offset, reg_addr;
	int ret, i;
	uint32_t value;
	bool verbose = false;

	if (argc < 2) {
		printf("Usage: %s <test_clk> [verbose]\n", argv[0]);
		return -1;
	}

	offset = AXI_CLK_MONITOR_BADDR;

	if (strcmp("CLK0", argv[1]) == 0)
		reg_addr = CLK0_REG_ADDR;
	else if (strcmp("CLK1", argv[1]) == 0)
		reg_addr = CLK1_REG_ADDR;
	else if (strcmp("CLK2", argv[1]) == 0)
		reg_addr = CLK2_REG_ADDR;
	else if (strcmp("CLK3", argv[1]) == 0)
		reg_addr = CLK3_REG_ADDR;
	else {
		printf("Usage: %s [test_clk CLK0|CLK1|CLK2|CLK3]\n", argv[0]);
		return -1;
	}
	
	if ((argc == 3) && (strcmp("verbose", argv[2]) == 0))
		verbose = true;
	
	// Truncate offset to a multiple of the page size, or mmap will fail.
	size_t pagesize = sysconf(_SC_PAGE_SIZE);
	off_t page_base = (offset / pagesize) * pagesize;
	off_t page_offset = offset - page_base;

	int fd = open("/dev/mem", O_RDWR|O_SYNC);
	void* mem = mmap(NULL, page_offset + reg_addr, PROT_READ | PROT_WRITE,
			    MAP_SHARED, fd, page_base);

	if (mem == MAP_FAILED) {
		perror("Can't map memory");
		return -1;
	}

	value = *(volatile uint32_t*)(mem + reg_addr);

	ret = ((value * AXI_CLK_SPEED_MHZ + 0x7FFF) >> 16);

	if (verbose)
		printf("%d\n", ret);

	close(fd);
	munmap(mem, page_offset + reg_addr);

	return 0;
}

