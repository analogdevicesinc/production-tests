ANSWER=1

echo
python3 -m pytest --color yes -vs /home/analog/pyadi-iio/test/test_fmcomms4_prod.py --uri="ip:127.0.0.1" --adi-hw-map --hw=fmcomms4
ANSWER=$?
exit $ANSWER
