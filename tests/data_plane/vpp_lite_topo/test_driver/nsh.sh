source config.sh
source odl_utils.sh
source topologies/2_node_topo.sh

ODL_CONFIG_FILE1="vpp1.json"
ODL_CONFIG_FILE2="vpp2.json"

if [ "$1" == "clean" ] ; then
  2_node_topo_clean
  exit 0
fi

if [[ $(id -u) != 0 ]]; then
  echo "Error: run this as root."
  exit 1
fi

function test_nsh
{
  2_node_topo_setup
  rc=1

  maybe_pause

  cat << EOF > scripts/lisp_nsh
create packet-generator interface pg0

packet-generator new {
  name nsh1
  limit 1
  node lisp-cp-lookup-nsh
  size 64-64
  no-recycle
  worker 0
  interface pg0
  pcap ${ONE_ROOT}/tests/data_plane/vpp_lite_topo/scripts/nsh.pcap
}
EOF

  echo "trace add af-packet-input 100" | nc 0 5002
  echo "trace add af-packet-input 100" | nc 0 5003
  echo "exec ${ONE_ROOT}/tests/data_plane/vpp_lite_topo/scripts/lisp_nsh" | nc 0 5002
  echo "packet-generator enable-stream nsh1" | nc 0 5002

  # add dummy node to ETR
  echo "test one nsh add-dummy-decap-node" | nc 0 5003

  # inject NSH packet to ITR
  echo "test one nsh pcap ${ONE_ROOT}/tests/data_plane/vpp_lite_topo/scripts/nsh.pcap" | nc 0 5002

  # check decap stats
  decap_stats="`echo "show errors" | nc 0 5003 | grep "lisp gpe dummy nsh decap" | awk '{print $1}'`"

  if [ "$decap_stats" == "1" ] ; then
    rc=0  # test pass
  fi

  maybe_pause
  2_node_topo_clean
  print_status $rc "NSH test failed!"
  exit $test_result
}
