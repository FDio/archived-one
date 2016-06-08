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
  two_customers_topo_clean
  sleep 1
  two_customers_topo_setup

  # init to test failed
  test_result=1

  #read -p  "press any key to continue .." -n1

  ip netns exec vpp1-cus1-ns "${1}" -w 20 -c 1 "${2}"
  rc=$?
  if [ $rc -ne 0 ] ; then
    echo "Error: customer 1 did not reveive any response!"
  fi

  #read -p  "press any key to continue .." -n1

  ip netns exec vpp1-cus2-ns "${1}" -w 20 -c 1 "${2}"
  rc=$?
  if [ $rc -ne 0 ] ; then
    echo "Error: customer 2 did not reveive any response!"
  fi

#  two_customers_topo_clean

  if [ $rc -ne 0 ] ; then
    echo "Test failed!";
  else
    echo "Test passed."
    test_result=0
  fi

  exit $test_result
}
