#!/usr/bin/env bash

# Test basic LISP functionality (ip4 over ip4)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/multihoming/4o4
ODL_CONFIG_DIR=`pwd`/../configs/odl/multihoming/4o4

source test_driver/multihoming.sh

test_multihoming ping "6.0.2.2"
