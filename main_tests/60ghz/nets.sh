#!/bin/bash
USAGE=$(cat <<-END
A small script that creates 2 network namespaces called net0 and net1.
This allows iperf tests to be run on the same computer, through two different
network cards or interfaces, and bypasses the kernel internal loopback so
data is actually sent to the physical devices.

On net0, iperf is run as server, reachable at 192.168.1.1 port 5001.

On net1, iperf can be run as a client:
	ip netns exec net1 iperf -c 192.168.1.1 -i1

Usage:
    nets.sh up
    nets.sh down

Author:
    darius.berghe@analog.com
END

)

if [[ $# -eq 0 ]] ; then
    echo "$USAGE"
    exit 0
fi
IF=$(ls /sys/class/net | grep ^e)
IFC=$(echo $IF | wc -w)
IFA=( $IF )

if [ $1 == "up" ]
then
    if [[ $(ip netns list) == *"net0"* ]]; then
        echo "Already up."
        exit 0
    fi
    if [[ $IFC -lt 2 ]]; then
        echo "You are required to have 2 network interfaces, but only have $IFC"
	echo $IF
	exit 0
    fi
    ip netns add net0
    ip netns add net1
    ip link set ${IFA[0]} netns net0
    ip link set ${IFA[1]} netns net1
    ip netns exec net0 ip addr add dev ${IFA[0]} 192.168.1.1/24
    ip netns exec net1 ip addr add dev ${IFA[1]} 192.168.1.2/24
    ip netns exec net0 ip link set ${IFA[0]} $1
    echo "net0 uses ${IFA[0]}"
    ip netns exec net1 ip link set ${IFA[1]} $1
    echo "net1 uses ${IFA[1]}"
    ip netns exec net0 iperf -s > /dev/null 2>&1 &
    echo "iperf server running with pid $!"

elif [ $1 == "down" ]
then
    if [[ -z $(ip netns list) ]]
    then
        echo "Already down"
        exit 0
    fi
    killall iperf
    ip netns del net0
    ip netns del net1
else
    echo "$USAGE"
fi
