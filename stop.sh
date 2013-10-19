#!/bin/bash

pnum=$( ps -ax | grep fuzzycactus | grep -c -v grep )
if [ $pnum -eq 1 ]; then
	kill "$(  fuzz=( $( ps -ax | grep fuzzycactus | grep -v grep ) ) && echo ${fuzz[0]} )" &> /dev/null
	echo "Stopped."
elif [[ $pnum -eq 0 ]]; then
	echo "No fuzzycactus process running."
else
	echo "Multiple instances of fuzzycactus found, please kill them manually."
	echo "$( ps -ax | grep fuzzycactus | grep -v grep )"
fi

if [[ ! -e ./crashclean.sh ]]; then
	echo "No 'crashclean.sh' file found, please re-download from http://github.com/compilingEntropy/fuzzycactus."
	exit
fi
./crashclean.sh