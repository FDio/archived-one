#!/usr/bin/env bash

# Test basic LISP functionality (ip4 over ip4)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/4o4
ODL_CONFIG_DIR=`pwd`/../configs/odl/basic/4o4

source test_driver/basic.sh

test_basic ping "6.0.2.2"
