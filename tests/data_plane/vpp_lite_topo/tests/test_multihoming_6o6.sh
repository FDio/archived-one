#!/usr/bin/env bash

# Test LISP multihoming functionality (ip6 over ip6)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/multihoming/6o6
ODL_CONFIG_DIR=`pwd`/../configs/odl/multihoming/6o6

source test_driver/multihoming.sh

test_multihoming ping6 "6:0:2::2"
