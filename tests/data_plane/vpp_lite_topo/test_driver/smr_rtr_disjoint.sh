source config.sh
source odl_utils.sh
source topologies/smr_rtr_disjoint.sh

# set odl config json file names; they are common among all rtr tests
ODL_CONFIG_FILE1="vpp1.json"
ODL_CONFIG_FILE2="vpp2.json"
ODL_CONFIG_FILE3="elp1.json"
ODL_CONFIG_FILE4="elp2.json"

if [ "$1" == "clean" ] ; then
  smr_rtr_disjoint_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_ns_ping {
  if [ "$1" != "${1#*[0-9].[0-9]}" ]; then
    ip netns exec $2 ping -w 15 -c 1 "${1}"
    rc=$?
  elif [ "$1" != "${1#*:[0-9a-fA-F]}" ]; then
    ip netns exec $2 ping6 -w 15 -c 1 "${1}"
    rc=$?
  else
    echo "Unrecognized IP format '$1'"
  fi
  return $rc
}

function test_smr_rtr_disjoint {
  # CONFIGURE
  smr_rtr_disjoint_setup

  maybe_pause

  test_result=1
  rc=0

  # TEST IP6 over IP4
  test_ns_ping $1 vpp1-ns
  assert_rc_ok $? smr_rtr_disjoint_clean "No icmp received!"

  maybe_pause

  # RECONFIGURE
  smr_rtr_disjoint_reconfigure

  maybe_pause

  # TEST IP6 over disjoint IP4 and IP6 underlay
  test_ns_ping $1 vpp1-ns
  rc=$?

  maybe_pause
  # CLEANUP
  smr_rtr_disjoint_clean
  print_status $rc "No ICMP response!"
  exit $test_result
}
