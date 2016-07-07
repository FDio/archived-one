#!/usr/bin/env bash

# Test basic LISP functionality with two ongoing traffics - 4o4 and 6o6

ODL_CONFIG_DIR=`pwd`/../configs/odl/basic/6o6
VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/4o4_and_6o6

source test_driver/basic_multi_traffic.sh

test_basic_multi_traffic ping6 "6:0:2::2" ping "6.0.2.2"

