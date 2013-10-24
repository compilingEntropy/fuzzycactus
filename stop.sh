#!/bin/bash

pnum=$( ps -ax | grep fuzzycactus | grep -v stop | grep -c -v grep )

if [ $pnum -eq 0 ]; then
	echo "No fuzzycactus process running."
else
	while [ $pnum -ge 1 ]; do
		kill "$( fuzz=( $( ps -ax | grep fuzzycactus | grep -v stop | grep -v grep ) ) && echo ${fuzz[0]} )" &> /dev/null
		echo "Stopped."
		((pnum--))
		sleep 0.5
	done
fi

if [[ ! -e ./crashclean.sh ]]; then
	echo "No 'crashclean.sh' file found, please re-download from http://github.com/compilingEntropy/fuzzycactus."
	exit
fi
./crashclean.sh 2>&1 | tee -a ./fuzz.log