#!/usr/bin/env bash

# Test basic LISP functionality without odl and adjacencies configured
# (ip6 over ip6)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/6o6_no_odl_adj
VAT_TEMPLATES=`pwd`/../vat_templates

source test_driver/basic_single_icmp.sh

test_single_icmp ping6 "6:0:2::2" "6:0:1::/64" "6:0:2::/64" "6:0:3::1" "6:0:3::2" "1" "104"
