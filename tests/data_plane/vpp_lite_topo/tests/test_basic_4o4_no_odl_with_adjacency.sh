#!/usr/bin/env bash

# Test basic LISP functionality without odl and adjacencies configured
# (ip4 over ip4)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/4o4_no_odl_adj

source test_driver/basic_single_icmp.sh

test_single_icmp ping "6.0.2.2"
