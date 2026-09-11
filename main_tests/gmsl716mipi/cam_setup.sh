#!/bin/bash

set -e  # Exit on any error

# GPIO mappings
CAM0_GPIO=34
CAM1_GPIO=46

# Deser model (716 or 792)
DESER=792

# Overlay directory
OVERLAY_DIR="/sys/kernel/config/device-tree/overlays/gmsl"

# Functions
clear_gpios() {
    echo "Clearing GPIOs..."
    sudo gpioset gpiochip0 $CAM0_GPIO=0
    sudo gpioset gpiochip0 $CAM1_GPIO=0
}

apply_overlay() {
    local gpio=$1
    local dtbo_path=$2

    echo "Applying overlay from $dtbo_path on GPIO $gpio"

    # Remove and recreate overlay dir if it exists
    if [ -d "$OVERLAY_DIR" ]; then
        sudo rmdir "$OVERLAY_DIR"
    fi
    sudo mkdir -p "$OVERLAY_DIR"

    # Set GPIO high to enable
    sudo gpioset gpiochip0 $gpio=1
    sleep 0.5

    # Apply overlay
    cat "$dtbo_path" | sudo tee "$OVERLAY_DIR/dtbo" > /dev/null
}

# Usage instructions
usage() {
    echo "Usage: $0 {CAM0|CAM1}"
    exit 1
}

# Validate input
if [ $# -ne 1 ]; then
    usage
fi

case "$1" in
    CAM0)
        clear_gpios
        apply_overlay $CAM0_GPIO "/boot/overlays/gmsl-${DESER}-cam0.dtbo"
        ;;
    CAM1)
        clear_gpios
        apply_overlay $CAM1_GPIO "/boot/overlays/gmsl-${DESER}-cam1.dtbo"
        ;;
    *)
        usage
        ;;
esac