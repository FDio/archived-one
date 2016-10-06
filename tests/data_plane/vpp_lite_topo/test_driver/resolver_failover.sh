source config.sh
source odl_utils.sh
source topologies/2_node_topo.sh

if [ "$1" == "clean" ] ; then
  basic_two_odls_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_resolver_failover
{
  2_node_topo_setup no_odl

  start_map_resolver "6.0.3.200"

  test_result=1

  maybe_pause

  ip netns exec vppns1 "${1}" -w 20 -c 1 "${2}"
  rc=$?

  # test done
  maybe_pause

  2_node_topo_clean no_odl
  kill $mr_id

  print_status $rc "No ICMP response!"
  exit $test_result
}
