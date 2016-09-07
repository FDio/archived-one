source config.sh
source odl_utils.sh
source topologies/two_customers_topo.sh

ODL_CONFIG_FILE1="vpp1_customer1.json"
ODL_CONFIG_FILE2="vpp2_customer1.json"
ODL_CONFIG_FILE3="vpp1_customer2.json"
ODL_CONFIG_FILE4="vpp2_customer2.json"

if [ "$1" == "clean" ] ; then
  two_customers_topo_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_eid_virtualization {
  two_customers_topo_setup

  # init to test failed
  test_result=1

  maybe_pause

  ip netns exec vpp1-cus1-ns "${1}" -w 20 -c 1 "${2}"
  assert_rc_ok $? two_customers_topo_clean "No response!"

  maybe_pause

  ip netns exec vpp1-cus2-ns "${1}" -w 20 -c 1 "${2}"
  rc=$?

  maybe_pause

  two_customers_topo_clean
  print_status $rc "No ICMP response!"
  exit $test_result
}
