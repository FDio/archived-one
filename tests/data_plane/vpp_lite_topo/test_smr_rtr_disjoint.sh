#!/usr/bin/env bash

#
# Test for VPP LISP RTR functionality (4over4).
#
# IMPORTANT: This test needs to have ODL running with following config
# line in etc/custom.properties:
#   lisp.elpPolicy = replace
#
# This test configures a topology of two XTRs and RTR. An ICMP request is
# sent from host1 behind first TR to the host2 behind the second TR.
# Both host and underlaying networks are IPv4.
#

VPP_LITE_CONF=`pwd`"/../configs/vpp_lite_config/smr_rtr_disjoint/"
ODL_CONFIG_DIR=`pwd`"/../configs/odl/smr_rtr_disjoint/"

source test_driver/smr_rtr_disjoint.sh

test_smr_rtr_disjoint "6:0:4::4" wait
