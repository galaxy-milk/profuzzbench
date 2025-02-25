#!/bin/bash

folder=$1   #fuzzer result folder
pno=$2      #port number
step=$3     #step to skip running gcovr and outputting data to covfile
            #e.g., step=5 means we run gcovr after every 5 test cases
covfile=$4  #path to coverage file
fmode=$5    #file mode -- structured or not
            #fmode = 0: the test case is a concatenated message sequence -- there is no message boundary
            #fmode = 1: the test case is a structured file keeping several request messages

#delete the existing coverage file
if [[ ! -d $(dirname $covfile) ]]; then
    mkdir -p $(dirname $covfile)
fi
if [[ -e $covfile ]]; then
    rm $covfile
fi
touch $covfile

#clear gcov data
cov_root="$WORKDIR/libiec61850-gcov"
gcovr -r $cov_root -s -d > /dev/null 2>&1

#output the header of the coverage file which is in the CSV format
#Time: timestamp, l_per/b_per and l_abs/b_abs: line/branch coverage in percentage and absolutate number
echo "Time,l_per,l_abs,b_per,b_abs" >> $covfile

#files stored in replayable-* folders are structured
#in such a way that messages are separated
if [ $fmode -eq "1" ]; then
  testdir="replayable-queue"
  replayer="aflnet-replay"
else
  testdir="queue"
  replayer="afl-replay"
fi

app="${WORKDIR}/libiec61850-gcov/examples/server_example_substitution/server_example_substitution"
# app="server_example_substitution"

#process seeds first
for f in ${folder}/${testdir}/*.raw; do 
  echo "replay: $f"
  time=$(stat -c %Y $f)
    
  $replayer $f MMS $pno 100 > /dev/null 2>&1 &
  replayer_pid=$!
  # timeout -k 0 3s ./apps/openssl s_server -key key.pem -cert cert.pem -4 -naccept 1 -no_anti_replay > /dev/null 2>&1
  timeout -k 0 3s $app > /dev/null 2>&1
  # while true; do
  #     timeout -k 0 3s $app > /dev/null 2>&1
  #
  #     if [ $? -eq 124 ]; then
  #         break
  #     fi
  # done
  wait $replayer_pid

  cov_data=$(gcovr -r $cov_root -s | grep "[lb][a-z]*:")
  l_per=$(echo "$cov_data" | grep lines | cut -d" " -f2 | rev | cut -c2- | rev)
  l_abs=$(echo "$cov_data" | grep lines | cut -d" " -f3 | cut -c2-)
  b_per=$(echo "$cov_data" | grep branch | cut -d" " -f2 | rev | cut -c2- | rev)
  b_abs=$(echo "$cov_data" | grep branch | cut -d" " -f3 | cut -c2-)
  
  echo "$time,$l_per,$l_abs,$b_per,$b_abs"
  echo "$time,$l_per,$l_abs,$b_per,$b_abs" >> $covfile
done

#process other testcases
count=0
for f in $folder/${testdir}/id*; do 
  echo "replay: $f"
  time=$(stat -c %Y $f)
  
  $replayer $f MMS $pno 100 > /dev/null 2>&1 &
  replayer_pid=$!
  # timeout -k 0 3s ./apps/openssl s_server -key key.pem -cert cert.pem -4 -naccept 1 -no_anti_replay > /dev/null 2>&1
  timeout -k 0 3s $app > /dev/null 2>&1
  # while true; do
  #     timeout -k 0 3s $app > /dev/null 2>&1
  #
  #     if [ $? -eq 124 ]; then
  #         break
  #     fi
  # done

  wait $replayer_pid

  count=$(expr $count + 1)
  rem=$(expr $count % $step)
  if [ "$rem" != "0" ]; then continue; fi
  cov_data=$(gcovr -r $cov_root -s | grep "[lb][a-z]*:")
  l_per=$(echo "$cov_data" | grep lines | cut -d" " -f2 | rev | cut -c2- | rev)
  l_abs=$(echo "$cov_data" | grep lines | cut -d" " -f3 | cut -c2-)
  b_per=$(echo "$cov_data" | grep branch | cut -d" " -f2 | rev | cut -c2- | rev)
  b_abs=$(echo "$cov_data" | grep branch | cut -d" " -f3 | cut -c2-)
  
  echo "$time,$l_per,$l_abs,$b_per,$b_abs"
  echo "$time,$l_per,$l_abs,$b_per,$b_abs" >> $covfile
done

#ouput cov data for the last testcase(s) if step > 1
if [[ $step -gt 1 ]]
then
  time=$(stat -c %Y $f)
  cov_data=$(gcovr -r $cov_root -s | grep "[lb][a-z]*:")
  l_per=$(echo "$cov_data" | grep lines | cut -d" " -f2 | rev | cut -c2- | rev)
  l_abs=$(echo "$cov_data" | grep lines | cut -d" " -f3 | cut -c2-)
  b_per=$(echo "$cov_data" | grep branch | cut -d" " -f2 | rev | cut -c2- | rev)
  b_abs=$(echo "$cov_data" | grep branch | cut -d" " -f3 | cut -c2-)
  
  echo "$time,$l_per,$l_abs,$b_per,$b_abs"
  echo "$time,$l_per,$l_abs,$b_per,$b_abs" >> $covfile
fi
