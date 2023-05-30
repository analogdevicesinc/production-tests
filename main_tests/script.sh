#!/bin/bash

echo SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/supported_boards.sh
#source $SCRIPT_DIR/setup_env.sh

# function to create a directory and test file"
create_board_test_file() {
    read -p "Enter a board name: " board
    touch &SCRIPT_DIR/production_${board^^}.sh
    chmod +x production_${board^^}.sh
    mkdir ${board,,}
    touch ${board,,}/production.sh
    chmod +x ${board,,}/production.sh

    echo "Production test folder '$board' and 'production_${board^^}' have been created successfully"
    sed -i "s/SUPPORTED_BOARDS=\"*/SUPPORTED_BOARDS=\"${board^^} /" supported_boards.sh
    echo "Successfully added board to the supported_boards.sh file"

}
create_board_test_file 

# function to create setup function to setup_env
add_board_function() {
    sed -i "/## Board Function Area ##/a\\\nsetup_${board^^}() {\n\n}" setup_env.sh
    echo "Added board setup function successfully"
}

add_board_function

# function to change raspberry pi hostname
change_rpi_hostname(){
    cd /etc
    sudo echo "pi" > hostname
    sudo sed -i 's/analog/pi/g' hosts
    echo "Raspberry Pi hostname has been changed. Prepare for reboot."
    sleep 1
    sudo reboot
}

change_rpi_hostname

