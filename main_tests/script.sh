#!/bin/bash

source $SCRIPT_DIR/supported_boards.sh
source $SCRIPT_DIR/setup_env.sh
# to delete the disable sudo function
#source $SCRIPT_DIR/lib/utils.sh

# setup_disable_sudo_passwd() {
# 	sudo_required
# 	sudo -s <<-EOF
# 		if ! grep -q $USER /etc/sudoers ; then
# 			echo "$USER	ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
# 		fi
# 	EOF
# }
# function to create a directory and test file"
create_board_test_file() {
    read -p "Enter a board name: " board
    mkdir ${board,,}
    touch ${board,,}/production_${board^^}.sh
    chmod +x ${board,,}/production_${board^^}.sh

    echo "Production test folder '$board' and 'production_${board^^}' have been created successfully"
    SB="$SUPPORTED_BOARDS ${board^^}"
    new_line="#!/bin/bash"
    echo -e "$new_line\n" >supported_boards.sh
    echo "SUPPORTED_BOARDS=\"$SB\"">>supported_boards.sh
    echo "Added new board to the supported boards list"

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
    echo "Raspberry Pi hostname has been changed. Prepare for reboot."
    sleep 1
    #sudo reboot
}

change_rpi_hostname


# # function to connect to Nebula
# connect_to_nebula() {
#     #cd ../../Downloads//nebula-stuff/
#     #Exec= /nebula -config /etc/nebula/config.yaml
#     ExecStart=/Downloads/nebula-stuff/nebula -config /etc/nebula/config.yaml

#     if [ $? -eq 0 ]; 
#     then
#         echo "Successfully connected to Nebula"
#     else
#         echo "Error: Failed to connect to Nebula"
#         exit 1
#     fi
# }

# #connect_to_nebula 
