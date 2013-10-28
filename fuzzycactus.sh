#!/bin/bash

#installs to /private/var/fuzzycactus/

file=$1
slowdown=0
time=11
params=( $( for arg in $@; do echo "$arg"; done ) )
usage="Usage: fuzzycactus [start/stop/help] /path/to/file.mov [-s] [-t 11]"


#get the time
i=0
for arg in "${params[@]}"; do
	if [[ "$arg" == "-t" ]]; then
		time="${params[$i+1]}"
	fi
	if [[ "$arg" == "-s" ]]; then
		slowdown=1
	fi
	((i++))
done

#check the time
if [[ $( echo $time | egrep -c "^[0-9]+$" ) -ne 1 ]]; then
	echo "The time provided isn't valid."
	echo "Please provide a new time."
	echo "$usage"
	exit
fi


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
	echo "$usage"
	exit
fi
if [[ ! -e $file ]]; then
	echo "The file you provided does not exist."
	echo "Please check your path and try again."
	exit
fi

extension=$( echo $file | sed 's|.*\.||g' )
j=1

cp $file ./file."$extension" &> /dev/null

#may not be necessary, but the idea is that as your device slows down from testing more files, it will add to the sleep time
slowdown()
{
	let j+=1
	if [ $j -ge 25 ]; then
		time=$( bc <<< "scale=1;$time+ 0.1" )
		j=1
		echo "Time incremented"
	fi
}

for (( i = 1; i < 10000; i++ )); do
	if [ $( grep -c "~$i " ./tested.log ) -lt 1 ]; then
		echo "~$i `date '+%y.%m.%d-%H.%M.%S'`"
		zzuf -c -r 0.0001:0.001 -s $i < $file > /private/var/www/files/"$i"."$extension"
		echo "File generated"
		sbopenurl http://127.0.0.1/files/"$i"."$extension"
		echo "Safari opened"
		sleep $time
		resetsafari
		#killall -KILL mediaserverd
		echo "Safari killed"
		if [ $slowdown -eq 1 ]; then
			slowdown
		fi
		echo "~$i `date '+%y.%m.%d-%H.%M.%S'`" >> ./tested.log
	else
		echo "Skipping $i"
	fi
done

echo "Done!"
fuzzycactus stop