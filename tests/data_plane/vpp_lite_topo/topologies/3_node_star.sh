#!/usr/bin/env bash

#                                 +--------+
#                                 |        |
#               6.0.10.25         |   MR   |
#            08:55:55:55:55:55    |        |
#                    +            +--------+
#                    |                 |6.0.3.100
# 6:0:1::2           |vpp8             |6:0:3::100
# 6.0.1.2     vpp1 +-+------+          |         +--------+
#        +---------+        |xtr1      |    xtr2 |        |vpp2
#                  |  VPP1  +----------+---------+  VPP2  +---------+
#        +---------+        |          |         |        |      6.0.2.2
# 6.0.5.5     vpp3 +-+------+          |         +-----+--+      6:0:2::2
# 6:0:5::5           |vpp5             |xtr3           |vpp7
#                    |             +--------+          |
#                    +             |        |          + 6.0.10.22
#                6.0.10.21         |  VPP3  |             08:22:22:22:22:22
#            08:11:11:11:11:11     |        |
#                                  +-+----+-+
#                                vpp6|    |vpp4
#                                    |    |
#                                    |    +6.0.2.2
#                                    +     6:0:2::2
#                             6.0.10.22
#                             08:22:22:22:22:22
#


function 3_node_star_topo_clean
{
  echo "Clearing all VPP instances.."
  pkill vpp --signal 9

  rm /dev/shm/*

  echo "Cleaning 3 node star topology..."
  ip netns exec xtr-ns ifconfig vppbr1 down
  ip netns exec xtr-ns brctl delbr vppbr1
  ip link del dev vpp1 &> /dev/null
  ip link del dev vpp2 &> /dev/null
  ip link del dev vpp3 &> /dev/null
  ip link del dev vpp4 &> /dev/null
  ip link del dev vpp5 &> /dev/null
  ip link del dev vpp6 &> /dev/null
  ip link del dev vpp7 &> /dev/null
  ip link del dev vpp8 &> /dev/null
  ip link del dev xtr1 &> /dev/null
  ip link del dev xtr2 &> /dev/null
  ip link del dev xtr3 &> /dev/null
  ip link del dev odl &> /dev/null

  ip netns del vpp-ns1 &> /dev/null
  ip netns del vpp-ns2 &> /dev/null
  ip netns del vpp-ns3 &> /dev/null
  ip netns del vpp-ns4 &> /dev/null
  ip netns del vpp-ns5 &> /dev/null
  ip netns del vpp-ns6 &> /dev/null
  ip netns del vpp-ns7 &> /dev/null
  ip netns del vpp-ns8 &> /dev/null
  ip netns del xtr-ns &> /dev/null

  odl_clear_all
}

function set_arp
{
  odl_mac=`ip a show dev odl | grep "link/ether" | awk '{print $2}'`
  echo "set ip arp host-xtr1 6.0.3.100 $odl_mac" | nc 0 5002
  echo "set ip arp host-xtr2 6.0.3.100 $odl_mac" | nc 0 5003
  echo "set ip arp host-xtr3 6.0.3.100 $odl_mac" | nc 0 5004

  mac1=`ip netns exec vpp-ns5 ip a show dev veth_vpp5  | grep "link/ether" | awk '{print $2}'`
  ip netns exec vpp-ns6 arp -s 6.0.10.21 $mac1

  mac2=`ip netns exec vpp-ns8 ip a show dev veth_vpp8  | grep "link/ether" | awk '{print $2}'`
  ip netns exec vpp-ns7 arp -s 6.0.10.25 $mac2

  mac3=`ip netns exec vpp-ns7 ip a show dev veth_vpp7  | grep "link/ether" | awk '{print $2}'`
  ip netns exec vpp-ns5 arp -s 6.0.10.22 $mac3
  ip netns exec vpp-ns8 arp -s 6.0.10.22 $mac3
}

function 3_node_star_topo_setup
{
  ip netns add vpp-ns1
  ip netns add vpp-ns2
  ip netns add vpp-ns3
  ip netns add vpp-ns4
  ip netns add vpp-ns5
  ip netns add vpp-ns6
  ip netns add vpp-ns7
  ip netns add vpp-ns8
  ip netns add xtr-ns

  ip link add veth_xtr1 type veth peer name xtr1
  ip link add veth_xtr2 type veth peer name xtr2
  ip link add veth_xtr3 type veth peer name xtr3
  ip link add veth_odl type veth peer name odl
  ip link set dev xtr1 up
  ip link set dev xtr2 up
  ip link set dev xtr3 up
  ip link set dev odl up

  ip link set dev veth_xtr1 up netns xtr-ns
  ip link set dev veth_xtr2 up netns xtr-ns
  ip link set dev veth_xtr3 up netns xtr-ns
  ip link set dev veth_odl up netns xtr-ns

  ip netns exec xtr-ns brctl addbr vppbr1
  ip netns exec xtr-ns brctl addif vppbr1 veth_xtr1
  ip netns exec xtr-ns brctl addif vppbr1 veth_xtr2
  ip netns exec xtr-ns brctl addif vppbr1 veth_xtr3
  ip netns exec xtr-ns brctl addif vppbr1 veth_odl
  ip netns exec xtr-ns ifconfig vppbr1 up

  ip link add veth_vpp1 type veth peer name vpp1
  ip link set dev vpp1 up
  ip link set dev veth_vpp1 up netns vpp-ns1

  ip netns exec vpp-ns1 \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.1.2/24 dev veth_vpp1
      ip addr add 6:0:1::2/64 dev veth_vpp1
      ip route add 6.0.2.0/24 via 6.0.1.1
      ip route add 6:0:2::0/64 via 6:0:1::1
  "

  ip link add veth_vpp2 type veth peer name vpp2
  ip link set dev vpp2 up
  ip link set dev veth_vpp2 up netns vpp-ns2

  ip netns exec vpp-ns2 \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.2.2/24 dev veth_vpp2
      ip addr add 6:0:2::2/64 dev veth_vpp2
      ip route add 6.0.1.0/24 via 6.0.2.1
      ip route add 6:0:1::0/64 via 6:0:2::1
  "

  ip link add veth_vpp3 type veth peer name vpp3
  ip link set dev vpp3 up
  ip link set dev veth_vpp3 up netns vpp-ns3

  ip netns exec vpp-ns3 \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.5.5/24 dev veth_vpp3
      ip addr add 6:0:5::5/64 dev veth_vpp3
      ip route add 6.0.2.0/24 via 6.0.5.1
      ip route add 6:0:2::0/64 via 6:0:5::1
  "

  ip link add veth_vpp4 type veth peer name vpp4
  ip link set dev vpp4 up
  ip link set dev veth_vpp4 up netns vpp-ns4

  ip netns exec vpp-ns4 \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.2.2/24 dev veth_vpp4
      ip addr add 6:0:2::2/64 dev veth_vpp4
      ip route add 6.0.5.0/24 via 6.0.2.1
      ip route add 6:0:5::0/64 via 6:0:2::1
  "

  ip link add veth_vpp5 type veth peer name vpp5
  ip link set dev vpp5 up
  ip link set dev veth_vpp5 address 08:11:11:11:11:11
  ip link set dev veth_vpp5 up netns vpp-ns5

  ip netns exec vpp-ns5 \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.10.21/24 dev veth_vpp5
  "

  ip link add veth_vpp6 type veth peer name vpp6
  ip link set dev vpp6 up
  ip link set dev veth_vpp6 address 08:22:22:22:22:22
  ip link set dev veth_vpp6 up netns vpp-ns6

  ip netns exec vpp-ns6 \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.10.22/24 dev veth_vpp6
  "

  ip link add veth_vpp7 type veth peer name vpp7
  ip link set dev vpp7 up
  ip link set dev veth_vpp7 address 08:22:22:22:22:22
  ip link set dev veth_vpp7 up netns vpp-ns7

  ip netns exec vpp-ns7 \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.10.22/24 dev veth_vpp7
  "

  ip link add veth_vpp8 type veth peer name vpp8
  ip link set dev vpp8 up
  ip link set dev veth_vpp8 address 08:55:55:55:55:55
  ip link set dev veth_vpp8 up netns vpp-ns8

  ip netns exec vpp-ns8 \
    bash -c "
      ip link set dev lo up
      ip addr add 6.0.10.25/24 dev veth_vpp8
  "

  ip addr add 6.0.3.100/24 dev odl
  ip addr add 6:0:3::100/64 dev odl
  ethtool --offload  odl rx off tx off
maybe_pause
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

  set_arp
}
