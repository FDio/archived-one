#!/usr/bin/env bash

function multihoming_topo_clean
{
  echo "Clearing all VPP instances.."
  pkill vpp --signal 9
  rm /dev/shm/*

  echo "Cleaning topology.."
  ip netns exec intervppns1 ifconfig vppbr down
  ip netns exec intervppns1 brctl delbr vppbr
  ip link del dev veth_vpp1 &> /dev/null
  ip link del dev veth_vpp2 &> /dev/null
  ip link del dev veth_intervpp11 &> /dev/null
  ip link del dev veth_intervpp12 &> /dev/null
  ip link del dev veth_odl &> /dev/null
  ip netns del vppns1 &> /dev/null
  ip netns del vppns2 &> /dev/null
  ip netns del intervppns1 &> /dev/null

  ip netns exec intervppns2 ifconfig vppbr down
  ip netns exec intervppns2 brctl delbr vppbr
  ip link del dev veth_intervpp21 &> /dev/null
  ip link del dev veth_intervpp22 &> /dev/null
  ip netns del intervppns2 &> /dev/null

  if [ "$1" != "no_odl" ] ; then
    odl_clear_all
  fi
}

function multihoming_topo_setup
{

  # create vpp to clients and inter-vpp namespaces
  ip netns add vppns1
  ip netns add vppns2
  ip netns add intervppns1
  ip netns add intervppns2

  # create vpp and odl interfaces and set them in intervppns1
  ip link add veth_intervpp11 type veth peer name intervpp11
  ip link add veth_intervpp12 type veth peer name intervpp12
  ip link add veth_odl type veth peer name odl
  ip link set dev intervpp11 up
  ip link set dev intervpp12 up
  ip link set dev odl up
  ip link set dev veth_intervpp11 up netns intervppns1
  ip link set dev veth_intervpp12 up netns intervppns1
  ip link set dev veth_odl up netns intervppns1

  ip link add veth_intervpp21 type veth peer name intervpp21
  ip link add veth_intervpp22 type veth peer name intervpp22
  ip link set dev intervpp21 up
  ip link set dev intervpp22 up
  ip link set dev veth_intervpp21 up netns intervppns2
  ip link set dev veth_intervpp22 up netns intervppns2

  # create bridge in intervppns1 and add vpp and odl interfaces
  ip netns exec intervppns1 brctl addbr vppbr
  ip netns exec intervppns1 brctl addif vppbr veth_intervpp11
  ip netns exec intervppns1 brctl addif vppbr veth_intervpp12
  ip netns exec intervppns1 brctl addif vppbr veth_odl
  ip netns exec intervppns1 ifconfig vppbr up

  # create bridge in intervppns2 and add vpp and odl interfaces
  ip netns exec intervppns2 brctl addbr vppbr
  ip netns exec intervppns2 brctl addif vppbr veth_intervpp21
  ip netns exec intervppns2 brctl addif vppbr veth_intervpp22
  ip netns exec intervppns2 brctl addif vppbr veth_odl
  ip netns exec intervppns2 ifconfig vppbr up

  # create and configure 1st veth client to vpp pair
  ip link add veth_vpp1 type veth peer name vpp1
  ip link set dev vpp1 up
  ip link set dev veth_vpp1 up netns vppns1

  # create and configure 2nd veth client to vpp pair
  ip link add veth_vpp2 type veth peer name vpp2
  ip link set dev vpp2 up
  ip link set dev veth_vpp2 up netns vppns2

  ip netns exec vppns1 \
  bash -c "
    ip link set dev lo up
    ip addr add 6.0.1.2/24 dev veth_vpp1
    ip route add 6.0.2.0/24 via 6.0.1.1
    ip addr add 6:0:1::2/64 dev veth_vpp1
    ip route add 6:0:2::0/64 via 6:0:1::1
  "

  ip netns exec vppns2 \
  bash -c "
    ip link set dev lo up
    ip addr add 6.0.2.2/24 dev veth_vpp2
    ip route add 6.0.1.0/24 via 6.0.2.1
    ip addr add 6:0:2::2/64 dev veth_vpp2
    ip route add 6:0:1::0/64 via 6:0:2::1
  "

  # set odl iface ip and disable checksum offloading
  ip addr add 6.0.3.100/24 dev odl
  ip addr add 6:0:3::100/64 dev odl
  ethtool --offload  odl rx off tx off

  # generate config files
  ./scripts/generate_config.py ${VPP_LITE_CONF} ${CFG_METHOD}

  start_vpp 5002 vpp1
  start_vpp 5003 vpp2

  echo "* Selected configuration method: $CFG_METHOD"
  if [ "$CFG_METHOD" == "cli" ] ; then
    echo "exec ${VPP_LITE_CONF}/vpp1.cli" | nc 0 5002
    echo "exec ${VPP_LITE_CONF}/vpp2.cli" | nc 0 5003
  elif [ "$CFG_METHOD" == "vat" ] ; then
    sleep 2
    ${VPP_API_TEST} chroot prefix vpp1 script in ${VPP_LITE_CONF}/vpp1.vat
    ${VPP_API_TEST} chroot prefix vpp2 script in ${VPP_LITE_CONF}/vpp2.vat
  else
    echo "=== WARNING:"
    echo "=== Invalid configuration method selected!"
    echo "=== To resolve this set env variable CFG_METHOD to vat or cli."
    echo "==="
  fi

  if [ "$1" != "no_odl" ] ; then
    post_curl "add-mapping" ${ODL_CONFIG_FILE1}
    post_curl "add-mapping" ${ODL_CONFIG_FILE2}
  fi
}

