#!/bin/bash

#depends on:
#--------------->   com.innoying.sbutils bc lighttpd adv-cmds com.cameronfarzaneh.safariresetter curl wget coreutils
install()
{
	apt-get install com.innoying.sbutils bc lighttpd adv-cmds com.cameronfarzaneh.safariresetter curl wget coreutils
}
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

file=$1
time=11

#check for file in
if [[ -z $file ]]; then
	echo "You must provide a file as a parameter."
	echo "Usage: ./fuzzycactus.sh ./file.mov"
	exit
fi

extension=$( echo $file | sed 's|.*\.||g' )

if [[ ! -e $file ]]; then
	echo "The file you provided does not exist."
	echo "Please check your path and try again."
fi

if [[ ! -e ./tested.log ]]; then
	touch ./tested.log
fi
if [[ ! -d /var/www/files/ ]]; then
	mkdir -p /var/www/files/
fi

#check dependencies
depends=( "com.innoying.sbutils" "bc" "lighttpd" "adv-cmds" "com.cameronfarzaneh.safariresetter" "curl" "wget" "coreutils" "zzuf" )
checkdepends()
{
	hasdepends=1
	haszzuf=1
	for item in "${depends[@]}"; do
		if [ $( dpkg -l | grep -c $item ) -lt 1 ]; then
			echo "Missing '$item'"'!'
			hasdepends=0
			if [[ $item == "zzuf" ]]; then
				haszzuf=0
			fi
		fi
	done
}
checkdepends

#not all dependencies exist, try to get them
if [[ $hasdepends -eq 0 ]]; then
	echo "Not all dependencies were met."
	while(true)
	do
		echo "Would you like me to try installing them? (y/n)"
		read answer
		if [[ "$answer" == "n" ]]; then
				echo "To install most of the dependencies required, run the following as root:"
				echo "installpkgs"
				echo "If you're missing zzuf, get it at 'https://dl.dropboxusercontent.com/u/33697434/zzuf_0.13-1_iphoneos-arm.deb'."
				exit
		elif [[ "$answer" == "y" ]]; then
			if [[ $( whoami ) == "root" ]]; then
				if [[ $( dpkg -l | grep apt7 | grep tool | grep -c Debian ) -eq 1 ]]; then
					echo "Installing required installpkgs..."
					install
					if [ $haszzuf -eq 0 ]; then
						wget https://dl.dropboxusercontent.com/u/33697434/zzuf_0.13-1_iphoneos-arm.deb --no-check-certificate
						dpkg -i ./zzuf_0.13-1_iphoneos-arm.deb
						if [ $( dpkg -l | grep -c zzuf ) -ne 1 ]; then
							echo "Something went wrong with the install, please install zzuf manually or try again."
							exit
						else
							rm ./zzuf_0.13-1_iphoneos-arm.deb
						fi
					fi
					checkdepends
					if [ $hasdepends -eq 1 ]; then
						break
					else
						echo "Something went wrong with the install, please install the dependencies you're missing manually or try again."
					fi
				else
					echo "This script was unable to set up the required dependencies for you because you don't have apt7 installed."
					echo "Install 'APT 0.7 Strict' from Cydia, and try again."
				fi
			else
				echo "This script was unable to set up the required dependencies for you because you're not running this script as root."
			fi
			echo "To install most of the dependencies required, run the following as root:"
			echo "apt-get install com.innoying.sbutils bc lighttpd adv-cmds com.cameronfarzaneh.safariresetter curl"
			echo "If you're missing zzuf, find it on the googlez."
			exit
		else
		echo "Not a valid reponse; valid responses are 'y', or 'n'."
		fi
	done
fi

#check for server config
if [[ ! -e /private/etc/lighttpd.conf ]]; then
	echo "No lighttpd.conf file found in /private/etc/!"
	while (true);
	do
		echo "Would you like me to set one up for you? (y/n)"
		read answer
		if [[ $answer == "n" ]]; then
				echo "You'll need to set one up yourself then, see https://ghostbin.com/paste/28bx6 for an example."
				exit
		elif [[ $answer == "y" ]]; then
				echo "Setting up..."
				curl -# http://ghostbin.com/paste/28bx6/raw > /private/etc/lighttpd.conf
				sed -i 's/\r$//' /private/etc/lighttpd.conf
				if [[ ! -e /private/etc/lighttpd.conf ]]; then
					echo "Something went wrong while setting up the file, please set one up manually or try again."
					echo "See https://ghostbin.com/paste/28bx6 for an example."
					exit
				fi
				echo "Done"
				break
		else
				echo "Not a valid reponse; valid responses are 'y', or 'n'."
		fi
	done
fi

#check document-root in server config
if [[ $( grep server.document-root /private/etc/lighttpd.conf ) != 'server.document-root = "/var/www/"' ]]; then
	echo "You must have your document root set up in /var/www/"
	echo "Please modify your /private/etc/lighttpd.conf file accordingly."
	exit
fi

#start server
if [[ $( ps -ax | grep lighttpd | grep -c -v grep ) -lt 1 ]]; then
	echo "No server running, attempting to start server..."
	lighttpd -f /etc/lighttpd.conf
	echo -n "Starting server..."
	sleep 1
	if [[ $( ps -ax | grep lighttpd | grep -c -v grep ) -lt 1 ]]; then
		echo "Still no server running."
		exit
	else
		echo "Server started."
	fi
fi

j=1
k=1

#may not be necessary, but the idea is that as your device slows down from testing more files, it will add to the sleep time
slowdown()
{
	let j+=1
	if [ $j -ge 25 -a $( echo "$time < 15" | bc ) -eq 1 ]; then
		time=$( bc <<< "scale=1;$time+ 0.1" )
		let k+=1
		j=1
		echo "Time incremented"
	elif [ $j -ge 20 -a $( echo "$time >= 15" | bc ) -eq 1 ]; then
		let k+=1
		j=1
	fi
}

for (( i = 1; i < 10000; i++ )); do
	if [ $( grep -c "~$i " ./tested.log ) -lt 1 ]; then
		echo "~$i `date '+%y.%m.%d-%H.%M.%S'`"
		zzuf -c -r 0.0001:0.001 -s $i < $file > /var/www/files/"$i"."$extension"
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