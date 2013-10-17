#!/bin/bash

if [ $( ps -ax | grep fuzzycactus | grep -c -v grep ) -ne 1 ]; then
	kill "$(  fuzz=( $( ps -ax | grep fuzzycactus | grep -v grep ) ) && echo ${fuzz[0]} )"
else
	echo "No fuzzycactus process running."
	exit
fi
./crashcleaner.sh