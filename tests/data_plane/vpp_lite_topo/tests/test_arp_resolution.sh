#!/usr/bin/env bash

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/arp

source test_driver/arp.sh

test_arp_resolution ping "6.0.10.22"
