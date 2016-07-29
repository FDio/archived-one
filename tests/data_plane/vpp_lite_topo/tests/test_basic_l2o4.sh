#!/usr/bin/env bash

# Test basic LISP functionality (l2 over ip4)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/l2o4
ODL_CONFIG_DIR=`pwd`/../configs/odl/basic/l2o4

source test_driver/basic_l2.sh

test_basic ping "6.0.1.12"
