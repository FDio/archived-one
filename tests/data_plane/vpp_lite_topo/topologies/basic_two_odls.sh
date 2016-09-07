
#!/usr/bin/env bash

function basic_two_odls_clean
{
  echo "Clearing all VPP instances.."
  pkill vpp --signal 9
  rm /dev/shm/*

  echo "Cleaning topology.."
  ip netns exec intervppns ifconfig vppbr down
  ip netns exec intervppns brctl delbr vppbr
  ip link del dev veth_vpp1 &> /dev/null
  ip link del dev veth_vpp2 &> /dev/null
  ip link del dev veth_intervpp1 &> /dev/null
  ip link del dev veth_intervpp2 &> /dev/null
  ip link del dev veth_odl1 &> /dev/null
  ip link del dev veth_odl2 &> /dev/null
  ip netns del vppns1 &> /dev/null
  ip netns del vppns2 &> /dev/null
  ip netns del intervppns &> /dev/null
}

function basic_two_odls_setup
{

  # create vpp to clients and inter-vpp namespaces
  ip netns add vppns1
  ip netns add vppns2
  ip netns add intervppns

  # create vpp and odl interfaces and set them in intervppns
  ip link add veth_intervpp1 type veth peer name intervpp1
  ip link add veth_intervpp2 type veth peer name intervpp2
  ip link add veth_odl1 type veth peer name odl1
  ip link add veth_odl2 type veth peer name odl2
  ip link set dev intervpp1 up
  ip link set dev intervpp2 up
  ip link set dev odl1 up
  ip link set dev odl2 up
  ip link set dev veth_intervpp1 up netns intervppns
  ip link set dev veth_intervpp2 up netns intervppns
  ip link set dev veth_odl1 up netns intervppns
  ip link set dev veth_odl2 up netns intervppns

  # create bridge in intervppns and add vpp and odl interfaces
  ip netns exec intervppns brctl addbr vppbr
  ip netns exec intervppns brctl addif vppbr veth_intervpp1
  ip netns exec intervppns brctl addif vppbr veth_intervpp2
  ip netns exec intervppns brctl addif vppbr veth_odl1
  ip netns exec intervppns brctl addif vppbr veth_odl2
  ip netns exec intervppns ifconfig vppbr up

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
  "

  ip netns exec vppns2 \
  bash -c "
    ip link set dev lo up
    ip addr add 6.0.2.2/24 dev veth_vpp2
    ip route add 6.0.1.0/24 via 6.0.2.1
  "

  # set odl iface ip and disable checksum offloading
  ip addr add 6.0.3.100/24 dev odl1
  ethtool --offload  odl1 rx off tx off

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
}
