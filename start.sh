#!/bin/bash

file=$1

if [[ ! -e ./checks.sh ]]; then
	echo "No 'checks.sh' file found, please re-download from http://github.com/compilingEntropy/fuzzycactus."
	exit
fi

./checks.sh
if [ $? -ne 2 ]; then
	exit
fi

#check for file in
if [[ -z $file ]]; then
	echo "You must provide a file as a parameter."
	echo "Usage: ./start.sh ./file.mov"
	exit
fi
if [[ ! -e $file ]]; then
	echo "The file you provided does not exist."
	echo "Please check your path and try again."
fi

if [[ ! -e ./crashclean.sh ]]; then
	echo "No 'crashclean.sh' file found, please re-download from http://github.com/compilingEntropy/fuzzycactus."
	exit
fi
./crashclean.sh 2>&1 | tee -a ./fuzz.log

if [[ ! -e ./fuzzycactus.sh ]]; then
	echo "No 'fuzzycactus.sh' file found, please re-download from http://github.com/compilingEntropy/fuzzycactus."
	exit
fi
./fuzzycactus.sh $file &> ./fuzz.log &
tail -f ./fuzz.log