#!/usr/bin/env bash

# Test basic LISP functionality (ip4 over ip4)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/multihoming/l2o4
ODL_CONFIG_DIR=`pwd`/../configs/odl/multihoming/l2o4

source test_driver/multihoming_l2.sh

test_multihoming ping "6.0.1.12"
