#!/bin/bash

file=$1

#check for file in
if [[ -z $file ]]; then
	echo "You must provide a file as a parameter."
	echo "Usage: ./fuzzycactus.sh ./file.mov"
	exit
fi

./crashclean.sh
./fuzzycactus.sh $file &> ./fuzz.log &
tail -f ./fuzz.log