source config.sh
source odl_utils.sh
source topologies/basic_topo_l2.sh

ODL_CONFIG_FILE1="vpp1.json"
ODL_CONFIG_FILE2="vpp2.json"

if [ "$1" == "clean" ] ; then
  basic_topo_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function test_basic
{
  if [ "$3" != "no_setup" ] ; then
    basic_topo_setup
  fi

  maybe_pause
  test_result=1

  ip netns exec vppns1 "${1}" -w 15 -c 1 "${2}"
  rc=$?

  maybe_pause
  assert_rc_ok $rc basic_topo_clean "No response received!"

  # test done

  basic_topo_clean
  print_status $rc "No ICM response!"
  exit $test_result
}
