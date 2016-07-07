#!/usr/bin/env bash

#
# Test for VPP LISP RTR functionality with EID virualization.
#
# IMPORTANT: This test needs to have ODL running with following config
# line in etc/custom.properties:
#   lisp.elpPolicy = replace
#
# This test configures a topology of two XTRs and RTR. An ICMP request is
# sent from host1 behind first TR to the host2 behind the second TR.
#
#

VPP_LITE_CONF=`pwd`"/../configs/vpp_lite_config/rtr_two_iface_two_customers/6o46"
ODL_CONFIG_DIR=`pwd`"/../configs/odl/rtr_two_iface_two_customers/6o46"

source test_driver/rtr_two_iface_two_customers.sh

test_rtr_two_iface_two_customers ping6 "6:0:4::4"
