#!/usr/bin/env bash

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/nsh
ODL_CONFIG_DIR=`pwd`/../configs/odl/nsh

source test_driver/nsh.sh

# args: dest IP, service path ID, service index
test_nsh "6.0.2.2" 10 200
