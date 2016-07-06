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

function test_basic_multi_traffic
{
  basic_topo_setup

  # additional setup
  ODL_CONFIG_DIR=`pwd`/../configs/odl/basic/4o4
  post_curl "add-mapping" ${ODL_CONFIG_FILE1}
  post_curl "add-mapping" ${ODL_CONFIG_FILE2}

  test_result=1

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  if [ $? -ne 0 ] ; then
    echo "No response received!"
    basic_topo_clean
    exit $test_result
  fi

  ip netns exec vppns1 "${3}" -w 15 -c 1 "${4}"
  if [ $? -ne 0 ] ; then
    echo "No response received!"
    basic_topo_clean
    exit $test_result
  fi

  # change IP addresses of destination RLOC
  echo "set int ip address del host-intervpp2 6.0.3.2/24" | nc 0 5003
  echo "set int ip address host-intervpp2 6.0.3.20/24" | nc 0 5003
  echo "set int ip address del host-intervpp2 6:0:3::2/24" | nc 0 5003
  echo "set int ip address host-intervpp2 6:0:3::20/24" | nc 0 5003

  ODL_CONFIG_DIR=`pwd`/../configs/odl/basic/6o6
  post_curl "update-mapping" ${ODL_CONFIG_FILE3}
  ODL_CONFIG_DIR=`pwd`/../configs/odl/basic/4o4
  post_curl "update-mapping" ${ODL_CONFIG_FILE3}

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  if [ $? -ne 0 ] ; then
    echo "No response received!"
    basic_topo_clean
    exit $test_result
  fi

  ip netns exec vppns1 "${3}" -w 15 -c 1 "${4}"
  rc=$?

  # test done

  basic_topo_clean
  if [ $rc -ne 0 ] ; then
    echo "Test failed: No ICMP response received within specified timeout limit!"
  else
    echo "Test passed."
    test_result=0
  fi

  exit $test_result
}

