#!/usr/bin/env bash

#
# Test for VPP LISP RTR functionality (4over6).
#
# IMPORTANT: This test needs to have ODL running with following config
# line in etc/custom.properties:
#   lisp.elpPolicy = replace
#
# This test configures a topology of two XTRs and RTR. An ICMP request is
# sent from host1 behind first TR to the host2 behind the second TR.
# Hosts resides in IPv4 network, underlying network is IPv6
#

VPP_LITE_CONF=`pwd`"/../configs/vpp_lite_config/rtr_single_iface/4o6/"
ODL_CONFIG_DIR=`pwd`"/../configs/odl/rtr_single_iface/4o6"

source test_driver/rtr_single_iface.sh

test_rtr_single_iface ping "6.0.4.4"
