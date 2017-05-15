#!/usr/bin/env bash

# Requires scapy for python.

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/dhcp

source test_driver/dhcp.sh

test_dhcp
