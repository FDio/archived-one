#!/usr/bin/env bash

# Test basic LISP functionality without odl (ip6 over ip6)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/6o6_no_odl

source test_driver/basic_no_odl.sh

test_basic_no_odl ping6 "6:0:2::2"

