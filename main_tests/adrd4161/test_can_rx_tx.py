import can
import sys

RX_IF = "slcan0"
TX_IF = "can0"
ARB_ID = 0x123
DATA = bytes.fromhex("45 67")

rx_bus = can.interface.Bus(channel=RX_IF, interface="socketcan")

tx_bus = can.interface.Bus(channel=TX_IF, interface="socketcan")

msg = can.Message(
    arbitration_id=ARB_ID,
    data=DATA,
    is_extended_id=False
)

tx_bus.send(msg)

rx_msg = rx_bus.recv(timeout=2.0)

if rx_msg is None:
    print("No frame received.")
    rx_bus.shutdown()
    tx_bus.shutdown()
    sys.exit(1)

if rx_msg.arbitration_id != ARB_ID:
    print("Wrong CAN ID")
    rx_bus.shutdown()
    tx_bus.shutdown()
    sys.exit(2)

rx_bus.shutdown()
tx_bus.shutdown()
sys.exit(0)
