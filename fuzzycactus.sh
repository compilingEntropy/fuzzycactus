#!/bin/bash

#depends on:
#a file to fuzz
#zzuf
#'sbutils' from cydia
#'bc' from cydia
#'lighttpd' from cydia
#'adv-cmds' from cydia
#'safariresetter' from cydia
#'cURL' from cydia
#'wget' from cydia
#'coreutils' from cydia

#installs to /private/var/fuzzycactus/

file=$1
time=11
usage="Usage: fuzzycactus [start/stop/help] /path/to/file.mov"

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

extension=$( echo $file | sed 's|.*\.||g' )

if [[ ! -e $file ]]; then
	echo "The file you provided does not exist."
	echo "Please check your path and try again."
fi

j=1

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
		slowdown
		echo "~$i `date '+%y.%m.%d-%H.%M.%S'`" >> ./tested.log
	else
		echo "Skipping $i"
	fi
done