#!/usr/bin/env bash

function rtr_single_iface_clean {
  echo "Clearing all VPP instances.."
  pkill vpp --signal 9

  rm /dev/shm/*

  echo "Cleaning RTR topology.."
  ip netns exec xtr-rtr-ns ifconfig vppbr1 down
  ip netns exec xtr-rtr-ns brctl delbr vppbr1
  ip link del dev vpp1 &> /dev/null
  ip link del dev vpp2 &> /dev/null
  ip link del dev xtr_rtr1 &> /dev/null
  ip link del dev xtr_rtr2 &> /dev/null
  ip link del dev xtr_rtr3 &> /dev/null
  ip link del dev odl &> /dev/null

  ip netns del vpp-ns1 &> /dev/null
  ip netns del vpp-ns2 &> /dev/null
  ip netns del xtr-rtr-ns &> /dev/null

  odl_clear_all
}

function rtr_single_iface_setup {
  ip netns add vpp-ns1
  ip netns add vpp-ns2
  ip netns add xtr-rtr-ns

  ip link add veth_xtr_rtr1 type veth peer name xtr_rtr1
  ip link add veth_xtr_rtr2 type veth peer name xtr_rtr2
  ip link add veth_xtr_rtr3 type veth peer name xtr_rtr3
  ip link add veth_odl type veth peer name odl
  ip link set dev xtr_rtr1 up
  ip link set dev xtr_rtr2 up
  ip link set dev xtr_rtr3 up
  ip link set dev odl up

  ip link set dev veth_xtr_rtr1 up netns xtr-rtr-ns
  ip link set dev veth_xtr_rtr2 up netns xtr-rtr-ns
  ip link set dev veth_xtr_rtr3 up netns xtr-rtr-ns
  ip link set dev veth_odl up netns xtr-rtr-ns

  ip netns exec xtr-rtr-ns brctl addbr vppbr1
  ip netns exec xtr-rtr-ns brctl addif vppbr1 veth_xtr_rtr1
  ip netns exec xtr-rtr-ns brctl addif vppbr1 veth_xtr_rtr2
  ip netns exec xtr-rtr-ns brctl addif vppbr1 veth_xtr_rtr3
  ip netns exec xtr-rtr-ns brctl addif vppbr1 veth_odl
  ip netns exec xtr-rtr-ns ifconfig vppbr1 up

  ip link add veth_vpp1 type veth peer name vpp1
  ip link set dev vpp1 up
  ip link set dev veth_vpp1 up netns vpp-ns1

  ip netns exec vpp-ns1 \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.2.2/24 dev veth_vpp1
      ip addr add 6:0:2::2/64 dev veth_vpp1
      ip route add 6.0.4.0/24 via 6.0.2.1
      ip route add 6:0:4::0/64 via 6:0:2::1
  "

  ip link add veth_vpp2 type veth peer name vpp2
  ip link set dev vpp2 up
  ip link set dev veth_vpp2 up netns vpp-ns2

  ip netns exec vpp-ns2 \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.4.4/24 dev veth_vpp2
      ip addr add 6:0:4::4/64 dev veth_vpp2
      ip route add 6.0.2.0/24 via 6.0.4.1
      ip route add 6:0:2::0/64 via 6:0:4::1
  "

  ip addr add 6.0.3.100/24 dev odl
  ip addr add 6:0:3::100/64 dev odl
  ethtool --offload  odl rx off tx off

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
