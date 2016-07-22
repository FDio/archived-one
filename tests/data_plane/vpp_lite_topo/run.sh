#!/usr/bin/env bash

TESTS_DIR=tests

function help
{
  echo "Run all ONE tests"
  echo
  echo This must be run with superuser privileges.
  echo "Usage:"
  echo " ./run.sh [vh]"
  echo
  echo "  -v : verbose output"
  echo "  -h : show help"
}

verbose=0

while [ $# -gt 0 ] ; do
  arg=$1
  shift

  if [ $arg == "-v" ]; then
    verbose=1
  elif [ $arg == "-h" ] ; then
    help
    exit 0
  fi
done

### begin script

failed_tcs=()
count=0
failed_num=0
passed_num=0

start_time=`date +%s`

# count tests
test_num=`ls -l $TESTS_DIR/test_* | wc -l`

echo
echo "Running VPP lite test suite."
echo

for test_case in $TESTS_DIR/test_*
do
  let "count=$count + 1"

  # run the test case
  base_name=`basename -a $test_case`
  printf "*** %d/%d : %-45s" $count $test_num $base_name

  if [ $verbose -ne 0 ] ; then
    $test_case
  else
    $test_case &> /dev/null
  fi
  rc=$?

  if [ $rc -ne 0 ] ; then
    printf "failed!\n"
    failed_tcs+=("$test_case")
    let "failed_num=$failed_num + 1"
  else
    printf "passed.\n"
    let "passed_num=$passed_num + 1"
  fi
  sleep 1
done

end_time=`date +%s`
runtime=$((end_time-start_time))

echo
echo "------------------------------------------------------"
echo "Runtime: " `date -u -d @${runtime} +"%M min %S sec"`
echo

if [ $failed_num -eq 0 ]; then
  echo "All tests have passed."
else
  echo "List of failed test cases:"
  for tc in "${failed_tcs[@]}"
  do
    echo "$tc"
  done
fi

echo "------------------------------------------------------"

### end script