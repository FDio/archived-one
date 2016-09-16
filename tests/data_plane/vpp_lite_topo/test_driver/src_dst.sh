source config.sh
source odl_utils.sh
source topologies/3_node_star.sh

ODL_CONFIG_FILE1="map1.json"
ODL_CONFIG_FILE2="map2.json"

if [ "$1" == "clean" ] ; then
  3_node_star_topo_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function send_ping_from_ns
{
  ip netns exec "${1}" "${2}" -w 20 -c 1 "${3}"
  assert_rc_ok $? 3_node_star_topo_clean "No ICMP Response!"
}

function test_src_dst
{
  3_node_star_topo_setup
  post_curl "add-mapping" "map3.json"
  post_curl "add-mapping" "map4.json"

  maybe_pause

  test_result=1

  # send ping for first EID
  send_ping_from_ns vpp-ns1 ${1} ${2}

  # TODO assert counters

  maybe_pause

  # send ping for second EID
  send_ping_from_ns vpp-ns3 ${1} ${2}

  maybe_pause

  # verify first tunnel still works
  send_ping_from_ns vpp-ns1 ${1} ${2}

  maybe_pause

  # verify second tunnel still works
  send_ping_from_ns vpp-ns3 ${1} ${2}
  rc=$?

  maybe_pause
  3_node_star_topo_clean
  print_status $rc "No ICM response!"
  exit $test_result
}

function test_src_dst_l2
{
  3_node_star_topo_setup
  post_curl "add-mapping" "map3.json"
  post_curl "add-mapping" "map4.json"

  maybe_pause

  test_result=1

  # send ping for first EID
  send_ping_from_ns vpp-ns5 ${1} ${2}

  # TODO assert counters

  maybe_pause

  # send ping for second EID
  send_ping_from_ns vpp-ns8 ${1} ${2}

  maybe_pause

  # verify first tunnel still works
  send_ping_from_ns vpp-ns5 ${1} ${2}

  maybe_pause

  # verify second tunnel still works
  send_ping_from_ns vpp-ns8 ${1} ${2}
  rc=$?

  maybe_pause
  3_node_star_topo_clean
  print_status $rc "No ICM response!"
  exit $test_result
}
