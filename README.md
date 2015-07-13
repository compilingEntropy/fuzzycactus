fuzzycactus
===========

A tool which automates and simplifies the on-device fuzzing of MobileSafari.

What it does:  
This tool can turn anyone's freshly jailbroken device into a fuzzing machine in minutes. All the setup is handled for you.

How it works:  
It uses zzuf to take the input file and generate a slightly modified version of it. It then attempts to load that modified file with MobileSafari. It does this repeatedly without any user interaction; the idea is you can start it and when you come back you'll have some crashes to play with.  
fuzzycactus continually pairs crashes with the files that caused them. The paired files and crashes are found in /private/var/fuzzycactus/Results/. Previously, fuzzycactus would inform you if there were crashes that could not be paired with their respective files. This behavior has been depreciated because pairing is now completely reliable. If your device had a kernel panic while fuzzing, fuzzycactus will pair the crash the next time iOS boots. No user actions are required for this to take place.  
This tool is designed to be run over ssh. Fuzzing is daemonized, so you can safely ctrl+c and disconnect your ssh session without fear of interrupting your fuzzing. If you choose to start this tool via MobileTerminal, stop the script by doing a 'slide-to-power-off' or ssh in and stop normally.
Part of the way this works involves running a local web-server on your device. This is useful because if you want to test a juicy file on another device, you can easily connect to your fuzzycactus device over a local network and do so. This is particularly useful for non-jailbroken devices, which can be a little tricky to load files onto.

Do not touch your device while it is fuzzing. This can cause false positives with the
crash-detector or other issues.

Always remember: Before you begin fuzzing, go to 'Settings' > 'General' > 'About' > 'Diagnostics & Usage' and check the "Don't Send" option. Otherwise, all your hard work will go to Apple and you will be sad. =(

Usage:  
`fuzzycactus [action] [file] [options]`  
`fuzzycactus [start/stop/watch/update/help] [./file.mov] [-s] [-t 11] [-r 0.0001:0.001] [-k]`  
For more usage information, please do `fuzzycactus help` and read the help text.

Installation:  
The preferred installation method is to add the following repo to Cydia, and install the fuzzycactus package:
`http://tihmstar.net/repo`  
Alternatively, you can install by running the following commands on your device:  
```
curl -k https://raw.githubusercontent.com/compilingEntropy/fuzzycactus/master/fuzzycactus > /usr/bin/fuzzycactus
chmod +x /usr/bin/fuzzycactus
```