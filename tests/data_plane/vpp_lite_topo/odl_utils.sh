
function post_curl {
  echo "Sending mapping from ${2} to ODL; operation: ${1}"
  until [ "`curl -X POST "http://${ODL_IP}:${ODL_PORT}/restconf/operations/odl-mappingservice:${1}" \
     -H "Content-Type: application/json" --data-binary "@${ODL_CONFIG_DIR}/${2}" \
     -u ${ODL_USER}:${ODL_PASSWD} -s -o /dev/null -w "%{http_code}"`" == "200" ]
  do
    echo "Updating failed; trying again.."
  done
}

function odl_clear_all {
  echo "Deleting all ODL mappings.."
  curl -X DELETE "http://${ODL_IP}:${ODL_PORT}/restconf/config/odl-mappingservice:mapping-database" \
       -u ${ODL_USER}:${ODL_PASSWD}
}

function check_odl_running {
  if [ -z  "`netstat -tunlp | grep 8181`" ] ; then
  echo "ODL is not running!"
    exit 1
  fi
}
