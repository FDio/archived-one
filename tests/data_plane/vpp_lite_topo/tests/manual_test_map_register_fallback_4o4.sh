#!/usr/bin/env bash

# Test LISP map register feature (ip4 over ip4)

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/4o4_map_register_fallback

source test_driver/basic.sh

test_basic_map_register_fallback ping "6.0.2.2"
