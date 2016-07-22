#!/usr/bin/env bash

# Test map resover failover scenario
#
# Current implementation selects first map resolver that is configured
# and sends map requests towards it. If there is no response try next one.
# This test verifies whether ITR is able to switch ultimately to a working one.

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/basic/4o4_failover
ODL_CONFIG_DIR=`pwd`/../configs/odl/basic/4o4

source test_driver/resolver_failover.sh

test_resolver_failover ping "6.0.2.2"
