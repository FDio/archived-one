#!/usr/bin/env bash

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/ipsec/6o6

source test_driver/basic_single_icmp.sh

test_single_icmp_no_counters ping6 "6:0:2::2"
