#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include "phys_addr.h"
#include <string.h>

#define RST_REG_ADDR	0x10
#define STATUS_REG_ADDR	0x14
#define PLL_REG_ADDR	0x18

int register_read(unsigned char *ptr, char reg_offset) {
	return 0;
}

int register_write(unsigned char mmap_ptr, char reg_offset, char mask) {
	return 0;
}

int main(int argc, char *argv[]) {
	off_t offset;
	int ret;
	uint32_t value;

	if (argc < 2) {
		printf("Usage: %s <test_dev> [verbose]\n", argv[0]);
		return -1;
	}

	if (strcmp("SFP", argv[1]) == 0)
		offset = XCVRLB_SFP_BADDR;
	else if (strcmp("QSFP", argv[1]) == 0)
		offset = XCVRLB_QSFP_BADDR;
	else if (strcmp("FMC", argv[1]) == 0)
		offset = XCVRLB_FMC_BADDR;
	else if (strcmp("PCIE", argv[1]) == 0)
		offset = XCVRLB_PCIE_BADDR;
	else {
		printf("Usage: %s [test_dev SFP|QSFP|FMC|PCIE]\n", argv[0]);
		return -1;
	}
	
	// Truncate offset to a multiple of the page size, or mmap will fail.
	size_t pagesize = sysconf(_SC_PAGE_SIZE);
	off_t page_base = (offset / pagesize) * pagesize;
	off_t page_offset = offset - page_base;

	int fd = open("/dev/mem", O_RDWR|O_SYNC);
	void* mem = mmap(NULL, page_offset + PLL_REG_ADDR, PROT_READ | PROT_WRITE,
			    MAP_SHARED, fd, page_base);

	if (mem == MAP_FAILED) {
		perror("Can't map memory");
		return -1;
	}

	/* Take peripheral out of reset */
	*(volatile uint32_t*)(mem + RST_REG_ADDR) = (uint32_t)0x1;
	usleep (1000);

	/* Clear status reg */
	*(volatile uint32_t*)(mem + STATUS_REG_ADDR) = *(volatile uint32_t*)(mem + STATUS_REG_ADDR);
	usleep (1000);

	/* Clear PLL reg */
	*(volatile uint32_t*)(mem + PLL_REG_ADDR) = *(volatile uint32_t*)(mem + PLL_REG_ADDR);

	*(volatile uint32_t*)(mem + STATUS_REG_ADDR) = *(volatile uint32_t*)(mem + STATUS_REG_ADDR);
	
	value = *(volatile uint32_t*)(mem + STATUS_REG_ADDR);

	if (value) {
		ret = -10;
	} else {
		ret = 0;
	}

	close(fd);
	munmap(mem, page_offset + PLL_REG_ADDR);

	return ret;
}

