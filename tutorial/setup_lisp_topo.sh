# path to vpp executable and configurations folder
VPP_LITE_BIN=/vpp/build-root/install-vpp_lite_debug-native/vpp/bin/vpp
VPP_LITE_CONF=/etc/vpp/lite/

# make sure there are no vpp instances running
pkill vpp

# delete previous incarnations if they exist
ip netns exec intervppns ifconfig vppbr down
ip netns exec intervppns brctl delbr vppbr
ip link del dev veth_vpp1 &> /dev/null
ip link del dev veth_vpp2 &> /dev/null
ip link del dev veth_intervpp1 &> /dev/null
ip link del dev veth_intervpp2 &> /dev/null
ip link del dev veth_odl &> /dev/null
ip netns del vppns1 &> /dev/null
ip netns del vppns2 &> /dev/null
ip netns del intervppns &> /dev/null

if [ "$1" == "clean" ] ; then
  exit 0;
fi

# create vpp to clients and inter-vpp namespaces
ip netns add vppns1
ip netns add vppns2
ip netns add intervppns

# create vpp and odl interfaces and set them in intervppns
ip link add veth_intervpp1 type veth peer name intervpp1
ip link add veth_intervpp2 type veth peer name intervpp2
ip link add veth_odl type veth peer name odl
ip link set dev intervpp1 up
ip link set dev intervpp2 up
ip link set dev odl up
ip link set dev veth_intervpp1 up netns intervppns
ip link set dev veth_intervpp2 up netns intervppns
ip link set dev veth_odl up netns intervppns

# create bridge in intervppns and add vpp and odl interfaces
ip netns exec intervppns brctl addbr vppbr
ip netns exec intervppns brctl addif vppbr veth_intervpp1
ip netns exec intervppns brctl addif vppbr veth_intervpp2
ip netns exec intervppns brctl addif vppbr veth_odl
ip netns exec intervppns ifconfig vppbr up

# create and configure 1st veth client to vpp pair
ip link add veth_vpp1 type veth peer name vpp1
ip link set dev vpp1 up
ip link set dev veth_vpp1 up netns vppns1

ip netns exec vppns1 \
  bash -c "
    ip link set dev lo up
    ip addr add 6.0.2.2/24 dev veth_vpp1
    ip route add 6.0.4.0/24 via 6.0.2.1
"

# create and configure 2nd veth client to vpp pair
ip link add veth_vpp2 type veth peer name vpp2
ip link set dev vpp2 up
ip link set dev veth_vpp2 up netns vppns2

ip netns exec vppns2 \
  bash -c "
    ip link set dev lo up
    ip addr add 6.0.4.4/24 dev veth_vpp2
    ip route add 6.0.2.0/24 via 6.0.4.1
"

# set odl iface ip and disable checksum offloading
ifconfig odl 6.0.3.100/24
ethtool --offload  odl rx off tx off

# start vpp1 and vpp2 in separate chroot
sudo $VPP_LITE_BIN                              \
  unix { log /tmp/vpp1.log cli-listen           \
         localhost:5002 full-coredump           \
         exec $VPP_LITE_CONF/vpp1.conf }        \
         api-trace { on } chroot {prefix xtr1}

sudo $VPP_LITE_BIN                              \
  unix { log /tmp/vpp2.log cli-listen           \
         localhost:5003 full-coredump           \
         exec $VPP_LITE_CONF/vpp2.conf}         \
         api-trace { on } chroot {prefix xtr2}
