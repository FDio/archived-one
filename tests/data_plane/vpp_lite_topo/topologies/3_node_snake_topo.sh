
function 3_node_snake_topo_clean
{
  echo "Clearing all VPP instances.."
  pkill vpp --signal 9
  rm /dev/shm/*

  echo "Cleaning topology.."
  ip netns exec xtr-ns12 ifconfig br12 down
  ip netns exec xtr-ns23 ifconfig br23 down

  ip netns exec xtr-ns12 brctl delbr br12
  ip netns exec xtr-ns23 brctl delbr br23

  ip link del dev veth_vpp1 &> /dev/null
  ip link del dev veth_vpp2 &> /dev/null
  ip link del dev veth_xtr1_xtr2 &> /dev/null
  ip link del dev veth_xtr2_xtr1 &> /dev/null
  ip link del dev veth_xtr2_xtr3 &> /dev/null
  ip link del dev veth_xtr3_xtr2 &> /dev/null

  ip netns del vppns1 &> /dev/null
  ip netns del vppns2 &> /dev/null
  ip netns del xtr-ns12 &> /dev/null
  ip netns del xtr-ns23 &> /dev/null
}

function 3_node_snake_topo_setup
{
  ip netns add vppns1
  ip netns add vppns2
  ip netns add xtr-ns12
  ip netns add xtr-ns23

  ip link add veth_xtr1_xtr2 type veth peer name xtr1_xtr2
  ip link add veth_xtr2_xtr1 type veth peer name xtr2_xtr1
  ip link add veth_xtr2_xtr3 type veth peer name xtr2_xtr3
  ip link add veth_xtr3_xtr2 type veth peer name xtr3_xtr2

  # enable peer interfaces
  ip link set dev xtr1_xtr2 up
  ip link set dev xtr2_xtr1 up
  ip link set dev xtr2_xtr3 up
  ip link set dev xtr3_xtr2 up

  ip link set dev veth_xtr1_xtr2 up netns xtr-ns12
  ip link set dev veth_xtr2_xtr1 up netns xtr-ns12
  ip link set dev veth_xtr2_xtr3 up netns xtr-ns23
  ip link set dev veth_xtr3_xtr2 up netns xtr-ns23

  ip netns exec xtr-ns12 brctl addbr br12
  ip netns exec xtr-ns23 brctl addbr br23

  ip netns exec xtr-ns12 brctl addif br12 veth_xtr1_xtr2
  ip netns exec xtr-ns12 brctl addif br12 veth_xtr2_xtr1
  ip netns exec xtr-ns12 ifconfig br12 up
  ip netns exec xtr-ns23 brctl addif br23 veth_xtr2_xtr3
  ip netns exec xtr-ns23 brctl addif br23 veth_xtr3_xtr2
  ip netns exec xtr-ns23 ifconfig br23 up

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

  # generate config files
  ./scripts/generate_config.py ${VPP_LITE_CONF} ${CFG_METHOD}

  start_vpp 5002 vpp1
  start_vpp 5003 vpp2
  start_vpp 5004 vpp3

  sleep 2
  echo "* Selected configuration method: $CFG_METHOD"
  if [ "$CFG_METHOD" == "cli" ] ; then
    echo "exec ${VPP_LITE_CONF}/vpp1.cli" | nc 0 5002
    echo "exec ${VPP_LITE_CONF}/vpp2.cli" | nc 0 5003
    echo "exec ${VPP_LITE_CONF}/vpp3.cli" | nc 0 5004
  elif [ "$CFG_METHOD" == "vat" ] ; then
    ${VPP_API_TEST} chroot prefix vpp1 script in ${VPP_LITE_CONF}/vpp1.vat
    ${VPP_API_TEST} chroot prefix vpp2 script in ${VPP_LITE_CONF}/vpp2.vat
    ${VPP_API_TEST} chroot prefix vpp3 script in ${VPP_LITE_CONF}/vpp3.vat
  else
    echo "=== WARNING:"
    echo "=== Invalid configuration method selected!"
    echo "=== To resolve this set env variable CFG_METHOD to vat or cli."
    echo "==="
  fi
}
