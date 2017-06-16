#!/usr/bin/env bash

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/nsh
ODL_CONFIG_DIR=`pwd`/../configs/odl/nsh

source test_driver/nsh.sh

test_nsh
