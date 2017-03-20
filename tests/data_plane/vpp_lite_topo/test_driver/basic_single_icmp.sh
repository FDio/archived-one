source config.sh
source topologies/2_node_topo.sh

if [ "$1" == "clean" ] ; then
  2_node_topo_clean no_odl
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_single_icmp
{
  2_node_topo_setup no_odl
  maybe_pause
  test_result=1

  # send only one ping request
  ip netns exec vppns1 "${1}" -c 1 "${2}"
  rc=$?

  #                         SEID DEID LLOC RLOC PKTS BYTES
  check_counters "vpp1" "0" $3   $4   $5   $6   $7   $8
  assert_rc_ok $? "2_node_topo_clean no_odl" "Counters do not match!"

  # test done
  maybe_pause
  2_node_topo_clean no_odl
  print_status $rc "No ICMP response!"
  exit $test_result
}
