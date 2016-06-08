#!/usr/bin/env bash

function two_customers_topo_clean {
  echo "Clearing all VPP instances.."
  pkill vpp --signal 9
  rm /dev/shm/*

  echo "Cleaning topology.."
  ip netns exec intervpp-ns ifconfig vppbr1 down
  ip netns exec intervpp-ns brctl delbr vppbr1
  ip link del dev vpp1_cus1 &> /dev/null
  ip link del dev vpp2_cus1 &> /dev/null
  ip link del dev vpp1_cus2 &> /dev/null
  ip link del dev vpp2_cus2 &> /dev/null
  ip link del dev intervpp1 &> /dev/null
  ip link del dev intervpp2 &> /dev/null
  ip link del dev odl &> /dev/null

  ip netns del vpp1-cus1-ns &> /dev/null
  ip netns del vpp1-cus2-ns &> /dev/null
  ip netns del vpp2-cus1-ns &> /dev/null
  ip netns del vpp2-cus2-ns &> /dev/null
  ip netns del intervpp-ns &> /dev/null

  odl_clear_all
}

function two_customers_topo_setup {
  echo "Configuring topology..."
  ip netns add vpp1-cus1-ns
  ip netns add vpp1-cus2-ns
  ip netns add vpp2-cus1-ns
  ip netns add vpp2-cus2-ns
  ip netns add intervpp-ns

  ip link add veth_intervpp1 type veth peer name intervpp1
  ip link add veth_intervpp2 type veth peer name intervpp2
  ip link add veth_odl type veth peer name odl
  ip link set dev intervpp1 up
  ip link set dev intervpp2 up
  ip link set dev odl up
  ip link set dev veth_intervpp1 up netns intervpp-ns
  ip link set dev veth_intervpp2 up netns intervpp-ns
  ip link set dev veth_odl up netns intervpp-ns

  ip netns exec intervpp-ns brctl addbr vppbr1
  ip netns exec intervpp-ns brctl addif vppbr1 veth_intervpp1
  ip netns exec intervpp-ns brctl addif vppbr1 veth_intervpp2
  ip netns exec intervpp-ns brctl addif vppbr1 veth_odl
  ip netns exec intervpp-ns ifconfig vppbr1 up

  # customer1 configuration on vpp1
  ip link add veth_vpp1_cus1 type veth peer name vpp1_cus1
  ip link set dev vpp1_cus1 up
  ip link set dev veth_vpp1_cus1 up netns vpp1-cus1-ns

  ip netns exec vpp1-cus1-ns \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.2.2/24 dev veth_vpp1_cus1
      ip addr add 6:0:2::2/64 dev veth_vpp1_cus1
      ip route add 6.0.4.0/24 via 6.0.2.1
      ip route add 6:0:4::0/64 via 6:0:2::1
  "

  # customer2 configuration on vpp1
  ip link add veth_vpp1_cus2 type veth peer name vpp1_cus2
  ip link set dev vpp1_cus2 up
  ip link set dev veth_vpp1_cus2 up netns vpp1-cus2-ns

  ip netns exec vpp1-cus2-ns \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.2.2/24 dev veth_vpp1_cus2
      ip addr add 6:0:2::2/64 dev veth_vpp1_cus2
      ip route add 6.0.4.0/24 via 6.0.2.1
      ip route add 6:0:4::0/64 via 6:0:2::1
  "

  # customer1 configuration on vpp2
  ip link add veth_vpp2_cus1 type veth peer name vpp2_cus1
  ip link set dev vpp2_cus1 up
  ip link set dev veth_vpp2_cus1 up netns vpp2-cus1-ns

  ip netns exec vpp2-cus1-ns \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.4.4/24 dev veth_vpp2_cus1
      ip addr add 6:0:4::4/64 dev veth_vpp2_cus1
      ip route add 6.0.2.0/24 via 6.0.4.1
      ip route add 6:0:2::0/64 via 6:0:4::1
  "

  # customer2 configuration on vpp2
  ip link add veth_vpp2_cus2 type veth peer name vpp2_cus2
  ip link set dev vpp2_cus2 up
  ip link set dev veth_vpp2_cus2 up netns vpp2-cus2-ns

  ip netns exec vpp2-cus2-ns \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.4.4/24 dev veth_vpp2_cus2
      ip addr add 6:0:4::4/64 dev veth_vpp2_cus2
      ip route add 6.0.2.0/24 via 6.0.4.1
      ip route add 6:0:2::0/64 via 6:0:4::1
  "

  ip addr add 6.0.3.100/24 dev odl
  ip addr add 6:0:3::100/64 dev odl
  ethtool --offload  odl rx off tx off

  ${VPP_LITE_BIN} \
    unix { log /tmp/vpp1.log cli-listen \
           localhost:5002 full-coredump \
           exec ${VPP_LITE_CONF}/vpp1.config } \
    api-trace { on } api-segment { prefix xtr1 }

  ${VPP_LITE_BIN} \
    unix { log /tmp/vpp2.log cli-listen \
           localhost:5003 full-coredump \
           exec ${VPP_LITE_CONF}/vpp2.config } \
    api-trace { on } api-segment { prefix xtr2 }

  post_curl "add-mapping" ${ODL_CONFIG_FILE1}
  post_curl "add-mapping" ${ODL_CONFIG_FILE2}
  post_curl "add-mapping" ${ODL_CONFIG_FILE3}
  post_curl "add-mapping" ${ODL_CONFIG_FILE4}
}
