#!/usr/bin/env bash

#
# Test for VPP LISP RTR functionality (6over6).
#
# IMPORTANT: This test needs to have ODL running with following config
# line in etc/custom.properties:
#   lisp.elpPolicy = replace
#
# This test configures a topology of two XTRs and RTR. An ICMP request is
# sent from host1 behind first TR to the host2 behind the second TR.
# Both underlying and overlying networks are IPv6
#

VPP_LITE_CONF=`pwd`"/../configs/vpp_lite_config/rtr_single_iface/6o6/"
ODL_CONFIG_DIR=`pwd`"/../configs/odl/rtr_single_iface/6o6"

source test_driver/rtr_single_iface.sh

test_rtr_single_iface ping6 "6:0:4::4"
