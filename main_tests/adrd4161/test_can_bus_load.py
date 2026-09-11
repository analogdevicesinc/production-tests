import subprocess
import time
import re
import sys

DURATION = 2.0
MAX_LOAD_OK = 90.0

BUSLOAD_CMD = ["canbusload", "can0@500000", "slcan0@500000"]
CANGEN_CMD = ["cangen", "slcan0", "-g0", "-x", "-i"]

busload = subprocess.Popen(
    BUSLOAD_CMD,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True
)

cangen = subprocess.Popen(
    CANGEN_CMD,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL
)

time.sleep(DURATION)

cangen.terminate()
busload.terminate()

try:
    out, _ = busload.communicate(timeout=1.0)
except subprocess.TimeoutExpired:
    busload.kill()
    out, _ = busload.communicate()

try:
    cangen.wait(timeout=1.0)
except subprocess.TimeoutExpired:
    cangen.kill()

percents = [float(x) for x in re.findall(r"(\d+(?:\.\d+)?)\s*%", out)]

if not percents:
    sys.exit(2)

max_load = max(percents)

if max_load > MAX_LOAD_OK:
    sys.exit(1)

sys.exit(0)
