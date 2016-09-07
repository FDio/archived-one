source config.sh
source odl_utils.sh
source topologies/rtr_two_iface_two_customers.sh

ODL_CONFIG_FILE1="vpp1_customer1.json"
ODL_CONFIG_FILE2="vpp2_customer1.json"
ODL_CONFIG_FILE3="vpp1_customer2.json"
ODL_CONFIG_FILE4="vpp2_customer2.json"

if [ "$1" == "clean" ] ; then
  rtr_two_iface_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_rtr_two_iface_two_customers {
  rtr_two_iface_two_customers_setup
  sleep 1

  test_result=0
  rc=0

  maybe_pause

  ip netns exec vpp1-cus1-ns "${1}" -w 20 -c 1 "${2}"
  assert_rc_ok $? rtr_two_iface_two_customers_clean "No response received!"

  ip netns exec vpp1-cus2-ns "${1}" -w 20 -c 1 "${2}"
  rc=$?

  maybe_pause

  rtr_two_iface_two_customers_clean
  print_status $rc "No ICMP response!"
  exit $test_result
}
