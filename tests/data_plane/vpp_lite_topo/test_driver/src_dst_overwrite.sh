source config.sh
source odl_utils.sh
source topologies/2_node_topo.sh

ODL_CONFIG_FILE1="map1.json"
ODL_CONFIG_FILE2="map2.json"

if [ "$1" == "clean" ] ; then
  2_node_topo_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function send_ping_from_ns
{
  ip netns exec "${1}" "${2}" -w 20 -c 1 "${3}"
  assert_rc_ok $? 2_node_topo_clean "No ICMP Response!"
}

function send_ping_from_ns_expect_failure
{
  ip netns exec "${1}" "${2}" -w 10 -c 1 "${3}"
  assert_rc_not_ok $? 2_node_topo_clean "Reply received, but failure expected!"
}

function remove_sd_mapping {
  curl -X POST -H "Authorization: Basic YWRtaW46YWRtaW4=" -H "Content-Type: application/json" -H "Cache-Control: no-cache" -H "Postman-Token: 1e4f00f4-74eb-20d7-97da-89963f37713b" -d '{
    "input": {
        "eid": {
            "address-type": "ietf-lisp-address-types:source-dest-key-lcaf",
            "source-dest-key": {
                "source": "'$1'",
                "dest": "'$2'"
            }
        }
    }
}' "http://${ODL_IP}:8181/restconf/operations/odl-mappingservice:remove-mapping"
}

function remove_mapping1 {
curl -X DELETE -H "Content-Type: application/json" -H "Cache-Control: no-cache" "http://${ODL_IP}:${ODL_PORT}/restconf/config/odl-mappingservice:mapping-database/virtual-network-identifier/0/mapping/${1}/northbound/"
}

function test_src_dst_overwrite
{
  2_node_topo_setup

  maybe_pause

  test_result=1

  # send ping request
  send_ping_from_ns vppns1 ${1} ${2}

  maybe_pause

  # Replace ODL mapping with negative one
  post_curl "add-mapping" "replace1.json"
  remove_sd_mapping "6.0.1.0/24" "6.0.2.0/24"

  # wait for SMR being resolved
  sleep 2

  maybe_pause

  # now ping should fail
  send_ping_from_ns_expect_failure vppns1 ${1} ${2}

  maybe_pause

  # Replace ODL mapping with positive one
  post_curl "add-mapping" "replace2.json"
  remove_sd_mapping "6.0.0.0/16" "6.0.2.0/24"

  # wait for SMR being resolved
  sleep 2

  maybe_pause

  # expect ping reply again
  send_ping_from_ns vppns1 ${1} ${2}
  rc=$?

  maybe_pause
  2_node_topo_clean
  print_status $rc "No ICM response!"
  exit $test_result
}
