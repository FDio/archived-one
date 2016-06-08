#!/usr/bin/env bash

# Test EID virualization (4over6)
#
# This test configures two LISP XTRs with two customers. Both customers
# have two client nodes (EID) as depict here:
#
#     eid1    ______     _______    eid2
#  customer1 -|     |    |     |- customer1
#             | xTR |----| xTR |
#  customer2 -|_____| |  |_____|- customer2
#     eid3            |             eid4
#                    ODL
#
# In this scenario both eid1 and eid3 are equal.

VPP_LITE_CONF=`pwd`"/../configs/vpp_lite_config/eid_virt/4o6"
ODL_CONFIG_DIR=`pwd`"/../configs/odl/eid_virt/4o6"

source test_driver/two_customers_topo.sh

test_eid_virtualization ping "6.0.4.4"
