source config.sh
source odl_utils.sh
source topologies/basic_topo.sh

if [ "$1" == "clean" ] ; then
  basic_topo_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_basic_no_odl
{
  basic_topo_setup no_odl

  if [ "$3" == "wait" ] ; then
    read -p  "press any key to continue .." -n1
  fi

  test_result=1

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  if [ $? -ne 0 ] ; then
    echo "No response received!"
    basic_topo_clean no_odl
    exit $test_result
  fi

  # change IP addresses of destination RLOC
  echo "set int ip address del host-intervpp2 6.0.3.2/24" | nc 0 5003
  echo "set int ip address host-intervpp2 6.0.3.20/24" | nc 0 5003
  echo "set int ip address del host-intervpp2 6:0:3::2/24" | nc 0 5003
  echo "set int ip address host-intervpp2 6:0:3::20/24" | nc 0 5003

  echo "lisp remote-mapping del vni 0 deid 6.0.2.0/24 seid 6.0.1.0/24 rloc 6.0.3.2" | nc 0 5002
  echo "lisp remote-mapping add vni 0 deid 6.0.2.0/24 seid 6.0.1.0/24 rloc 6.0.3.20" | nc 0 5002

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  rc=$?

  if [ "$3" == "wait" ] ; then
    read -p  "press any key to continue .." -n1
  fi

  # test done

  basic_topo_clean no_odl
  if [ $rc -ne 0 ] ; then
    echo "Test failed: No ICMP response received within specified timeout limit!"
  else
    echo "Test passed."
    test_result=0
  fi

  exit $test_result
}

