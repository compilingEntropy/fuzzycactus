#!/bin/bash

file=$1

#check for file in
if [[ -z $file ]]; then
	echo "You must provide a file as a parameter."
	echo "Usage: ./autofuzz.sh ./file.mov"
	exit
fi
if [[ ! -e $file ]]; then
	echo "The file you provided does not exist."
	echo "Please check your path and try again."
fi

./crashclean.sh
./fuzzycactus.sh $file &> ./fuzz.log &
tail -f ./fuzz.log