#!/bin/bash

#installs to /private/var/fuzzycactus/

#crash directories
crashroot="/private/var/mobile/Library/Logs/CrashReporter"
precrashroot="/private/var/logs/CrashReporter"
crashpanics="$crashroot/Panics"
precrashpanics="$precrashroot/Panics"
crashdirs=( "$crashroot" "$precrashroot" "$crashpanics" "$precrashpanics" )

for dir in "${crashdirs[@]}"; do
	if [[ ! -d $dir/ ]]; then
		mkdir -p $dir/
	fi
done

if [[ ! -d ./Results/ ]]; then
	mkdir ./Results/
fi
if [[ ! -d ./Crashes/Panics/ ]]; then
	mkdir -p ./Crashes/Panics/
fi
if [[ ! -d ./logs/ ]]; then
	mkdir ./logs/
fi
if [[ ! -e ./fuzz.log ]]; then
	touch ./fuzz.log
fi
if [[ ! -e ./tested.log ]]; then
	touch ./tested.log
fi

#count crashes of different types
crashcount()
{
	crashcount=$( ls $crashroot/ | grep -c plist )
	let crashcount+=$( ls $precrashroot/ | grep -c plist )
	paniccount=$( ls $crashpanics/ | grep -c plist )
	let paniccount+=$( ls $precrashpanics/ | grep -c plist )
	oldcrashcount=$( ls ./Crashes/ | grep -c plist )
	oldpaniccount=$( ls ./Crashes/Panics/ | grep -c plist )
}

#generate an array of crash files for the given array $1
crashlist()
{
	crashes=( $( ls -p $1/ | grep -v '\/' | grep 'plist' ) )
}

#pull times out of the crash files
getcrashtime()
{
	date=( $( grep 'Date' $1 ) )
	crashyear="${date[1]:2:2}"
	crashmonth="${date[1]:5:2}"
	crashday="${date[1]:8:2}"
	crashhour="${date[2]:0:2}"
	crashminute="${date[2]:3:2}"
	crashsecond="${date[2]:6:2}"
}

#pull times out of the tested.log file
getlogtime()
{
	logyear="${tested[$i]:0:2}"
	logmonth="${tested[$i]:3:2}"
	logday="${tested[$i]:6:2}"
	loghour="${tested[$i]:9:2}"
	logminute="${tested[$i]:12:2}"
	logsecond="${tested[$i]:15:2}"
}

foundit()
{
	files=( "${files[@]}" "${tested[$i]}" )
	filefound=1
	echo -n "."
	break
}

#find where the crashtime fits in the logs and return the file that caused it to files[]
comparetimes()
{
if [ $crashyear -eq $logyear ]; then
	
	if [ $crashmonth -eq $logmonth ]; then
		
		if [ $crashday -eq $logday ]; then
			
			if [ $crashhour -eq $loghour ]; then

				if [ $crashminute -eq $logminute ]; then
					
					if [ $crashsecond -eq $logsecond ]; then
						#wut
						files=( "${files[@]}" "${tested[$i]}" )
					elif [ $crashsecond -lt $logsecond ]; then
						foundit
					fi

				elif [ $crashminute -lt $logminute ]; then
					foundit
				fi

			elif [ $crashhour -lt $loghour ]; then
				foundit
			fi

		elif [ $crashday -lt $logday ]; then
			foundit
		fi

	elif [ $crashmonth -lt $logmonth ]; then
		foundit
	fi

elif [ $crashyear -lt $logyear ]; then
	foundit
fi
}

#pairs crashes with files that caused them, and copy them both to a directory created in ./Results/
sortcrashes()
{
if [[ $filefound -eq 1 ]]; then
	latest="${files[$(( ${#files[@]}-1 ))]}" #last file in files[] array
	tempseed=$( grep $latest ./tested.log | sed "s| $latest||g;s|~||g" ) #get the seed of the file that caused the crash
	crashtype=$( echo "$crash" | sed 's|_.*||g' | sed 's|-.*||g' ) #type of crash determined by whatever comes before '-' or '_' in crash name
	
	#create directory if it does not exist, and copy files to that directory
	if [[ ! -d ./Results/"$crashtype"_"$tempseed"/ ]]; then
		mkdir ./Results/"$crashtype"_"$tempseed"/
	fi	
	mv $dir/$crash ./Results/"$crashtype"_"$tempseed"/
	cp /var/www/files/$tempseed.* ./Results/"$crashtype"_"$tempseed"/
else
	#file not found, return the last file tested to files[]
	notinfile=1
	unpaired=( "${unpaired[@]}" "$crash" )
	if [ "${#tested[$i]}" -ne 0 ]; then
		files=( "${files[@]}" "${tested[$i-1]}" )
	fi
	mv $dir/$crash ./Crashes/Unpaired/
	echo -n "-"
fi
}

#Fix for iOS7 crashes
for dir in "${crashdirs[@]}"; do
	crashlist $dir
	for crash in "${crashes[@]}"; do
		if [ $( echo "$crash" | grep -c ".synced" ) -ge 1 ]; then
			mv "$dir/$crash" "$dir/$( echo $crash | sed 's|.synced||g' )"
		fi
	done
done

#delete garbage files and count how many you've deleted
crashcount
crashcount1=$crashcount
for dir in "${crashdirs[@]:0:2}"; do
	if [[ $( ls $dir/ | grep -c "Latest" ) -ge 1 ]]; then
		rm $dir/Latest*.plist
	fi
	if [[ $( ls $dir/ | grep -c "Reset" ) -ge 1 ]]; then
		rm $dir/Reset*.plist
	fi
	if [[ $( ls $dir/ | grep -c "LowMemory" ) -ge 1 ]]; then
		rm $dir/LowMemory*.plist
	fi
	if [[ $( ls $dir/ | grep -c "LowBatteryLog" ) -ge 1 ]]; then
		rm $dir/LowBatteryLog*.plist
	fi
done
crashcount
if [[ $(($crashcount1-$crashcount)) -ne 0 ]]; then
	echo "Removed $(($crashcount1-$crashcount)) garbage file(s)."
fi

#copy crashes and tell how many have been copied
crashcount
crashcount1=$crashcount
oldcrashcount1=$oldcrashcount
if [ $crashcount -ge 1 ]; then
	echo "You have $crashcount crash(es)."
	for dir in "${crashdirs[@]:0:2}"; do
		if [ $( ls $dir/ | grep -c plist ) -ge 1 ]; then
			cp $dir/*.plist ./Crashes/
		fi
	done
	crashcount
	echo "Copied $(($oldcrashcount-$oldcrashcount1)) crash(es) to /priavte/var/fuzzycactus/Crashes/ for you to inspect."
	if [[ $crashcount1 -ne $(($oldcrashcount-$oldcrashcount1)) ]]; then
		echo "Not all files copied, look in $crashroot/ for the rest."
	fi
fi
#copy panics and tell how many have been copied
crashcount
paniccount1=$paniccount
oldpaniccount1=$oldpaniccount
if [[ $paniccount -ge 1 ]]; then
	echo "You have $paniccount kernel panic(s)."
	for dir in "${crashdirs[@]:2:2}"; do
		if [ $( ls $dir/ | grep -c plist ) -ge 1 ]; then
			cp $dir/*.plist ./Crashes/Panics/
		fi
	done
	crashcount
	echo "Copied $(($oldpaniccount-$oldpaniccount1)) kernel panic(s) to /priavte/var/fuzzycactus/Crashes/Panics/ for you to inspect."
	if [[ $paniccount1 -ne $(($paniccount-$paniccount1)) ]]; then
		echo "Not all files copied, look in $crashpanics/ for the rest."
	fi
fi

#tell users we're working
if [ $crashcount -ge 1 -o $paniccount -ge 1 ]; then
	echo "Finding files that caused crashes, please wait..."
fi

#store timestamps of all files tested so far in this session to tested[]
tested=( $( sed 's|.* ||g' ./tested.log ) )


#main routine
for dir in "${crashdirs[@]}"; do
	crashlist $dir
	for crash in "${crashes[@]}"; do
		filefound=0
		getcrashtime "$dir/$crash"
		for (( i = 0; i < ${#tested[@]}; i++ )); do
			getlogtime
			comparetimes
		done
		sortcrashes
	done
done


#newline to seperate the '.' and '-' from other output (if they exist)
if [ $crashcount -ge 1 -o $paniccount -ge 1 ]; then
	echo ""
fi

#build seeds[]
if [ "${#files[@]}" -ge 1 ]; then
	for file in "${files[@]}"; do
		seeds=( "${seeds[@]}" $( grep $file ./tested.log | sed "s| $file||g;s|~||g" ) ) #return the seed for a given crash
	done
fi

#if there are things in the log indicating mobilesafari may have crashed, add them to seeds[]
if [[ $( grep -c "No matching processes were found" ./fuzz.log ) -gt 0 ]]; then
	echo 'Found things in the logs indicating MobileSafari may have crashed.'
	safarifiles=$( grep 'No matching processes were found' -B 5 ./fuzz.log | grep '~' | sed "s| .*||g;s|~||g" )
	seeds=( "${seeds[@]}" "${safarifiles[@]}" )
	echo "Seeds which possibly caused MobileSafari crashes:"
	echo "${safarifiles[@]}"
fi

#append a '*' to each entry in tested.log that is associated with a crash
for seed in "${seeds[@]}"; do
	sed -i -r "s|~$seed .*|&\*|g" ./tested.log
done

#if there were crashes that couldn't be matched with files, list them
if [[ $notinfile -eq 1 ]]; then
	if [[ ! -d ./Crashes/Unpaired/ ]]; then
		mkdir -p ./Crashes/Unpaired/
	fi
	echo "Not all crashes were able to be paired up with seeds."
	echo "This is probably due to crashes that were in your CrashReporter directory prior to fuzzing."
	unpaired=( $( for crash in "${unpaired[@]}"; do echo "$crash"; done | sort -u ) )
	echo "Crashes which were unable to be paired with a seed:"
	for pairfail in "${unpaired[@]}"; do
		echo "$pairfail"
	done
fi

#if there are seeds that caused crashes, list them
if [ "${#seeds[@]}" -ge 1 ]; then
	seeds=( $( for seed in "${seeds[@]}"; do echo "$seed"; done | sort -n -u ) )
	echo "Files/seeds which likely caused crashes, and are worth checking out:"
	for seed in "${seeds[@]}"; do
		echo "$seed"
	done
fi

#clean up for new fuzzing session
if [ $( grep -c '1' ./fuzz.log ) -ge 1 ]; then
	mv ./fuzz.log ./logs/`date '+%y.%m.%d-%H.%M.%S'`.log
fi