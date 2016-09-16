#!/usr/bin/env bash

# Test LISP source/destination feature (ip4 over ip4)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/sd/6o6
ODL_CONFIG_DIR=`pwd`/../configs/odl/sd/6o6

source test_driver/src_dst.sh

test_src_dst ping6 "6:0:2::2"
