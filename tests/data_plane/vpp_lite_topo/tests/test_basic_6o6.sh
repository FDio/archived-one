#!/usr/bin/env bash

# Test basic LISP functionality (ip6 over ip6)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/6o6
ODL_CONFIG_DIR=`pwd`/../configs/odl/basic/6o6

source test_driver/basic.sh

test_basic ping6 "6:0:2::2"
