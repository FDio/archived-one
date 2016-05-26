
source config.sh
source odl_utils.sh
source topologies/rtr_single_iface.sh

# set odl config json file names; they are common among all rtr tests
ODL_CONFIG_FILE1="elp1.json"
ODL_CONFIG_FILE2="elp2.json"

if [ "$1" == "clean" ] ; then
  rtr_single_iface_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_rtr_single_iface {
  rtr_single_iface_setup

  test_result=1

  ip netns exec vpp-ns1 ping -w 15 -c 1 "${1}"
  rc=$?

  rtr_single_iface_clean

  if [ $rc -ne 0 ] ; then
    echo "Test failed: No ICMP response received within specified timeout limit!"
  else
    echo "Test passed."
    test_result=0
  fi

  exit $test_result
}
