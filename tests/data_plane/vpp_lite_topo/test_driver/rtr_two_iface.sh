source config.sh
source odl_utils.sh
source topologies/rtr_two_iface.sh


# set odl config json file names; they are common among all rtr tests
ODL_CONFIG_FILE1="elp1.json"
ODL_CONFIG_FILE2="elp2.json"

if [ "$1" == "clean" ] ; then
  rtr_two_iface_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_rtr_two_iface {
  rtr_two_iface_setup

  maybe_pause

  test_result=1
  rc=0

  if [ "$1" != "${1#*[0-9].[0-9]}" ]; then
    ip netns exec vpp1-ns ping -w 20 -c 1 "${1}"
    rc=$?
  elif [ "$1" != "${1#*:[0-9a-fA-F]}" ]; then
    ip netns exec vpp1-ns ping6 -w 20 -c 1 "${1}"
    rc=$?
  else
    echo "Unrecognized IP format '$1'"
  fi

  maybe_pause

  rtr_two_iface_clean
  print_status $rc "No ICMP response!"
  exit $test_result
}
