source config.sh
source odl_utils.sh
source topologies/3_node_star.sh

if [ "$1" == "clean" ] ; then
  3_node_star_topo_clean no_odl
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as root."
  exit 1
fi

function send_icmp_from_namespace
{
  ip netns exec "$1" "$2" -w 15 -c 1 "$3"
}

function test_arp_resolution
{
  3_node_star_topo_setup no_odl no_arp

  maybe_pause
  send_icmp_from_namespace vpp-ns5 "$1" "$2"
  rc=$?

  maybe_pause
  3_node_star_topo_clean no_odl
  print_status $rc "No ICMP response!"
  exit $test_result
}
