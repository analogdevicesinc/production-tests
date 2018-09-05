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


Important utilities
================================

setup_env.sh
---------------------------------

Run this on a new system when cloning this repo with `./setup_env.sh <pluto|m2k>`.
Requires `sudo` access and the script will request it.
This script will also install the current user.

This script sets up all necessary pieces for flashing to work:
* downloads & builds libiio
* downloads plutosdr_scripts and builds  `cal_ad9361`
* builds `ft4232h_pin_ctrl` utility that controls the FTDI channels/pins for SPI and Bitbang functions
* downloads builds Scopy for M2k
* disable some default XUbuntu auto-start services that may complicate things
* installs running user in /etc/sudoers with NOPASSWD: directive
* installs `init.sh` in the udev rules to be called whenever the JIG board is plugged in
* installs `production_<pluto|m2k>.sh` to the .config/autostart folder to start production script on startup
* installs `autosave_logs.sh` to the .config/autostart folder ; this will save logs on anything mounted under /media/ that has an `autosave_logs` folder
* installs `call_home` to the .config/autostart folder ; this will periodically try to open a reverse SSH tunnel back to testjig.hopto.org on port 2222

Tested/working on XUbuntu 18.04. Currently XUbuntu is the preferred distro; it could work on other Ubuntu distros as well, as long as XFCE4 is available & installed.

autosave_logs.sh
---------------------------------

It's running as a service installed by setup_env.sh.

This will save logs on anything mounted under /media/ that has an `autosave_logs` folder.

Once the logs are saved, it will wait for 1 minute and save them again if the folder is still available.

The script itself is pretty dumb. All logs under the `logs` subfolder will be tar + gzipped to the `autosave_logs` folder in a file with format "<hostname>-<date>.tar.gz".


init.sh
--------------------------------

Initiates all FTDI pins + GPIO expander pins to default values.
Only initiates channels A, B & D on FTDI, since C is reserved for UART talk.

This is is called by udev whenever a JIG board is plugged in.

The logic is also called when the `production_<m2k|pluto>.sh` scripts run.

This is important to run because it inits all the GPIOs to valid states.

m2k_power_calib_meas.sh
--------------------------------

Contains the logic for calibrating the power-supplies for M2k.
It checks that the values are withing valid ranges.

It's called by the `config/m2k/scopy1.js` script.

config/<m2k|pluto>/postflash.sh, config/m2k/scopy1.js, config/m2k/scopy2.js
--------------------------------

Post-flashing scripts for Pluto & M2k have been added to the config/<board> folders.

These steps are very specific to each board.

For M2k, Scopy is being run with the scopy1.js & scopy2.js. The reason it was split into 2 parts, is because `scopy1.js` is run without showing the Scopy GUI; in that part it's more important to show the console. There is currently a problem when showing the Scopy GUI [when it was hidden initially], in that it doesn't render properly.


ref_measure_ctl.sh
--------------------------------

Used for M2k in `config/m2k/scopy1.js`.

It toggles some GPIOs on the GPIO expander, and then will measure the values. The step for measuring these refs, requires enabling them via some GPIOs on the GPIO expander, and then measuring, so the step was hidden behind this script.

scp.sh
--------------------------------

Used for M2k in `config/m2k/scopy1.js`.
Writes the calibration file (generated by `config/m2k/scopy1.js` together with `m2k_power_calib_meas.sh`) via SCP to the M2k device.

SCP is more reliable than using the auto-mounted drive from M2k.

This also handles passwd login via the `sshpass` tool.

Outputs `ok` if all went well.

Called with `scp.sh <src> <dst> <pass>`

wait_pins.sh
--------------------------------

Used in `production_<pluto|m2k>.sh` and `config/m2k/scopy1.js` to wait for a pin to be asserted.

Called with `wait_pins.sh <chan> <pin>`, where  chan can be A,B,C,D or GPIO_EXP1 and pin can be `pinX` [ X = 0..7 ].

scopy
--------------------------------

Wrapper for calling the Scopy binary that was built by `setup_env.sh`.

call_home
--------------------------------

A simple loop that will open a reverse SSH tunnel to `testjig.hopto.org` on port 2222.

This tunnel can then be used to connect back to the test-jigs from the `testjig.hopto.org` host via  `ssh -p <port> localhost`, where port is the `REVERSE_SSH_PORT=2000` from the `call_home` script.

General/other utilities
=================================

Most scripts will load `config.sh` which overrides paths to make sure that the proper `iio_attr`, `cal_ad9361` and `ft4232h_pin_ctrl` utilities are used.
i.e. the utilities built by `setup_env.sh`.

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

flash_<pluto|m2k|sidekiqz2>.sh, postflash_<m2k|pluto>.sh, preflash_<m2k|pluto>.sh
---------------------------------

These scripts handle flashing, preflash, postflash part of the boards.

Are added for convenience.

The flashing scripts require files to be presend in `release/<target-name>`

update_<m2k|pluto>_release.sh
--------------------------------

These files are also called by the `setup_env.sh` script.

They will download the latest version of the files required for flashing for Pluto/M2k.

Files will be placed in `release/pluto` & `release/m2k`.

**Note:** they will delete existing files in those folders.

If needed, an older version can be specificed as an argument.

Example: `update_m2k_release.sh v0.18`

