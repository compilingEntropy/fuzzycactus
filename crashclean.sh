#!/bin/bash

#crash directories
crashroot="/private/var/mobile/Library/Logs/CrashReporter"
crashpanics="$crashroot/Panics"
crashdirs=( "$crashroot" "$crashpanics" )

if [[ ! -d $crashpanics/ ]]; then
	mkdir -p $crashpanics/
fi
if [[ ! -d ./Crashes/Panics/ ]]; then
	mkdir -p ./Crashes/Panics/
fi
if [[ ! -d ./Results/ ]]; then
	mkdir ./Results/
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

crashcount()
{
	crashcount=$( ls $crashroot/ | grep -c plist )
}

crashlist()
{
	crashes=( $( ls -p $1/ | grep -v '\/' | grep 'plist' ) )
}

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

getlogtime()
{
	logyear="${tested[$i]:0:2}"
	logmonth="${tested[$i]:3:2}"
	logday="${tested[$i]:6:2}"
	loghour="${tested[$i]:9:2}"
	logminute="${tested[$i]:12:2}"
	logsecond="${tested[$i]:15:2}"
}

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
						#found it
						files=( "${files[@]}" "${tested[$i]}" )
						filefound=1
						break
					fi

				elif [ $crashminute -lt $logminute ]; then
					notinfile=1
					unpaired=( "${unpaired[@]}" "$crash" )
				fi

			elif [ $crashhour -lt $loghour ]; then
				notinfile=1
				unpaired=( "${unpaired[@]}" "$crash" )
			fi

		elif [ $crashday -lt $logday ]; then
			notinfile=1
			unpaired=( "${unpaired[@]}" "$crash" )
		fi

	elif [ $crashmonth -lt $logmonth ]; then
		notinfile=1
		unpaired=( "${unpaired[@]}" "$crash" )
	fi

elif [ $crashyear -lt $logyear ]; then
	notinfile=1
	unpaired=( "${unpaired[@]}" "$crash" )
fi
}

sortcrashes()
{
if [[ $filefound -eq 1 ]]; then
	latest="${files[$(( ${#files[@]}-1 ))]}"
	tempseed=$( grep $latest ./tested.log | sed "s| $latest||g;s|~||g" )
	if [[ ! -d ./Results/$tempseed/ ]]; then
		mkdir ./Results/$tempseed/
	fi	
	cp $dir/$crash ./Results/$tempseed/
	cp /var/www/files/$tempseed.* ./Results/$tempseed
else
	if [ "${#tested[$i]}" -ne 0 ]; then
		files=( "${files[@]}" "${tested[$i-1]}" )
	fi
fi
}

crashcount
crashcount1=$crashcount
if [[ $( ls $crashroot/ | grep -c "Latest" ) -ge 1 ]]; then
	rm $crashroot/Latest*.plist
fi
if [[ $( ls $crashroot/ | grep -c "Reset" ) -ge 1 ]]; then
	rm $crashroot/Reset*.plist
fi
if [[ $( ls $crashroot/ | grep -c "LowMemory" ) -ge 1 ]]; then
	rm $crashroot/LowMemory*.plist
fi
if [[ $( ls $crashroot/ | grep -c "LowBatteryLog" ) -ge 1 ]]; then
	rm $crashroot/LowBatteryLog*.plist
fi
crashcount
if [[ $(($crashcount1-$crashcount)) -ne 0 ]]; then
	echo "Removed $(($crashcount1-$crashcount)) garbage file(s)."
fi

if [ $crashcount -ge 1 ]; then
	echo "Crashes found!"
	echo "Finding files that caused crashes, please wait..."
fi

tested=( $( sed 's|.* ||g' ./tested.log ) )

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

if [ "${#files[@]}" -ge 1 ]; then
	for file in "${files[@]}"; do
		seeds=( "${seeds[@]}" $( grep $file ./tested.log | sed "s| $file||g;s|~||g" ) )
		sed -i "s|$file|$file\*|g" ./tested.log
	done
fi

crashcount
crashcount1=$crashcount
if [ $crashcount -ge 1 ]; then
	echo "You have $crashcount crash(es)."
	mv $crashroot/*.plist ./Crashes/
	crashcount
	echo "Moved $(($crashcount1-$crashcount)) crash(es) to ./Crashes/ for you to inspect."
	if [[ $crashcount1 -ne $(($crashcount1-$crashcount)) ]]; then
		echo "Not all files moved, look in $crashroot/ for the rest."
	fi
fi
panics1=$( ls $crashpanics | grep -c plist )
if [[ $panics1 -ge 1 ]]; then
	echo "You have $panics1 kernel panic(s)."
	mv $crashpanics/*.plist ./Crashes/Panics/
	panics=$( ls $crashpanics | grep -c plist )
	echo "Moved $(($panics1-$panics)) kernel panic(s) to ./Crashes/Panics/ for you to inspect."
	if [[ $panics1 -ne $(($panics1-$panics)) ]]; then
		echo "Not all files moved, look in $crashpanics/ for the rest."
	fi
fi

if [[ $( grep -c "No matching processes were found" ./fuzz.log ) -gt 0 ]]; then
	echo 'Found things in the logs indicating MobileSafari may have crashed.'
	safarifiles=$( grep 'No matching processes were found' -B 5 ./fuzz.log | grep '~' | sed "s| .*||g;s|~||g" )
	seeds=( "${seeds[@]}" "$safarifiles" )
	sed -i -r "s|~$safarifiles .*$|&\*|g" ./tested.log
	echo "Seeds which possibly caused MobileSafari crashes:"
	echo "${safarifiles[@]}"
fi

if [[ $notinfile -eq 1 ]]; then
	echo "Not all crashes were able to be paired up with seeds."
	echo "This is probably due to crashes that were in your CrashReporter directory prior to fuzzing."
	unpaired=( $( for crash in "${unpaired[@]}"; do echo "$crash"; done | sort -u ) )
	echo "Crashes which were unable to be paired with a seed:"
	for pairfail in "${unpaired[@]}"; do
		echo "$pairfail"
	done
fi

if [ "${#seeds[@]}" -ge 1 ]; then
	seeds=( $( for seed in "${seeds[@]}"; do echo "$seed"; done | sort -n -u ) )
	echo "Files/seeds which likely caused crashes, and are worth checking out:"
	for seed in "${seeds[@]}"; do
		echo "$seed"
	done
fi

if [ $( grep -c '1' ./fuzz.log ) -ge 1 ]; then
	mv ./fuzz.log ./logs/`date '+%y.%m.%d-%H.%M.%S'`.log
fi