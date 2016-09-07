source config.sh
source odl_utils.sh
source topologies/multihoming_topo.sh

ODL_CONFIG_FILE1="vpp1.json"
ODL_CONFIG_FILE2="vpp2.json"
ODL_CONFIG_FILE3="update_vpp2.json"

if [ "$1" == "clean" ] ; then
  multihoming_topo_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_multihoming
{
  if [ "$3" != "no_setup" ] ; then
    multihoming_topo_setup
  fi

  maybe_pause

  test_result=1

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  assert_rc_ok $? multihoming_topo_clean "No response received!"

  # do some port sweeping to see that load balancing works
  ip netns exec vppns1 nc -n -z "${2}" 1-1000 > /dev/null 2>&1

  # check that it works
  pkts=$(echo "show int" | nc 0 5002 | grep host-intervpp11 | awk '{print $6}' | tr -d '\r')

  if [ $pkts -gt 450 ] && [ $pkts -lt 550 ] ; then
    rc=0
  else
    rc=1
  fi

  if [ $rc -ne 0 ] ; then
    echo "Load balancing doesn't work!"

    maybe_pause

    multihoming_topo_clean
    exit $test_result
  fi

  maybe_pause

  # change IP addresses of destination RLOC
  echo "set int ip address del host-intervpp12 6.0.3.2/24" | nc 0 5003
  echo "set int ip address host-intervpp12 6.0.3.20/24" | nc 0 5003
  echo "set int ip address del host-intervpp12 6:0:3::2/64" | nc 0 5003
  echo "set int ip address host-intervpp12 6:0:3::20/64" | nc 0 5003
  post_curl "update-mapping" ${ODL_CONFIG_FILE3}

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  rc=$?

  # test done

  maybe_pause

  multihoming_topo_clean
  print_status $rc "No ICMP response!"
  exit $test_result
}
