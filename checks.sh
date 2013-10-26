#!/bin/bash

installpkgs="apt-get install com.innoying.sbutils bc lighttpd adv-cmds com.cameronfarzaneh.safariresetter curl wget coreutils"
install()
{
             apt-get install com.innoying.sbutils bc lighttpd adv-cmds com.cameronfarzaneh.safariresetter curl wget coreutils
}

#make directories
if [[ ! -e ./tested.log ]]; then
	touch ./tested.log
fi
if [[ ! -d /private/var/www/files/ ]]; then
	mkdir -p /private/var/www/files/
fi
if [[ ! -d /private/var/www/ ]]; then
	mkdir -p /private/var/www/
fi
if [[ ! -d /private/var/log/lighttpd/ ]]; then
	mkdir /private/var/log/lighttpd/
fi

#check dependencies
depends=( "com.innoying.sbutils" "bc" "lighttpd" "adv-cmds" "com.cameronfarzaneh.safariresetter" "curl" "wget" "coreutils" "zzuf" )
checkdepends()
{
	hasdepends=1
	haszzuf=1
	for item in "${depends[@]}"; do
		if [[ "$item" == "coreutils" ]]; then
			amount=2
		else
			amount=1
		fi
		if [ $( dpkg -l | grep -c $item ) -lt $amount ]; then
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
				echo "$installpkgs"
				echo "If you're missing zzuf, get it at 'https://dl.dropboxusercontent.com/u/33697434/zzuf_0.13-1_iphoneos-arm.deb'."
				exit 1
		elif [[ "$answer" == "y" ]]; then
			if [[ ! -e /usr/bin/whoami ]]; then
				echo "Because you don't have coreutils, I can't tell if you're running this script as root."
				while (true);
				do
					echo "Are you running this script as root? (y/n)"
					echo "(If you aren't, the installation of missing dependencies will fail.)"
					read answer
					if [[ $answer == "n" ]]; then
							isroot=0
							break
					elif [[ $answer == "y" ]]; then
							isroot=2
							break
					else
							echo "Not a valid reponse; valid responses are 'y', or 'n'."
					fi
				done
			elif [[ $( whoami ) == "root" ]]; then
				isroot=1
			else
				isroot=0
			fi

			if [ $isroot -ge 1 ]; then
				if [[ $( dpkg -l | grep apt7 | grep tool | grep -c Debian ) -eq 1 ]]; then
					echo "Installing required installpkgs..."
					install
					if [ $haszzuf -eq 0 ]; then
						wget https://dl.dropboxusercontent.com/u/33697434/zzuf_0.13-1_iphoneos-arm.deb --no-check-certificate
						dpkg -i ./zzuf_0.13-1_iphoneos-arm.deb
						if [ $( dpkg -l | grep -c zzuf ) -ne 1 ]; then
							echo "Something went wrong with the install, please install zzuf manually or try again."
							exit 1
						else
							rm ./zzuf_0.13-1_iphoneos-arm.deb
						fi
					fi
					checkdepends
					if [ $hasdepends -eq 1 ]; then
						break
					else
						echo "Something went wrong with the install, please install the dependencies you're missing manually or try again."
						if [[ $isroot -eq 2 ]]; then
							echo "Sounds like you weren't actually root, please run this script again as root or complete setup manually."
						fi
					fi
				else
					echo "This script was unable to set up the required dependencies for you because you don't have apt7 installed."
					echo "Install 'APT 0.7 Strict' from Cydia, and try again."
				fi
			else
				echo "This script was unable to set up the required dependencies for you because you're not running this script as root."
				echo "Try running this script again as root, or complete the installation of missing dependencies manually."
			fi
			echo "To install most of the dependencies required, run the following as root:"
			echo "apt-get install com.innoying.sbutils bc lighttpd adv-cmds com.cameronfarzaneh.safariresetter curl wget coreutils"
			echo "If you're missing zzuf, you can get it here: https://dl.dropboxusercontent.com/u/33697434/zzuf_0.13-1_iphoneos-arm.deb."
			exit 1
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
				echo "You'll need to set one up yourself then, see https://ghostbin.com/paste/suk7q for an example."
				exit 1
		elif [[ $answer == "y" ]]; then
				echo "Setting up..."
				curl -# http://ghostbin.com/paste/suk7q/raw > /private/etc/lighttpd.conf
				sed -i 's|\r$||' /private/etc/lighttpd.conf
				if [[ ! -e /private/etc/lighttpd.conf ]]; then
					echo "Something went wrong while setting up the file, please set one up manually or try again."
					echo "See https://ghostbin.com/paste/suk7q for an example."
					exit 1
				fi
				echo "Done"
				break
		else
				echo "Not a valid reponse; valid responses are 'y', or 'n'."
		fi
	done
fi

#check document-root in server config
if [[ "$( grep server.document-root /private/etc/lighttpd.conf )" != 'server.document-root = "/var/www/" '* && "$( grep server.document-root /private/etc/lighttpd.conf )" != $( echo -e "server.document-root = \"/var/www/\"\n" ) ]]; then
	echo "You must have your document root set up in /private/var/www/"
	echo "Please modify your /private/etc/lighttpd.conf file accordingly."
	exit 1
fi

#check server port is 80
if [[ "$( grep server.port /private/etc/lighttpd.conf )" != "server.port = 80 "* && "$( grep server.port /private/etc/lighttpd.conf )" != $( echo -e "server.port = 80\n" ) ]]; then
	echo "You must have your server port set to 80."
	echo "Please modify your /private/etc/lighttpd.conf file accordingly."
	exit 1
fi

#start server
if [[ $( ps -ax | grep lighttpd | grep -c -v grep ) -lt 1 ]]; then
	echo "No server running, attempting to start server..."
	lighttpd -f /etc/lighttpd.conf
	echo -n "Starting server..."
	sleep 1
	if [[ $( ps -ax | grep lighttpd | grep -c -v grep ) -lt 1 ]]; then
		echo "Still no server running."
		exit 1
	else
		echo "Server started."
	fi
fi

#neuter crash reporting
if [ $( grep -c '^127.0.0.1       iphonesubmissions.apple.com$' /private/etc/hosts ) -lt 1 ]; then
	if [[ $(whoami) != "root" ]]; then
		echo "Run this script again with root access (this is only required once)."
		exit 1
	else
		echo "" >> /private/etc/hosts
		echo "#Begin fuzzycactus" >> /private/etc/hosts
		echo "127.0.0.1       iphonesubmissions.apple.com" >> /private/etc/hosts
		echo "#End fuzzycactus" >> /private/etc/hosts
	fi
fi

#check to see if fuzzycactus is already running
pnum=$( ps -ax | grep fuzzycactus | grep -c -v grep )
if [ $pnum -ge 4 ]; then
	echo "A fuzzycactus process is already running, please run 'stop'."
	exit 1
fi

exit 2