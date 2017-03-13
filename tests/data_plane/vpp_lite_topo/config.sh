ODL_USER="admin"
ODL_PASSWD="admin"
ODL_IP="127.0.0.1"
ODL_PORT="8181"

# path to vpp executable
VPP_LITE_DIR=/vpp/build-root/install-vpp_debug-native/vpp/bin
VPP_LITE_BIN=${VPP_LITE_DIR}/vpp
VPP_API_TEST=/vpp/build-root/install-vpp_debug-native/vpp-api-test/bin/vpp_api_test

# read user config file if exists
if [ -f "${HOME}/.onerc" ] ; then
  source "${HOME}/.onerc"
fi

if [ ! -f "${VPP_LITE_BIN}" ] ; then
  echo "Error: VPP binary not found. You can set VPP_LITE_BIN in config.sh"
  echo "Current value:"
  echo "VPP_LITE_BIN=${VPP_LITE_BIN}"
  exit 1
fi

if [ ! -f "${VPP_API_TEST}" ] ; then
  echo "Error: vpp_api_test not found. Either it's not built or environment \
    variable VPP_API_TEST is not set. You can build vpp_api_test with:"
  echo "$ make build-vat"
  echo "VPP_API_TEST can be set in config.sh or in ~/.onerc."
  echo "Current value:"
  echo "VPP_API_TEST=${VPP_API_TEST}"
  exit 1
fi

if [ "${CFG_METHOD}" == '' ] ; then
  CFG_METHOD=vat
  echo
  echo "* INFO: configuration method not selected, defaulting to 'vat'"
  echo "* To define the method run the test as follows:"
  echo "* $ sudo CFG_METHOD=vat|cli ./tests/<tc>.sh"
  echo
fi

function clean_all
{
  echo "Clearing all VPP instances.."
  pkill vpp --signal 9
  rm /dev/shm/* &> /dev/null

  echo "Cleaning topology.."
  ip netns exec intervppns ifconfig vppbr down &> /dev/null
  ip netns exec intervppns brctl delbr vppbr &> /dev/null
  ip netns exec intervppns1 ifconfig vppbr down &> /dev/null
  ip netns exec intervppns1 brctl delbr vppbr &> /dev/null
  ip netns exec intervppns2 ifconfig vppbr down &> /dev/null
  ip netns exec intervppns2 brctl delbr vppbr &> /dev/null
  ip netns exec intervpp-ns ifconfig vppbr1 down &> /dev/null
  ip netns exec intervpp-ns brctl delbr vppbr1 &> /dev/null
  ip netns exec xtr-rtr-ns ifconfig vppbr1 down &> /dev/null
  ip netns exec xtr-rtr-ns brctl delbr vppbr1 &> /dev/null

  ip link del dev veth_vpp1 &> /dev/null
  ip link del dev veth_vpp2 &> /dev/null
  ip link del dev vpp1_cus1 &> /dev/null
  ip link del dev vpp2_cus1 &> /dev/null
  ip link del dev vpp1_cus2 &> /dev/null
  ip link del dev vpp2_cus2 &> /dev/null
  ip link del dev vpp1 &> /dev/null
  ip link del dev vpp2 &> /dev/null

  ip link del dev veth_intervpp1 &> /dev/null
  ip link del dev veth_intervpp2 &> /dev/null
  ip link del dev veth_intervpp11 &> /dev/null
  ip link del dev veth_intervpp12 &> /dev/null
  ip link del dev veth_intervpp21 &> /dev/null
  ip link del dev veth_intervpp22 &> /dev/null
  ip link del dev intervpp1 &> /dev/null
  ip link del dev intervpp2 &> /dev/null
  ip link del dev xtr_rtr1 &> /dev/null
  ip link del dev xtr_rtr2 &> /dev/null
  ip link del dev xtr_rtr3 &> /dev/null

  ip link del dev veth_odl &> /dev/null
  ip link del dev odl &> /dev/null

  ip netns del vppns1 &> /dev/null
  ip netns del vppns2 &> /dev/null
  ip netns del intervppns &> /dev/null
  ip netns del intervppns1 &> /dev/null
  ip netns del intervppns2 &> /dev/null
  ip netns del vpp1-cus1-ns &> /dev/null
  ip netns del vpp1-cus2-ns &> /dev/null
  ip netns del vpp2-cus1-ns &> /dev/null
  ip netns del vpp2-cus2-ns &> /dev/null
  ip netns del intervpp-ns &> /dev/null
  ip netns del vpp-ns1 &> /dev/null
  ip netns del vpp-ns2 &> /dev/null
  ip netns del xtr-rtr-ns &> /dev/null

  if [ "$1" != "no_odl" ] ; then
    odl_clear_all
  fi
}

function maybe_pause
{
  if [ "$WAIT" == "1" ] ; then
    read -p  "press any key to continue .." -n1
  fi
}


function start_vpp
{
  # start_vpp port prefix

  ${VPP_LITE_BIN} \
    unix { log /tmp/$2.log           \
           full-coredump             \
           cli-listen localhost:$1 } \
    api-trace { on } api-segment { prefix "$2" }
    plugins { plugin dpdk_plugin.so { disable } }
}

function print_status
{
  # show_status rc error_msg
  if [ $1 -ne 0 ] ; then
    echo "Test failed: $2"
  else
    echo "Test passed."
    test_result=0
  fi
}

function assert_rc_ok
{
  # assert_rc_ok rc cleanup_fcn error_msg
  if [ $1 -ne 0 ] ; then
    echo $3
    maybe_pause
    $2
    exit $test_result
  fi
}

function assert_rc_not_ok
{
  if [ $1 -eq 0 ] ; then
    echo $3
    maybe_pause
    $2
    exit $test_result
  fi
}

function start_map_resolver
{
  echo "starting dummy map resolver on interface $1"
  python scripts/dummy_mr.py "$1" 4342 &
  mr_id=$!
}
