#!/bin/sh

ip link set dev eth0 name eth_user
ip link set dev eth_user up
ip addr add 192.168.100.1/24 dev eth_user

route add -net 0.0.0.0 netmask 0.0.0.0 gw 192.168.100.2 dev eth_user
