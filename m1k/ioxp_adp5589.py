"""Module to control IOXP ADP5589."""

import global_

global_.init()


def direction_port_a(direction):
    """Set port A pins as input or output."""
    gpio_direction_a_reg = 0x30
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, gpio_direction_a_reg, direction)


def rpull_config_a(state):
    """Set pull up or pull down resistor for R0 ... R3."""
    rpull_config_a_reg = 0x19
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, rpull_config_a_reg, state)


def rpull_config_b(state):
    """Set pull up or pull down resistor for R4 ... R7."""
    rpull_config_b_reg = 0x1A
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, rpull_config_b_reg, state)


def rpull_config_c(state):
    """Set pull up or pull down resistor for C0 ... C3."""
    rpull_config_c_reg = 0x1B
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, rpull_config_c_reg, state)


def rpull_config_d(state):
    """Set pull up or pull down resistor for C4 ... C7."""
    rpull_config_d_reg = 0x1C
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, rpull_config_d_reg, state)


def rpull_config_e(state):
    """Set pull up or pull down resistor for C8 ... C10."""
    rpull_config_d_reg = 0x1D
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, rpull_config_d_reg, state)


def data_out_port_a(data_out):
    """Set port A pins state."""
    gpo_data_out_a_reg = 0x2A
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, gpo_data_out_a_reg, data_out)


def direction_port_b(direction):
    """Set port B pins as input or output."""
    gpio_direction_b_reg = 0x31
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, gpio_direction_b_reg, direction)


def data_out_port_b(data_out):
    """Set port B pins state."""
    gpo_data_out_b_reg = 0x2B
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, gpo_data_out_b_reg, data_out)


def direction_port_c(direction):
    """Set port C pins as input or output."""
    gpio_direction_c_reg = 0x32
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, gpio_direction_c_reg, direction)


def data_out_port_c(data_out):
    """Set port C pins state."""
    gpo_data_out_a_reg = 0x2C
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, gpo_data_out_a_reg, data_out)


def setup_digital_in_out():
    """Set pins used for DIO test to return logic state.

    Interrupt is active high and debunce is disable for used pins as input.
    Write GPI_INT_LEVEL_B and DEBOUNCE_DIS_B registers and read GPI_STATUS_B.
    """
    direction_port_b(0x00)
    gpi_int_level_b_data = debounce_dis_b_data = 0xf4
    gpi_int_level_b_reg = 0x1F
    debounce_dis_b_reg = 0x28
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, gpi_int_level_b_reg, gpi_int_level_b_data)
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, debounce_dis_b_reg, debounce_dis_b_data)


def get_status_digital_in_out():
    """Set pins used for DIO test to return logic state.

    Interrupt is active high and debunce is disable for used pins as input.
    Write GPI_INT_LEVEL_B and DEBOUNCE_DIS_B registers and read GPI_STATUS_B.
    """
    gpi_status_b_reg = 0x17
    status = hex(global_.bus.read_byte_data(
        global_.EXPANDER_ID, gpi_status_b_reg))
    # print status
    return status


def get_button_status():
    """Set pins used for DIO test to return logic state.

    Interrupt is active high and debunce is disable for used pins as input.
    Write GPI_INT_LEVEL_B and DEBOUNCE_DIS_B registers and read GPI_STATUS_B.
    """
    direction_port_b(0x00)
    gpi_int_level_b_data = debounce_dis_b_data = 0x08
    gpi_int_level_b_reg = 0x1F
    debounce_dis_b_reg = 0x28
    gpi_status_b_reg = 0x17
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, gpi_int_level_b_reg, gpi_int_level_b_data)
    global_.bus.write_byte_data(
        global_.EXPANDER_ID, debounce_dis_b_reg, debounce_dis_b_data)
    return hex(global_.bus.read_byte_data(
        global_.EXPANDER_ID, gpi_status_b_reg))


def update(list_item, string_reference, data_reg_val, direction_reg_val):
    """Update data and direction registers."""
    if list_item == string_reference:
        data_reg_val[0] = data_reg_val[0] | data_reg_val[1]
        direction_reg_val[0] = direction_reg_val[0] | direction_reg_val[1]
    return data_reg_val[0], direction_reg_val[0]


def gpo_set_port_a(status_list):
    """Set selected pins as output and their logis state for port A."""
    index = 0
    gpo_data_a = 0x00
    gpo_direction_a = 0xff
    repeat = len(status_list)
    while index in range(repeat):
        data = update(status_list[index], 'GPIO_7__1',
                      [gpo_data_a, 0x01], [gpo_direction_a, 0x01])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_7__0',
                      [gpo_data_a, 0x00], [gpo_direction_a, 0x01])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_9__1',
                      [gpo_data_a, 0x02], [gpo_direction_a, 0x02])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_9__0',
                      [gpo_data_a, 0x00], [gpo_direction_a, 0x02])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_10__1',
                      [gpo_data_a, 0x04], [gpo_direction_a, 0x04])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_10__0',
                      [gpo_data_a, 0x00], [gpo_direction_a, 0x04])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'EN_1V2__1',
                      [gpo_data_a, 0x08], [gpo_direction_a, 0x08])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'EN_1V2__0',
                      [gpo_data_a, 0x00], [gpo_direction_a, 0x08])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_0__1',
                      [gpo_data_a, 0x10], [gpo_direction_a, 0x10])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_0__0',
                      [gpo_data_a, 0x00], [gpo_direction_a, 0x10])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_3__1',
                      [gpo_data_a, 0x20], [gpo_direction_a, 0x20])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_3__0',
                      [gpo_data_a, 0x00], [gpo_direction_a, 0x20])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_1__1',
                      [gpo_data_a, 0x40], [gpo_direction_a, 0x40])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_1__0',
                      [gpo_data_a, 0x00], [gpo_direction_a, 0x40])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_2__1',
                      [gpo_data_a, 0x80], [gpo_direction_a, 0x80])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        data = update(status_list[index], 'GPIO_2__0',
                      [gpo_data_a, 0x00], [gpo_direction_a, 0x80])
        gpo_data_a, gpo_direction_a = data[0], data[1]
        index += 1
    global_.bus.write_byte_data(global_.EXPANDER_ID, 0x30, gpo_direction_a)
    global_.bus.write_byte_data(global_.EXPANDER_ID, 0x2A, gpo_data_a)


def gpo_set_port_b(status_list):
    """Set selected pins as output and their logis state for port B."""
    index = 0
    gpo_data_b = 0x00
    gpo_direction_b = 0xff
    repeat = len(status_list)
    while index in range(repeat):
        data = update(status_list[index], 'GPIO_5__1',
                      [gpo_data_b, 0x01], [gpo_direction_b, 0x01])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'GPIO_5__0',
                      [gpo_data_b, 0x00], [gpo_direction_b, 0x01])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'GPIO_6__1',
                      [gpo_data_b, 0x02], [gpo_direction_b, 0x02])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'GPIO_6__0',
                      [gpo_data_b, 0x00], [gpo_direction_b, 0x02])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], '3V3_M1K__1',
                      [gpo_data_b, 0x04], [gpo_direction_b, 0x04])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], '3V3_M1K__0',
                      [gpo_data_b, 0x00], [gpo_direction_b, 0x04])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'LED_1__1',
                      [gpo_data_b, 0x08], [gpo_direction_b, 0x08])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'LED_1__0',
                      [gpo_data_b, 0x00], [gpo_direction_b, 0x08])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'PIO_3__1',
                      [gpo_data_b, 0x10], [gpo_direction_b, 0x10])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'PIO_3__0',
                      [gpo_data_b, 0x00], [gpo_direction_b, 0x10])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'PIO_2__1',
                      [gpo_data_b, 0x20], [gpo_direction_b, 0x20])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'PIO_2__0',
                      [gpo_data_b, 0x00], [gpo_direction_b, 0x20])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'PIO_1__1',
                      [gpo_data_b, 0x40], [gpo_direction_b, 0x40])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'PIO_1__0',
                      [gpo_data_b, 0x00], [gpo_direction_b, 0x40])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'PIO_0__1',
                      [gpo_data_b, 0x80], [gpo_direction_b, 0x80])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        data = update(status_list[index], 'PIO_0__0',
                      [gpo_data_b, 0x00], [gpo_direction_b, 0x80])
        gpo_data_b, gpo_direction_b = data[0], data[1]
        index += 1
    global_.bus.write_byte_data(global_.EXPANDER_ID, 0x31, gpo_direction_b)
    global_.bus.write_byte_data(global_.EXPANDER_ID, 0x2B, gpo_data_b)


def gpo_set_port_c(status_list):
    """Set selected pins as output and their logis state for port C."""
    index = 0
    gpo_data_c = 0x00
    gpo_direction_c = 0xff
    repeat = len(status_list)
    while index in range(repeat):
        data = update(status_list[index], 'LED_2__1',
                      [gpo_data_c, 0x01], [gpo_direction_c, 0x01])
        gpo_data_c, gpo_direction_c = data[0], data[1]
        data = update(status_list[index], 'LED_2__0',
                      [gpo_data_c, 0x00], [gpo_direction_c, 0x01])
        gpo_data_c, gpo_direction_c = data[0], data[1]
        data = update(status_list[index], 'USB_GPO__1',
                      [gpo_data_c, 0x02], [gpo_direction_c, 0x02])
        gpo_data_c, gpo_direction_c = data[0], data[1]
        data = update(status_list[index], 'USB_GPO__0',
                      [gpo_data_c, 0x00], [gpo_direction_c, 0x02])
        gpo_data_c, gpo_direction_c = data[0], data[1]
        data = update(status_list[index], 'GPIO_8__1',
                      [gpo_data_c, 0x04], [gpo_direction_c, 0x04])
        gpo_data_c, gpo_direction_c = data[0], data[1]
        data = update(status_list[index], 'GPIO_8__0',
                      [gpo_data_c, 0x00], [gpo_direction_c, 0x04])
        gpo_data_c, gpo_direction_c = data[0], data[1]
        index += 1
    global_.bus.write_byte_data(global_.EXPANDER_ID, 0x32, gpo_direction_c)
    global_.bus.write_byte_data(global_.EXPANDER_ID, 0x2C, gpo_data_c)


def gpo_set(status_list):
    """Set selected pins as output and their logis state."""
    gpo_set_port_a(status_list)
    gpo_set_port_b(status_list)
    gpo_set_port_c(status_list)


def gpo_set_ac(status_list):
    """Set selected pins as output and their logis state."""
    gpo_set_port_a(status_list)
    gpo_set_port_c(status_list)
