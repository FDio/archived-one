#!/usr/bin/env bash

# Test mapping timers expiration for dst-only and src/dst mappings

VPP_LITE_CONF=`pwd`/../configs/vpp_lite_config/sd/4o4
ODL_CONFIG_DIR=`pwd`/../configs/odl/map_timers
VAT_TEMPLATES=`pwd`/../vat_templates

source test_driver/src_dst.sh

test_mapping_timers ping "6.0.2.2"
