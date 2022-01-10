
echo
python3 -m pytest --color yes -vs /home/analog/pyadi-iio/test/test_dcxo.py --uri="ip:127.0.0.1" --adi-hw-map --hw=fmcomms4 > calib.txt

cat calib.txt | grep "1 passed" &>/dev/null
result=$?
if [ result -eq 0 ]; then
    exit $result
else
    cat calib.txt | grep "1 skipped" &>/dev/null
    result=$?
    if [ result -eq 0 ]; then
        exit 2
    else
        exit 1
    fi
fi

