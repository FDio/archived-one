#!/usr/bin/env bash

function smr_rtr_disjoint_clean {
  echo "Clearing all VPP instances.."
  pkill vpp --signal 9

  rm /dev/shm/*

  echo "Cleaning RTR topology.."
  ip netns exec wan4-ns ifconfig vppbr1 down
  ip netns exec wan4-ns brctl delbr vppbr1
  ip netns exec vpp2-rtr-ns ifconfig vppbr2 down
  ip netns exec vpp2-rtr-ns brctl delbr vppbr2
  ip link del dev vpp1 &> /dev/null
  ip link del dev vpp2 &> /dev/null
  ip link del dev vpp1_wan4 &> /dev/null
  ip link del dev rtr1_vpp1 &> /dev/null
  ip link del dev vpp2_rtr &> /dev/null
  ip link del dev rtr_vpp2 &> /dev/null
  ip link del dev odl_wan4 &> /dev/null
  ip link del dev odl_vpp2 &> /dev/null

  ip netns del vpp1-ns &> /dev/null
  ip netns del vpp2-ns &> /dev/null
  ip netns del wan4-ns &> /dev/null
  ip netns del vpp2-rtr-ns &> /dev/null

  odl_clear_all
}

function smr_rtr_disjoint_setup {
  # create namespaces
  ip netns add vpp1-ns
  ip netns add vpp2-ns
  ip netns add wan4-ns
  ip netns add vpp2-rtr-ns

  # create pair interfaces between vpp[1|2], rtr and odl
  ip link add veth_vpp1_wan4 type veth peer name vpp1_wan4
  ip link add veth_rtr_wan4 type veth peer name rtr_wan4
  ip link add veth_vpp2_rtr type veth peer name vpp2_rtr
  ip link add veth_vpp2_wan4 type veth peer name vpp2_wan4
  ip link add veth_rtr_vpp2 type veth peer name rtr_vpp2
  ip link add veth_odl_wan4 type veth peer name odl_wan4
  ip link add veth_odl_vpp2 type veth peer name odl_vpp2

  # enable peer interfaces
  ip link set dev vpp1_wan4 up
  ip link set dev rtr_wan4 up
  ip link set dev vpp2_rtr up
  ip link set dev vpp2_wan4 up
  ip link set dev rtr_vpp2 up
  ip link set dev odl_wan4 up
  ip link set dev odl_vpp2 up

  # enable veth interfaces and set them in the appropriate ip ns
  ip link set dev veth_vpp1_wan4 up netns wan4-ns
  ip link set dev veth_rtr_wan4 up netns wan4-ns
  ip link set dev veth_vpp2_rtr up netns vpp2-rtr-ns
  ip link set dev veth_vpp2_wan4 up netns wan4-ns
  ip link set dev veth_rtr_vpp2 up netns vpp2-rtr-ns
  ip link set dev veth_odl_wan4 up netns wan4-ns
  ip link set dev veth_odl_vpp2 up netns vpp2-rtr-ns

  # vpp1, rtr and odl
  ip netns exec wan4-ns brctl addbr vppbr1
  ip netns exec wan4-ns brctl addif vppbr1 veth_vpp1_wan4
  ip netns exec wan4-ns brctl addif vppbr1 veth_rtr_wan4
  ip netns exec wan4-ns brctl addif vppbr1 veth_vpp2_wan4
  ip netns exec wan4-ns brctl addif vppbr1 veth_odl_wan4
  ip netns exec wan4-ns ifconfig vppbr1 up

  # vpp2, rtr and odl
  ip netns exec vpp2-rtr-ns brctl addbr vppbr2
  ip netns exec vpp2-rtr-ns brctl addif vppbr2 veth_vpp2_rtr
  ip netns exec vpp2-rtr-ns brctl addif vppbr2 veth_rtr_vpp2
  ip netns exec vpp2-rtr-ns brctl addif vppbr2 veth_odl_vpp2
  ip netns exec vpp2-rtr-ns ifconfig vppbr2 up

  # vpp1 to client
  ip link add veth_vpp1 type veth peer name vpp1
  ip link set dev vpp1 up
  ip link set dev veth_vpp1 up netns vpp1-ns

  ip netns exec vpp1-ns \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.2.2/24 dev veth_vpp1
      ip addr add 6:0:2::2/64 dev veth_vpp1
      ip route add 6.0.4.0/24 via 6.0.2.1
      ip route add 6:0:4::0/64 via 6:0:2::1
  "

  # vpp2 to client
  ip link add veth_vpp2 type veth peer name vpp2
  ip link set dev vpp2 up
  ip link set dev veth_vpp2 up netns vpp2-ns

  ip netns exec vpp2-ns \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.4.4/24 dev veth_vpp2
      ip addr add 6:0:4::4/64 dev veth_vpp2
      ip route add 6.0.2.0/24 via 6.0.4.1
      ip route add 6:0:2::0/64 via 6:0:4::1
  "

  # vpp1 to odl
  ip addr add 6.0.3.100/24 dev odl_wan4
  ip addr add 6:0:3::100/64 dev odl_wan4
  ethtool --offload  odl_wan4 rx off tx off

  # vpp2 to odl
  ip addr add 6.0.5.100/24 dev odl_vpp2
  ip addr add 6:0:5::100/64 dev odl_vpp2
  ethtool --offload  odl_vpp2 rx off tx off

  ${VPP_LITE_BIN} \
    unix { log /tmp/vpp1.log cli-listen \
           localhost:5002 full-coredump \
           exec ${VPP_LITE_CONF}/vpp1.config } \
    api-trace { on } api-segment {prefix xtr1}

  ${VPP_LITE_BIN} \
    unix { log /tmp/vpp2.log cli-listen \
           localhost:5003 full-coredump \
           exec ${VPP_LITE_CONF}/vpp2.config } \
    api-trace { on } api-segment {prefix xtr2}

   ${VPP_LITE_BIN} \
    unix { log /tmp/rtr.log cli-listen \
           localhost:5004 full-coredump \
           exec ${VPP_LITE_CONF}/rtr.config } \
    api-trace { on } api-segment {prefix rtr}

  post_curl "add-mapping" ${ODL_CONFIG_FILE1}
  post_curl "add-mapping" ${ODL_CONFIG_FILE2}
}

function smr_rtr_disjoint_reconfigure {
  post_curl "add-mapping" ${ODL_CONFIG_FILE3}
  post_curl "add-mapping" ${ODL_CONFIG_FILE4}
}