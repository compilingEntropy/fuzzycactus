fuzzycactus
===========

A tool which automates and simplifies the on-device fuzzing of MobileSafari.

How it works:
This tool can turn anyone's freshly jailbroken device into a fuzzing machine in minutes. All the setup is handled for you.

It uses zzuf to take the input file and generate a slightly modified version of it. It then attempts to load that modified file with MobileSafari. It does this repeatedly without any user interaction; the idea is you can start it and when you come back you'll have some crashes to play with. 
The ./crashclean.sh file is automatically run after every fuzzing session. It will remove uninteresting things like ResetCounter and let you focus on the important stuff. It checks the time of each crash against the log files that are generated when fuzzycactus is running, and pairs each crash with the file that caused it. These pairs are put into the ./Results/ directory. Afterward, all crashes are moved to the ./Crashes/ directory for easy access. It will look at what seeds caused crashes and make note in the ./tested.log file as well, so it's easy to find. These seeds are then given you you in a list.
All of this runs on the device itself. No network connection is required during the fuzzing process. You should, however, start and stop the script over ssh (rather than mobileterminal) to avoid confusing the device as it does its work. Once the script is started you can safely disconnect.
Part of the way this works involves running a local server on your device. This is useful because if you want to test a juicy file on another device, you can easily connect to your fuzzycactus device over a local network and do so. This is particularly useful for non-jailbroken devices, which can be a little tricky to load files onto.

Always remember: Before you begin fuzzing, go to 'Settings' > 'General' > 'About' > 'Diagnostics & Usage' and check the "Don't Send" option. Otherwise, all your hard work will go to Apple and you will be sad. =(

Usage:
To start fuzzing ./file.mov, do:
	fuzzycactus start ./file.mov
To stop fuzzing, do:
	fuzzycactus stop
For help, do:
	fuzzycactus help