#!/usr/bin/env bash

# Test negative mapping

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/4o4_neg_mapping

source test_driver/basic_no_odl.sh

test_negative_mapping ping "6.0.2.2"
