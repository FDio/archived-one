source config.sh
source odl_utils.sh
source topologies/basic_topo.sh

ODL_CONFIG_FILE1="vpp1.json"
ODL_CONFIG_FILE2="vpp2.json"
ODL_CONFIG_FILE3="update_vpp2.json"

if [ "$1" == "clean" ] ; then
  basic_topo_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_basic
{
  if [ "$3" != "no_setup" ] ; then
    basic_topo_setup
  fi

  if [ "$3" == "wait" ] ; then
    read -p  "press any key to continue .." -n1
  fi

  test_result=1

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  rc=$?
  if [ $rc -ne 0 ] ; then
    echo "No response received!"
    basic_topo_clean
    exit $test_result
  fi

  if [ "$3" == "wait" ] ; then
    read -p  "press any key to continue .." -n1
  fi

  # change IP addresses of destination RLOC
  echo "set int ip address del host-intervpp2 6.0.3.2/24" | nc 0 5003
  echo "set int ip address host-intervpp2 6.0.3.20/24" | nc 0 5003
  echo "set int ip address del host-intervpp2 6:0:3::2/24" | nc 0 5003
  echo "set int ip address host-intervpp2 6:0:3::20/24" | nc 0 5003
  post_curl "update-mapping" ${ODL_CONFIG_FILE3}

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  rc=$?

  # test done

  if [ "$3" == "wait" ] ; then
    read -p  "press any key to continue .." -n1
  fi

  basic_topo_clean
  if [ $rc -ne 0 ] ; then
    echo "Test failed: No ICMP response received within specified timeout limit!"
  else
    echo "Test passed."
    test_result=0
  fi

  exit $test_result
}
