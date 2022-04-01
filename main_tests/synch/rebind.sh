hmc7044_spi=`ls /sys/bus/spi/drivers/hmc7044/ | grep spi`
ad9545_spi=`ls /sys/bus/spi/drivers/ad9545/ | grep spi`

echo $hmc7044_spi > /sys/bus/spi/drivers/hmc7044/unbind
echo $ad9545_spi > /sys/bus/spi/drivers/ad9545/unbind

echo $ad9545_spi > /sys/bus/spi/drivers/ad9545/bind
echo $hmc7044_spi > /sys/bus/spi/drivers/hmc7044/bind
echo 'Rebind done'
