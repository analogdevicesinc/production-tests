#!/bin/bash

################### export all #############################
echo 428 > /sys/class/gpio/export ;
echo 429 > /sys/class/gpio/export ;
echo 430 > /sys/class/gpio/export ;
echo 431 > /sys/class/gpio/export ;
echo 432 > /sys/class/gpio/export ;
echo 433 > /sys/class/gpio/export ;
echo 434 > /sys/class/gpio/export ;
echo 435 > /sys/class/gpio/export ;
echo 436 > /sys/class/gpio/export ;
echo 437 > /sys/class/gpio/export ;
echo 438 > /sys/class/gpio/export ;
echo 439 > /sys/class/gpio/export ;
echo 440 > /sys/class/gpio/export ;
echo 441 > /sys/class/gpio/export ;
echo 442 > /sys/class/gpio/export ;
echo 443 > /sys/class/gpio/export ;

echo 460 > /sys/class/gpio/export ;
echo 461 > /sys/class/gpio/export ;
echo 462 > /sys/class/gpio/export ;
echo 463 > /sys/class/gpio/export ;
echo 464 > /sys/class/gpio/export ;
echo 465 > /sys/class/gpio/export ;
echo 466 > /sys/class/gpio/export ;
echo 467 > /sys/class/gpio/export ;
echo 468 > /sys/class/gpio/export ;
echo 469 > /sys/class/gpio/export ;
echo 470 > /sys/class/gpio/export ;
echo 471 > /sys/class/gpio/export ;
echo 472 > /sys/class/gpio/export ;
echo 473 > /sys/class/gpio/export ;
echo 474 > /sys/class/gpio/export ;
echo 475 > /sys/class/gpio/export ;

############### bank 26 ###########################
echo out > /sys/class/gpio/gpio460/direction;
echo out > /sys/class/gpio/gpio461/direction;
echo out > /sys/class/gpio/gpio464/direction;
echo out > /sys/class/gpio/gpio465/direction;

echo in > /sys/class/gpio/gpio462/direction;
echo in > /sys/class/gpio/gpio463/direction;
echo in > /sys/class/gpio/gpio466/direction;
echo in > /sys/class/gpio/gpio467/direction;

############### bank 64 ###########################
echo out > /sys/class/gpio/gpio475/direction;
echo out > /sys/class/gpio/gpio468/direction;
echo out > /sys/class/gpio/gpio471/direction;
echo out > /sys/class/gpio/gpio472/direction;

echo in > /sys/class/gpio/gpio469/direction;
echo in > /sys/class/gpio/gpio470/direction;
echo in > /sys/class/gpio/gpio473/direction;
echo in > /sys/class/gpio/gpio474/direction;

#################### agpio direction ###################
echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio5_direction
echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio8_direction
echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio10_direction
echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio4_direction
echo 1 > /sys/kernel/debug/iio/iio\:device1/agpio6_direction

echo 0 > /sys/kernel/debug/iio/iio\:device1/agpio7_direction
echo 0 > /sys/kernel/debug/iio/iio\:device1/agpio9_direction
echo 0 > /sys/kernel/debug/iio/iio\:device1/agpio11_direction

#################### enable auxadc/aucdac #######################
echo 1 > /sys/bus/iio/devices/iio\:device1/out_voltage2_en
echo 1 > /sys/bus/iio/devices/iio\:device1/out_voltage3_en
echo 1 > /sys/bus/iio/devices/iio\:device1/out_voltage4_en
echo 1 > /sys/bus/iio/devices/iio\:device1/out_voltage5_en

echo 1 > /sys/bus/iio/devices/iio\:device1/in_voltage2_en
echo 1 > /sys/bus/iio/devices/iio\:device1/in_voltage3_en
echo 1 > /sys/bus/iio/devices/iio\:device1/in_voltage4_en
echo 1 > /sys/bus/iio/devices/iio\:device1/in_voltage5_en

################## front pannel gpios ############################
echo out > /sys/class/gpio/gpio428/direction;
echo out > /sys/class/gpio/gpio430/direction;
echo out > /sys/class/gpio/gpio432/direction;
echo out > /sys/class/gpio/gpio434/direction;
echo out > /sys/class/gpio/gpio436/direction;
echo out > /sys/class/gpio/gpio438/direction;
echo out > /sys/class/gpio/gpio440/direction;
echo out > /sys/class/gpio/gpio442/direction;
echo 0 > /sys/class/gpio/gpio428/value;
echo 0 > /sys/class/gpio/gpio430/value;
echo 0 > /sys/class/gpio/gpio432/value;
echo 0 > /sys/class/gpio/gpio434/value;
echo 0 > /sys/class/gpio/gpio436/value;
echo 0 > /sys/class/gpio/gpio438/value;
echo 0 > /sys/class/gpio/gpio440/value;
echo 0 > /sys/class/gpio/gpio442/value;

######## make sure all gpios set to 0########
echo out > /sys/class/gpio/gpio429/direction;
echo out > /sys/class/gpio/gpio431/direction;
echo out > /sys/class/gpio/gpio433/direction;
echo out > /sys/class/gpio/gpio435/direction;
echo out > /sys/class/gpio/gpio437/direction;
echo out > /sys/class/gpio/gpio439/direction;
echo out > /sys/class/gpio/gpio441/direction;
echo out > /sys/class/gpio/gpio443/direction;
echo 0 > /sys/class/gpio/gpio429/value;
echo 0 > /sys/class/gpio/gpio431/value;
echo 0 > /sys/class/gpio/gpio433/value;
echo 0 > /sys/class/gpio/gpio435/value;
echo 0 > /sys/class/gpio/gpio437/value;
echo 0 > /sys/class/gpio/gpio439/value;
echo 0 > /sys/class/gpio/gpio441/value;
echo 0 > /sys/class/gpio/gpio443/value;
############################################

echo in > /sys/class/gpio/gpio429/direction;
echo in > /sys/class/gpio/gpio431/direction;
echo in > /sys/class/gpio/gpio433/direction;
echo in > /sys/class/gpio/gpio435/direction;
echo in > /sys/class/gpio/gpio437/direction;
echo in > /sys/class/gpio/gpio439/direction;
echo in > /sys/class/gpio/gpio441/direction;
echo in > /sys/class/gpio/gpio443/direction;

######################export gpio for adrv9002 clksrc, for ext_lo test ###############################
#echo 413 > /sys/class/gpio/export;

# echo out > /sys/class/gpio/gpio413/direction;
# echo 1 > /sys/class/gpio/gpio413/value;
