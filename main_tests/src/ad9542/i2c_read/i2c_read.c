
#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>

const int16_t ad9542_regs_sysclk[9][2] = {
	{0x0200,0x18},
	{0x0201,0x09},
	{0x0202,0x00},
	{0x0203,0x00},
	{0x0204,0xB0},
	{0x0205,0x71},
	{0x0206,0x0B},
	{0x0207,0x32},
	{0x2001,0x0F}, // power-down reference inputs
}; 

const int16_t ad9542_regs_apll[14][2] = {
	{0x1000,0x98}, // DPLL0 free running tuning word
	{0x1001,0xD0}, // DPLL0 free running tuning word
	{0x1002,0x5E}, // DPLL0 free running tuning word
	{0x1003,0x42}, // DPLL0 free running tuning word
	{0x1004,0x2B}, // DPLL0 free running tuning word
	{0x1005,0x24}, // DPLL0 free running tuning word
	{0x1081,0x09}, // APLL0 M divider
	{0x1400,0x2F}, // DPLL1 free running tuning word
	{0x1401,0xBA}, // DPLL1 free running tuning word
	{0x1402,0xE8}, // DPLL1 free running tuning word
	{0x1403,0xA2}, // DPLL1 free running tuning word
	{0x1404,0x9F}, // DPLL1 free running tuning word
	{0x1405,0x22}, // DPLL1 free running tuning word
	{0x1481,0x0B}, // APLL1 M divider
}; 

const int16_t ad9542_regs_output[13][2] = {
	{0x10D7,0x00},	// Driver Config Ch0A CML, 7.5mA, diff
	{0x10D8,0x00},	// Driver COnfig Ch0B
	{0x10D9,0x00},	// Driver Config Ch0C
	{0x10DB,0x01},	// Autosync mode after APLL locked
	{0x1100,0x05},	// Ch0A Divider
	{0x1112,0x05},	// Ch0B Divider
	{0x1124,0x0C},	// Ch0C Divider
	{0x14D7,0x00},	// Driver Config Ch1A CML, 7.5mA, diff
	{0x14D8,0x00},	// Driver Config Ch1B
	{0x14DB,0x01},	// Autosync mode after APLL locked
	{0x1500,0x43},	// Ch1A Divider
	{0x1508,0x27},	// Ch1A Half Divide enable
	{0x1512,0x41},	// Ch1B Divider	
}; 

const int16_t ad9542_regs_status[5][2] = {
	{0x3001,0x03},	// SYSCLK stable, locked
	{0x3100,0x28},	// APLL0 calibration done, APLL0 locked
	{0x3101,0x01},	// DPLL0 freerun
	{0x3200,0x28},	// APLL1 calibration done, APLL1 locked
	{0x3201,0x01},	// DPLL1 freerun
}; 

  const int16_t ad9542_regs_EEPROM_Inst1[15][2] = {
	{0x2E10,0x04},	// driver config Ch0; 5 regs from 0x10D7
	{0x2E11,0xD7},	
	{0x2E12,0x10},	
	{0x2E13,0x34},	// driver config Ch0, 53 regs from 0x1100
	{0x2E14,0x00},	
	{0x2E15,0x11},	
	{0x2E16,0x03},  // driver config Ch1; 4 regs from 0x14D7
	{0x2E17,0xD7},	
	{0x2E18,0x14},	
	{0x2E19,0x23},	// driver config Ch1; 36 regs from 0x1500
	{0x2E1A,0x00},	
	{0x2E1B,0x15},	
	{0x2E1C,0x80},	// update
	{0x2E1D,0xFE},	// pause
	{0x2E1E,0xFF},	
  };
  const int16_t ad9542_regs_EEPROM_Inst2[15][2] = {	  
	{0x2E10,0x07},	// sysclk config; 8 regs from 0x0200
	{0x2E11,0x00},	
	{0x2E12,0x02},	
	{0x2E13,0x00},	// pwdn ref; 1 reg from 0x2001
	{0x2E14,0x01},	
	{0x2E15,0x20},	
	{0x2E16,0x05},	// appl0 config; 6 regs from 0x1000
	{0x2E17,0x00},	
	{0x2E18,0x10},	
	{0x2E19,0x00},	// 1 reg from 0x1081
	{0x2E1A,0x81},	
	{0x2E1B,0x10},	
	{0x2E1C,0x80},	// update
	{0x2E1D,0x91},	// calibrate SYSCLK
	{0x2E1E,0xFE},	// pause
  };
 const int16_t ad9542_regs_EEPROM_Inst3[15][2] = {	  
	{0x2E10,0x05},	// appl0 config; 6 regs from 0x1000
	{0x2E11,0x00},	
	{0x2E12,0x10},	
	{0x2E13,0x00},	// 1 reg from 0x1081
	{0x2E14,0x81},	
	{0x2E15,0x10},	
	{0x2E16,0x05},	// appl1 config; 6 regs from 0x1400
	{0x2E17,0x00},	
	{0x2E18,0x14},	
	{0x2E19,0x00},	// 1 reg from 0x1481
	{0x2E1A,0x81},	
	{0x2E1B,0x14},	
	{0x2E1C,0x80},	// update
	{0x2E1E,0xFE},	// pause
 };
 const int16_t ad9542_regs_EEPROM_Inst4[15][2] = {	  
	{0x2E10,0x90},	// calibrate APLLs
	{0x2E11,0x80},	// update
	{0x2E12,0xFF},	// end
	{0x2E13,0xFF},	// 1 reg from 0x1081
	{0x2E14,0xFF},	
	{0x2E15,0xFF},	
	{0x2E16,0xFF},	// appl1 config; 6 regs from 0x1400
	{0x2E17,0xFF},	
	{0x2E18,0xFF},	
	{0x2E19,0xFF},	// 1 reg from 0x1481
	{0x2E1A,0xFF},	
	{0x2E1B,0xFF},	
	{0x2E1C,0xFF},	// update
	{0x2E1E,0xFF},	
};  

#define SUCCESS		0
#define FAILURE		-1

#define regGlobal				0x2000
#define regAPLL0Calib			0x2100
#define regAPLL1Calib			0x2200

#define regIoUpdate				0x000F

#define regEepromConfifg		0x2E00
#define regEepromSave			0x2E02
#define regEepromLoad			0x2E03
#define regEepromStatus			0x3000

typedef enum {
	LINUX_I2C
} i2c_type;

typedef struct {
	i2c_type	type;
	uint32_t	id;
	char		*pathname;
	uint32_t	max_speed_hz;
	uint8_t		slave_address;
} i2c_init_param;

typedef struct {
	i2c_type	type;
	uint32_t	id;
	int		fd;
	uint32_t	max_speed_hz;
	uint8_t		slave_address;
} i2c_desc;

int32_t i2c_init(i2c_desc **desc,
		 const i2c_init_param *param)
{
	i2c_desc *descriptor;

	descriptor = (i2c_desc *)malloc(sizeof(*descriptor));
	if (!descriptor)
		return FAILURE;

	descriptor->fd = open(param->pathname, O_RDWR);
	if (descriptor->fd < 0) {
		printf("%s: Can't open device\n\r", __func__);
		free(descriptor);
		return FAILURE;
	}

	descriptor->slave_address = param->slave_address;

	*desc = descriptor;

	return SUCCESS;
}

int32_t i2c_remove(i2c_desc *desc)
{
	int ret;

	ret = close(desc->fd);
	if (ret < 0) {
		printf("%s: Can't close device\n\r", __func__);
		return FAILURE;
	}

	free(desc);

	return SUCCESS;
}

int32_t i2c_write(i2c_desc *desc,
		  uint8_t *data,
		  uint8_t bytes_number,
		  uint8_t stop_bit)
{
	int ret;

	ret = ioctl(desc->fd, I2C_SLAVE, desc->slave_address);
	if (ret < 0) {
		printf("%s: Can't select device\n\r", __func__);
		return FAILURE;
	}

	ret = write(desc->fd, data, bytes_number);
	if (ret < 0) {
		printf("%s: Can't write to file\n\r", __func__);
		return FAILURE;
	}

	if (stop_bit) {
	}

	return SUCCESS;
}

int32_t i2c_read(i2c_desc *desc,
		 uint8_t *data,
		 uint8_t bytes_number,
		 uint8_t stop_bit)
{
	int ret;

	ret = ioctl(desc->fd, I2C_SLAVE, desc->slave_address);
	if (ret < 0) {
		printf("%s: Can't select device\n\r", __func__);
		return FAILURE;
	}

	ret = read(desc->fd, data, bytes_number);
	if (ret < 0) {
		printf("%s: Can't read from file\n\r", __func__);
		return FAILURE;
	}

	if (stop_bit) {
	}

	return SUCCESS;
}

void ad9542_set_reg_value(i2c_desc *desc,
		uint16_t reg_addr,
		uint8_t reg_val)
{
	uint8_t buffer[3];

	buffer[0] = (reg_addr >> 8) & 0xFF;
	buffer[1] = (reg_addr >> 0) & 0xFF;
	buffer[2] = reg_val;

	i2c_write(desc, buffer, 3, 1);
}

void ad9542_get_reg_value(i2c_desc *desc,
		uint16_t reg_addr,
		uint8_t *reg_val)
{
	uint8_t buffer[2];

	buffer[0] = (reg_addr >> 8) & 0xFF;
	buffer[1] = (reg_addr >> 0) & 0xFF;
	
	i2c_write(desc, buffer, 2, 0);
	i2c_read(desc, reg_val, 1, 1);
}

void ad9542_reset (i2c_desc *desc)
{
	ad9542_set_reg_value(desc, 0x0000, 0x41);
	// IO Update
	ad9542_set_reg_value(desc, regIoUpdate, 0x01);
	
	ad9542_set_reg_value(desc, 0x0000, 0x00);	
	// IO Update
	ad9542_set_reg_value(desc, regIoUpdate, 0x01);
}	

int main(void)
{
	const i2c_init_param init_param = {
		LINUX_I2C,
		0,
		"/dev/i2c-0",
		0,
		0x4b,
	};
	i2c_desc *desc;
	uint16_t i;
	uint8_t val;
	
	int32_t configState = SUCCESS;

	printf("Hello\n");

	i2c_init(&desc, &init_param);
	


			
	
	//Verify reg
	
	for(i = 0; i < 5; i++) {
		ad9542_get_reg_value(desc, ad9542_regs_status[i][0], &val);
		if (val != ad9542_regs_status[i][1]) {
			printf("[0x%x]: 0x%x != 0x%x\n",
				ad9542_regs_sysclk[i][0], val, ad9542_regs_status[i][1]);
			configState = FAILURE;
		}
	}	
	
	for(i = 0; i < 9; i++) {
		ad9542_get_reg_value(desc, ad9542_regs_sysclk[i][0], &val);
		if (val != ad9542_regs_sysclk[i][1]) {
			printf("[0x%x]: 0x%x != 0x%x\n",
				ad9542_regs_sysclk[i][0], val, ad9542_regs_sysclk[i][1]);
			configState = FAILURE;
		}
	}
	
	for(i = 0; i < 14; i++) {
		ad9542_get_reg_value(desc, ad9542_regs_apll[i][0], &val);
		if (val != ad9542_regs_apll[i][1]) {
			printf("[0x%x]: 0x%x != 0x%x\n",
				ad9542_regs_apll[i][0], val, ad9542_regs_apll[i][1]);
			configState = FAILURE;
		}
	}	
	
	for(i = 0; i < 13; i++) {
		ad9542_get_reg_value(desc, ad9542_regs_output[i][0], &val);
		if (val != ad9542_regs_output[i][1]) {
			printf("[0x%x]: 0x%x != 0x%x\n",
				ad9542_regs_output[i][0], val, ad9542_regs_output[i][1]);
			configState = FAILURE;
		}
	}		
	if (configState == SUCCESS) 
		printf ("CONFIGURATION SUCCESS \n");
	else {
		printf ("CONFIGURATION FAILED \n");
		return FAILURE;
	}
	
	
	
	i2c_remove(desc);

	printf("Bye\n");

	return SUCCESS;
}
