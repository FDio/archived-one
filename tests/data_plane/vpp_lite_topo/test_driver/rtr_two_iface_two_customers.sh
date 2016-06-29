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

  ip netns exec vpp1-cus1-ns "${1}" -w 20 -c 1 "${2}"
  rc=$?
  if [ $rc -ne 0 ] ; then
    echo "Error: customer 1 did not receive any response!"
    test_result=1
  fi

  ip netns exec vpp1-cus2-ns "${1}" -w 20 -c 1 "${2}"
  rc=$?
  if [ $rc -ne 0 ] ; then
    echo "Error: customer 2 did not receive any response!"
    test_result=1
  fi

  rtr_two_iface_two_customers_clean

  if [ $rc -ne 0 ] ; then
    echo "Test failed: No ICMP response received within specified timeout limit!"
  else
    echo "Test passed."
  fi

  exit $test_result
}
