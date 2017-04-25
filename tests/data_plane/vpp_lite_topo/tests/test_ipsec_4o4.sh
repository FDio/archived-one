#!/usr/bin/env bash

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/ipsec/4o4

source test_driver/basic_single_icmp.sh

test_single_icmp_no_counters ping "6.0.2.2"
