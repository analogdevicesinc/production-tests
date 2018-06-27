Pluto & M2k production scripts
===============================

This is version 2 of the Pluto production scripts, and it also supports M2k.

The main scripts are `production_pluto.sh` & `production_m2k.sh`.

Before running the production scripts, run `setup_env.sh` once.

These scripts must be run with `sudo`, so `sudo ./production_pluto.sh`.

What these scripts will do is loop indefinitely, during which:

1. Initialize FTDI channels to default state
2. If there was an error, or settings not loaded from EEPROM, it will load them from EEPROM 
3. Turn on Ready LED, Turn off In-Progress LED, Wait for button "Go" to be pressed
4. When "Go" button pressed, it will
  * Turn off Done,Error,Ready LEDs
  * Turn on In-Progress LED
5. Run the pre-Flash tests (voltage measurements) and check valid values (script `lib/preflash.sh`)
  * If an error happens, or invalid measurements persist 4 retries, Error LED is turned on and will go to 1.
6. Run the Flash step (script `lib/flash.sh`)
  * Run OpenOCD to load bootloader via JTAG
  * Run dfu-util to flash uboot, uboot-env and firmware to proper partitions
  * power-cycle the board
7. Post flash step is specific to each board
  * for Pluto the `cal_ad9361` script will be run, the linux env will be validated

Configuration structure
=================================

All config for all supported boards is in the `config` folder.

Board specific stuff is under `config/<board>`.

The `digilent-hs2.cfg` & `ftdi4232.cfg` files are used by OpenOCD to operate with these JTAG adapters.
However, each board has it's own specific override for these, in order to include it's own `ps7_init.tcl` which differs per-board.

Under `config/<board>/values.sh` are stored the values for ADC for measurement.

For Pluto specifically (and maybe it will be similar for other boards) the `config/pluto/postflash.sh` is used during the post flash step.
Since this was written in v1 of the script, it is largely unchanged. Similarly this is true for `config/pluto/linux.exp`.

This may change at some point in time to common-alize things.


General/other utilities
=================================

Most scripts will load `config.sh` which overrides paths to make sure that the proper `iio_attr`, `cal_ad9361` and `ft4232h_pin_ctrl` utilities are used.
i.e. the utilities built by `setup_env.sh`.

setup_env.sh
---------------------------------

Run this on a new system when cloning this repo with `./setup_env.sh`.
Requires `sudo` access and the script will request it.

So, you could also run this with `sudo ./setup_env.sh`.

This script sets up all necessary pieces for flashing to work:
* downloads & builds libiio
* downloads plutosdr_scripts and builds  `cal_ad9361`
* builds `ft4232h_pin_ctrl` utility that controls the FTDI channels/pins for SPI and Bitbang functions

Tested/working on Ubuntu 17.10 & newer, and on Raspbian (Raspberry PI) version from April 2018.

eeprom_cfg.sh
--------------------------------

This will write the board's settings to EEPROM.

Must be called with:
```
sudo ./eeprom_cfg.sh save VGAIN=<gain> VREF=<vref> VOFF=<voffset>
```

Order is not important, but all 3 values must be provided.

Similarly:
```
sudo ../eeprom_cfg.sh load
```
will load configuration from EEPROM and display it.

Loading it via this shell script, won't make it available in the shell's env.

selftest.sh
---------------------------------

This will run the ADC self-test for the digital interface.

Run with:
```
sudo ./self_test.sh
```

Expected result is:
```
AA AA 55 55 

!!All good!!
```

toggle_pins.sh
--------------------------------

Generic bitbang wrapper for all FTDI pins.

Can be called with:
```
sudo ./toggle_pins <chan> [pin names]
```

Where:
* <chan> is A,B,C,D - FTDI channels
* pin names are pin0,pin1,...,pin7 to make pins output high, pin0i,pin1i,...,pin7i to make them input, and if omitted, should be active low

measure.sh
---------------------------------

Run a measurement with ADC on the board.

Run with:
```
sudo ./measure.sh <channel>
```

When **channel** is `V0A,V1A,...,V7A,V0B,V1B,...V7B` or `all`. Default is `all`.

flash_pluto.sh, flash_m2k.sh, flash_sidekiqz2.sh
---------------------------------

These scripts handle only the flashing part of the boards.

Are added for convenience.

They call `lib/flash.sh` with target names.

All flashing scripts require files to be presend in `release/<target-name>`

update_m2k_release.sh,update_pluto_release.sh
--------------------------------

These files are also called by the `setup_env.sh` script.

They will download the latest version of the files required for flashing for Pluto/M2k.

Files will be placed in `release/pluto` & `release/m2k`.

**Note:** they will delete existing files in those folders.

If needed, an older version can be specificed as an argument.

Example: `update_m2k_release.sh v0.18`

