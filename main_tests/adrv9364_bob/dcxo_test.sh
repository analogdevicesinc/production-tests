
SCRIPT_DIR="$(readlink -f $(dirname $0))"

echo
python3 -m pytest --color yes -vs $SCRIPT_DIR/../work/pyadi-iio/test/test_dcxo.py --uri="ip:analog.local" --adi-hw-map --hw=adrv9364 | tee calib.txt

cat calib.txt | grep "1 passed" &>/dev/null
result=$?
if [ $result -eq 0 ]; then
    exit $result
else
    cat calib.txt | grep "1 skipped" &>/dev/null
    result=$?
    if [ $result -eq 0 ]; then
        exit 2
    else
        exit 1
    fi
fi

