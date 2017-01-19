#!/usr/bin/env bash

# Manual test for LISP RLOC probe
#
# Test procedure:
# 1) run the test
# 2) the test stops its execution after few seconds.
#    At that moment there should be a LISP tunnel configured
# 3) Attach wireshark to intervpp1 or intervpp2 interface and check if there
#    are map-requests and map-replies coming forth and back with RLOC probe
#    bit set in the LISP header.

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/4o4_rloc_probe
ODL_CONFIG_DIR=`pwd`/../configs/odl/basic/4o4

source test_driver/basic.sh

test_rloc_probe ping "6.0.2.2"
