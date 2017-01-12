source config.sh
source odl_utils.sh
source topologies/2_node_topo.sh

if [ "$1" == "clean" ] ; then
  2_node_topo_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_basic_no_odl
{
  2_node_topo_setup no_odl

  maybe_pause

  test_result=1

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  if [ $? -ne 0 ] ; then
    echo "No response received!"
    2_node_topo_clean no_odl
    exit $test_result
  fi

  # change IP addresses of destination RLOC
  echo "set int ip address del host-intervpp2 6.0.3.2/24" | nc 0 5003
  echo "set int ip address host-intervpp2 6.0.3.20/24" | nc 0 5003
  echo "set int ip address del host-intervpp2 6:0:3::2/64" | nc 0 5003
  echo "set int ip address host-intervpp2 6:0:3::20/64" | nc 0 5003

  if [ ${3} == "switch_rlocs" ] ; then
    echo "lisp remote-mapping del vni 0 eid 6.0.2.0/24" | nc 0 5002
    echo "lisp remote-mapping add vni 0 eid 6.0.2.0/24 rloc 6:0:3::20" | nc 0 5002
    echo "lisp remote-mapping del vni 0 eid 6:0:2::0/64" | nc 0 5002
    echo "lisp remote-mapping add vni 0 eid 6:0:2::0/64 rloc 6.0.3.20" | nc 0 5002
  else
    echo "lisp remote-mapping del vni 0 eid 6.0.2.0/24 rloc 6.0.3.2" | nc 0 5002
    echo "lisp remote-mapping add vni 0 eid 6.0.2.0/24 rloc 6.0.3.20" | nc 0 5002
    echo "lisp remote-mapping del vni 0 eid 6:0:2::0/64 rloc 6:0:3::2" | nc 0 5002
    echo "lisp remote-mapping add vni 0 eid 6:0:2::0/64 rloc 6:0:3::20" | nc 0 5002
  fi

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  rc=$?

  maybe_pause

  # test done

  2_node_topo_clean no_odl
  if [ $rc -ne 0 ] ; then
    echo "Test failed: No ICMP response received within specified timeout limit!"
  else
    echo "Test passed."
    test_result=0
  fi

  exit $test_result
}

