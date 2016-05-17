#!/usr/bin/env bash

if [ "$1" == "-h" ] || [ "$1" == "-help" ] ; then
  echo "lisp_test.sh [ip4] [ip6] [ip4_ip6] [4o6] [6o4] [remote] [remote6]"
  echo "        ip4 - test ip4 topology"
  echo "        ip6 - test ip6 topology"
  echo "        ip4_ip6 - test ip4 and ip6 topology"
  echo "        4o6 - test ip4 over ip6"
  echo "        6o4 - test ip6 over ip4"
  echo "        remote - test statick mapping, whit out ODL"
  echo "        remote6 - test statick mapping for IPv6, whit out ODL"
  exit 0
fi

set -x

# path to vpp executable and configurations folder
# VPP_LITE_BIN=/vpp/build-root/install-vpp_lite_debug-native/vpp/bin/vpp
VPP_LITE_BIN=/home/csit/lisp_vpp/build-root/install-vpp_lite_debug-native/vpp/bin/vpp
VPP_LITE_CONF=`pwd`"/../configs/vpp_lite_config/"
VPP1_CONF="vpp1.conf"
VPP2_CONF="vpp2.conf"
ODL_CONFIG_DIR="../configs/odl/"
ODL_ADD_CONFIG1="add_ipv4_odl1.txt"
ODL_ADD_CONFIG1_4o6="add_ipv4o6_odl1.txt"
ODL_ADD_CONFIG1_6="add_ipv6_odl1.txt"
ODL_ADD_CONFIG1_6o4="add_ipv6o4_odl1.txt"
ODL_ADD_CONFIG2="add_ipv4_odl2.txt"
ODL_ADD_CONFIG2_4o6="add_ipv4o6_odl2.txt"
ODL_ADD_CONFIG2_6="add_ipv6_odl2.txt"
ODL_ADD_CONFIG2_6o4="add_ipv6o4_odl2.txt"
ODL_REPLACE_CONFIG2="replace_ipv4_odl2.txt"
ODL_REPLACE_CONFIG2_4o6="replace_ipv4o6_odl2.txt"
ODL_REPLACE_CONFIG2_6="replace_ipv6_odl2.txt"
ODL_REPLACE_CONFIG2_6o4="replace_ipv6o4_odl2.txt"

ODL_USER="admin"
ODL_PASSWD="admin"
ODL_IP="127.0.0.1"
ODL_PORT="8181"

function post_curl {
  curl -X POST http://${ODL_IP}:${ODL_PORT}/restconf/operations/odl-mappingservice:${1} \
     -H "Content-Type: application/json" --data-binary "@${ODL_CONFIG_DIR}${2}" \
     -u ${ODL_USER}:${ODL_PASSWD}
}

# make sure there are no vpp instances running
sudo pkill vpp

# delete previous incarnations if they exist
sudo ip netns exec intervppns ifconfig vppbr down
sudo ip netns exec intervppns brctl delbr vppbr
sudo ip link del dev veth_vpp1 &> /dev/null
sudo ip link del dev veth_vpp2 &> /dev/null
sudo ip link del dev veth_intervpp1 &> /dev/null
sudo ip link del dev veth_intervpp2 &> /dev/null
sudo ip link del dev veth_odl &> /dev/null
sudo ip netns del vppns1 &> /dev/null
sudo ip netns del vppns2 &> /dev/null
sudo ip netns del intervppns &> /dev/null

if [ "$1" != "remote" ] && [ "$1" != "remote6" ]  ; then
  curl -X DELETE http://${ODL_IP}:${ODL_PORT}/restconf/config/odl-mappingservice:mapping-database/ \
       -u ${ODL_USER}:${ODL_PASSWD}
fi

if [ "$1" == "clean" ] ; then
  exit 0;
fi

# create vpp to clients and inter-vpp namespaces
sudo ip netns add vppns1
sudo ip netns add vppns2
sudo ip netns add intervppns

# create vpp and odl interfaces and set them in intervppns
sudo ip link add veth_intervpp1 type veth peer name intervpp1
sudo ip link add veth_intervpp2 type veth peer name intervpp2
sudo ip link add veth_odl type veth peer name odl
sudo ip link set dev intervpp1 up
sudo ip link set dev intervpp2 up
sudo ip link set dev odl up
sudo ip link set dev veth_intervpp1 up netns intervppns
sudo ip link set dev veth_intervpp2 up netns intervppns
sudo ip link set dev veth_odl up netns intervppns

# create bridge in intervppns and add vpp and odl interfaces
sudo ip netns exec intervppns brctl addbr vppbr
sudo ip netns exec intervppns brctl addif vppbr veth_intervpp1
sudo ip netns exec intervppns brctl addif vppbr veth_intervpp2
sudo ip netns exec intervppns brctl addif vppbr veth_odl
sudo ip netns exec intervppns ifconfig vppbr up

# create and configure 1st veth client to vpp pair
sudo ip link add veth_vpp1 type veth peer name vpp1
sudo ip link set dev vpp1 up
sudo ip link set dev veth_vpp1 up netns vppns1

# create and configure 2nd veth client to vpp pair
sudo ip link add veth_vpp2 type veth peer name vpp2
sudo ip link set dev vpp2 up
sudo ip link set dev veth_vpp2 up netns vppns2

# set odl iface ip and disable checksum offloading
sudo ip addr add 6.0.3.100/24 dev odl
sudo ip addr add 6:0:3::100/64 dev odl
sudo ethtool --offload  odl rx off tx off

if [ "$1" == "ip6" ] ; then
  VPP1_CONF="vpp1_6.conf"
  VPP2_CONF="vpp2_6.conf"
fi

if [ "$1" == "ip4_ip6" ] ; then
  VPP1_CONF="vpp1_ip4_6.conf"
  VPP2_CONF="vpp2_ip4_6.conf"
fi

if [ "$1" == "4o6" ] ; then
  VPP1_CONF="vpp1_4o6.conf"
  VPP2_CONF="vpp2_4o6.conf"
fi

if [ "$1" == "6o4" ] ; then
  VPP1_CONF="vpp1_6o4.conf"
  VPP2_CONF="vpp2_6o4.conf"
fi

if [ "$1" == "remote" ] ; then
  VPP1_CONF="vpp1_remote.conf"
  VPP2_CONF="vpp2_remote.conf"
fi

if [ "$1" == "remote6" ] ; then
  VPP1_CONF="vpp1_6_remote.conf"
  VPP2_CONF="vpp2_6_remote.conf"
fi

# start vpp1 and vpp2 in separate chroot
sudo $VPP_LITE_BIN                              \
  unix { log /tmp/vpp1.log cli-listen           \
         localhost:5002 full-coredump           \
         exec $VPP_LITE_CONF/${VPP1_CONF} }     \
         api-trace { on } chroot {prefix xtr1}

sudo $VPP_LITE_BIN                              \
  unix { log /tmp/vpp2.log cli-listen           \
         localhost:5003 full-coredump           \
         exec $VPP_LITE_CONF/${VPP2_CONF}}      \
         api-trace { on } chroot {prefix xtr2}


if [ "$#" == 0 ] || [ "$1" == "ip4" ] ; then
  source lisp_ip4.sh
fi

if [ "$1" == "ip6" ] ; then
  source lisp_ip6.sh
fi

if [ "$1" == "ip4_ip6" ] ; then
  source lisp_ip4.sh
  source lisp_ip6.sh

  ping_lisp
  ping_lisp6
fi

if [ "$1" == "4o6" ] ; then
  source lisp_ip4o6.sh
fi

if [ "$1" == "6o4" ] ; then
  source lisp_ip6o4.sh
fi

if [ "$1" == "remote" ] ; then
  source lisp_remote_mapping.sh
fi

if [ "$1" == "remote6" ] ; then
  source lisp_6_remote_mapping.sh
fi

echo "Success"
