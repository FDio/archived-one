#!/usr/bin/env bash

# Test basic LISP functionality (l2 over ip4)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/l2o4_with_adj
VAT_TEMPLATES=`pwd`/../vat_templates

source test_driver/basic_l2.sh

test_single_icmp ping "6.0.1.12" "08:11:11:11:11:11" "08:22:22:22:22:22" "6.0.3.1" "6.0.3.2" "1" "98"
