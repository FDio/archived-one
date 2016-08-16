ODL_USER="admin"
ODL_PASSWD="admin"
ODL_IP="127.0.0.1"
ODL_PORT="8181"

# path to vpp executable
VPP_LITE_BIN=/vpp/build-root/install-vpp_lite_debug-native/vpp/bin/vpp

# read user config file if exists
if [ -f "${HOME}/.onerc" ] ; then
  source "${HOME}/.onerc"
fi

if [ ! -f "${VPP_LITE_BIN}" ] ; then
  echo "Error: VPP binary not found. You can set VPP_LITE_BIN in config.sh"
  echo "Current value:"
  echo "VPP_LITE_BIN=${VPP_LITE_BIN}"
  exit 1
fi

function clean_all
{
  echo "Clearing all VPP instances.."
  pkill vpp --signal 9
  rm /dev/shm/* &> /dev/null

  echo "Cleaning topology.."
  ip netns exec intervppns ifconfig vppbr down &> /dev/null
  ip netns exec intervppns brctl delbr vppbr &> /dev/null
  ip netns exec intervppns1 ifconfig vppbr down &> /dev/null
  ip netns exec intervppns1 brctl delbr vppbr &> /dev/null
  ip netns exec intervppns2 ifconfig vppbr down &> /dev/null
  ip netns exec intervppns2 brctl delbr vppbr &> /dev/null
  ip netns exec intervpp-ns ifconfig vppbr1 down &> /dev/null
  ip netns exec intervpp-ns brctl delbr vppbr1 &> /dev/null
  ip netns exec xtr-rtr-ns ifconfig vppbr1 down &> /dev/null
  ip netns exec xtr-rtr-ns brctl delbr vppbr1 &> /dev/null

  ip link del dev veth_vpp1 &> /dev/null
  ip link del dev veth_vpp2 &> /dev/null
  ip link del dev vpp1_cus1 &> /dev/null
  ip link del dev vpp2_cus1 &> /dev/null
  ip link del dev vpp1_cus2 &> /dev/null
  ip link del dev vpp2_cus2 &> /dev/null
  ip link del dev vpp1 &> /dev/null
  ip link del dev vpp2 &> /dev/null

  ip link del dev veth_intervpp1 &> /dev/null
  ip link del dev veth_intervpp2 &> /dev/null
  ip link del dev veth_intervpp11 &> /dev/null
  ip link del dev veth_intervpp12 &> /dev/null
  ip link del dev veth_intervpp21 &> /dev/null
  ip link del dev veth_intervpp22 &> /dev/null
  ip link del dev intervpp1 &> /dev/null
  ip link del dev intervpp2 &> /dev/null
  ip link del dev xtr_rtr1 &> /dev/null
  ip link del dev xtr_rtr2 &> /dev/null
  ip link del dev xtr_rtr3 &> /dev/null

  ip link del dev veth_odl &> /dev/null
  ip link del dev odl &> /dev/null

  ip netns del vppns1 &> /dev/null
  ip netns del vppns2 &> /dev/null
  ip netns del intervppns &> /dev/null
  ip netns del intervppns1 &> /dev/null
  ip netns del intervppns2 &> /dev/null
  ip netns del vpp1-cus1-ns &> /dev/null
  ip netns del vpp1-cus2-ns &> /dev/null
  ip netns del vpp2-cus1-ns &> /dev/null
  ip netns del vpp2-cus2-ns &> /dev/null
  ip netns del intervpp-ns &> /dev/null
  ip netns del vpp-ns1 &> /dev/null
  ip netns del vpp-ns2 &> /dev/null
  ip netns del xtr-rtr-ns &> /dev/null

  if [ "$1" != "no_odl" ] ; then
    odl_clear_all
  fi


}
