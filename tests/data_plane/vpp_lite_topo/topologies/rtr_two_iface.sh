#!/usr/bin/env bash

function rtr_two_iface_clean {
  echo "Clearing all VPP instances.."
  pkill vpp --signal 9

  rm /dev/shm/*

  echo "Cleaning RTR topology.."
  ip netns exec vpp1-rtr-ns ifconfig vppbr1 down
  ip netns exec vpp1-rtr-ns brctl delbr vppbr1
  ip netns exec vpp2-rtr-ns ifconfig vppbr2 down
  ip netns exec vpp2-rtr-ns brctl delbr vppbr2
  ip link del dev vpp1 &> /dev/null
  ip link del dev vpp2 &> /dev/null
  ip link del dev vpp1_rtr &> /dev/null
  ip link del dev rtr1_vpp1 &> /dev/null
  ip link del dev vpp2_rtr &> /dev/null
  ip link del dev rtr_vpp2 &> /dev/null
  ip link del dev odl_vpp1 &> /dev/null
  ip link del dev odl_vpp2 &> /dev/null

  ip netns del vpp1-ns &> /dev/null
  ip netns del vpp2-ns &> /dev/null
  ip netns del vpp1-rtr-ns &> /dev/null
  ip netns del vpp2-rtr-ns &> /dev/null

  odl_clear_all
}

function rtr_two_iface_setup {
  # create namespaces
  ip netns add vpp1-ns
  ip netns add vpp2-ns
  ip netns add vpp1-rtr-ns
  ip netns add vpp2-rtr-ns

  # create pair interfaces between vpp[1|2], rtr and odl
  ip link add veth_vpp1_rtr type veth peer name vpp1_rtr
  ip link add veth_rtr_vpp1 type veth peer name rtr_vpp1
  ip link add veth_vpp2_rtr type veth peer name vpp2_rtr
  ip link add veth_rtr_vpp2 type veth peer name rtr_vpp2
  ip link add veth_odl_vpp1 type veth peer name odl_vpp1
  ip link add veth_odl_vpp2 type veth peer name odl_vpp2

  # enable peer interfaces
  ip link set dev vpp1_rtr up
  ip link set dev rtr_vpp1 up
  ip link set dev vpp2_rtr up
  ip link set dev rtr_vpp2 up
  ip link set dev odl_vpp1 up
  ip link set dev odl_vpp2 up

  # enable veth interfaces and set them in the appropriate ip ns
  ip link set dev veth_vpp1_rtr up netns vpp1-rtr-ns
  ip link set dev veth_rtr_vpp1 up netns vpp1-rtr-ns
  ip link set dev veth_vpp2_rtr up netns vpp2-rtr-ns
  ip link set dev veth_rtr_vpp2 up netns vpp2-rtr-ns
  ip link set dev veth_odl_vpp1 up netns vpp1-rtr-ns
  ip link set dev veth_odl_vpp2 up netns vpp2-rtr-ns

  # vpp1, rtr and odl
  ip netns exec vpp1-rtr-ns brctl addbr vppbr1
  ip netns exec vpp1-rtr-ns brctl addif vppbr1 veth_vpp1_rtr
  ip netns exec vpp1-rtr-ns brctl addif vppbr1 veth_rtr_vpp1
  ip netns exec vpp1-rtr-ns brctl addif vppbr1 veth_odl_vpp1
  ip netns exec vpp1-rtr-ns ifconfig vppbr1 up

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
  ip addr add 6.0.3.100/24 dev odl_vpp1
  ip addr add 6:0:3::100/64 dev odl_vpp1
  ethtool --offload  odl_vpp1 rx off tx off

  # vpp2 to odl
  ip addr add 6.0.5.100/24 dev odl_vpp2
  ip addr add 6:0:5::100/64 dev odl_vpp2
  ethtool --offload  odl_vpp2 rx off tx off

  # generate config files
  ./scripts/generate_config.py ${VPP_LITE_CONF} ${CFG_METHOD}

  start_vpp 5002 vpp1
  start_vpp 5003 vpp2
  start_vpp 5004 vpp3

  echo "* Selected configuration method: $CFG_METHOD"
  if [ "$CFG_METHOD" == "cli" ] ; then
    echo "exec ${VPP_LITE_CONF}/vpp1.cli" | nc 0 5002
    echo "exec ${VPP_LITE_CONF}/vpp2.cli" | nc 0 5003
    echo "exec ${VPP_LITE_CONF}/vpp3.cli" | nc 0 5004
  elif [ "$CFG_METHOD" == "vat" ] ; then
    sleep 2
    ${VPP_API_TEST} chroot prefix vpp1 script in ${VPP_LITE_CONF}/vpp1.vat
    ${VPP_API_TEST} chroot prefix vpp2 script in ${VPP_LITE_CONF}/vpp2.vat
    ${VPP_API_TEST} chroot prefix vpp3 script in ${VPP_LITE_CONF}/vpp3.vat
  else
    echo "=== WARNING:"
    echo "=== Invalid configuration method selected!"
    echo "=== To resolve this set env variable CFG_METHOD to vat or cli."
    echo "==="
  fi
  post_curl "add-mapping" ${ODL_CONFIG_FILE1}
  post_curl "add-mapping" ${ODL_CONFIG_FILE2}
}
