source config.sh
source odl_utils.sh
source topologies/2_node_topo.sh

if [ "$1" == "clean" ] ; then
  2_node_topo_clean no_odl
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as root."
  exit 1
fi

function start_dhcp_server
{
  echo "starting DHCP server from namespace $1"
  ip netns exec "$1" python scripts/dhcp_server.py &
  dhcp_id=$!
}

function send_dhcp_discovery
{
  src_mac="`sudo ip netns exec vppns1 ifconfig veth_vpp1 | grep HWaddr | awk '{print $5}'`"
  ip netns exec "$1" python scripts/dhcp_client.py "$src_mac" "$2"
  rc=$?
}

function test_dhcp
{
  2_node_topo_setup no_odl
  test_result=1

  # dhcp proxy1 config
  echo "set dhcp proxy server 6.0.2.2 src-address 6.0.1.1" | nc 0 5002

  maybe_pause

  # run DHCP server from namespace
  start_dhcp_server vppns2

  # send DHCP discovery from namespace and check if reply (= DHCP offer)
  # comes from the proxy DHCP address
  send_dhcp_discovery vppns1 "6.0.1.1"

  maybe_pause
  2_node_topo_clean no_odl
  kill $dhcp_id

  print_status $rc "DHCP test failed!"
  exit $test_result
}

