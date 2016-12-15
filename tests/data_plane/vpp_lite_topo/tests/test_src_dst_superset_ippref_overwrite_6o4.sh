#!/usr/bin/env bash

# Test for overwriting remote mappings from the LISP map-cache

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/sd/overwrite/6o4
ODL_CONFIG_DIR=`pwd`/../configs/odl/sd/overwrite_superset/6o4

source test_driver/src_dst_overwrite.sh

test_src_dst_overwrite_superset ping6 "6:0:2::2"
