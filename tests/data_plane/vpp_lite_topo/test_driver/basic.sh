source config.sh
source odl_utils.sh
source topologies/2_node_topo.sh

ODL_CONFIG_FILE1="vpp1.json"
ODL_CONFIG_FILE2="vpp2.json"
ODL_CONFIG_FILE3="update_vpp2.json"

if [ "$1" == "clean" ] ; then
  2_node_topo_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_basic
{
  if [ "$3" != "no_setup" ] ; then
    2_node_topo_setup
  fi

  maybe_pause
  test_result=1

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  assert_rc_ok $? 2_node_topo_clean "No ICMP response!"

  maybe_pause
  # change IP addresses of destination RLOC
  echo "set int ip address del host-intervpp2 6.0.3.2/24" | nc 0 5003
  echo "set int ip address host-intervpp2 6.0.3.20/24" | nc 0 5003
  echo "set int ip address del host-intervpp2 6:0:3::2/64" | nc 0 5003
  echo "set int ip address host-intervpp2 6:0:3::20/64" | nc 0 5003
  post_curl "update-mapping" ${ODL_CONFIG_FILE3}

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  rc=$?

  # test done

  maybe_pause
  2_node_topo_clean
  print_status $rc "No ICMP response!"
  exit $test_result
}
