#!/usr/bin/env bash

# Test LISP source/destination feature (ip4 over ip4)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/sd/l2o4
ODL_CONFIG_DIR=`pwd`/../configs/odl/sd/l2o4

source test_driver/src_dst.sh

test_src_dst_l2 ping "6.0.10.22"
