source config.sh
source odl_utils.sh
source topologies/basic_two_odls.sh

ODL_CONFIG_FILE1="vpp1.json"
ODL_CONFIG_FILE2="vpp2.json"

if [ "$1" == "clean" ] ; then
  basic_two_odls_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as a root."
  exit 1
fi

function start_map_resolver
{
  echo "starting dummy map resolver on interface $1"
  python scripts/dummy_mr.py "$1" 4342 &
  mr_id=$!
}

function test_resolver_failover
{
  basic_two_odls_setup

  start_map_resolver "6.0.3.100"

  test_result=1

  if [ "$3" == "wait" ] ; then
    read -p  "press any key to continue .." -n1
  fi

  ip netns exec vppns1 "${1}" -w 20 -c 1 "${2}"
  rc=$?

  # test done
  if [ "$3" == "wait" ] ; then
    read -p  "press any key to continue .." -n1
  fi

  basic_two_odls_clean
  kill $mr_id

  if [ $rc -ne 0 ] ; then
    echo "Test failed: No ICMP response received within specified timeout limit!"
  else
    echo "Test passed."
    test_result=0
  fi

  exit $test_result
}
