#!/usr/bin/env bash

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/ndp

source test_driver/ndp.sh

test_neighbor_discovery ping6 "6:0:10::22"
