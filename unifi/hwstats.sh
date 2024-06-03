#!/bin/bash

# HWStats v1.00

# This script was designed by Ze'ev Schurmann.

# HWStats is a nifty little BASH script I put together to display:
# 1. Hostname
# 2. IP Address
# 3. Network Speed
# 4. Available Hard Drive Space
# 5. Device Temparture
# 6. CPU and Memory Utilization

# The information is displayed on the small 160x60 LCD screen. It also includes a 150 frame video to run when the device boots up.

# It is not ideal to run this script on stock standard CloudKeys. It is designed for CloudKeys that have been "owned". IE you have taken over the OS and removed UniFi OS and Apps all together.

# I would recommend that you either download the Ubuntu True Type Font and place it in the /usr/share/fonts/truetype/ubuntu/ folder. If you choose to use a different font, place it accordingly and update the $myfont variable at the top of the script.

# You will also need to install ImageMagick on the CloudKey.
#          # apt install imagemagick -y

# Copy the files hwstats.sh and the video folder to the folder /srv/hwstat/. Copy the file hwstats.service to the folder /lib/systemd/system/ and then enter the following:
#          # systemctl daemon-reload && systemctl enable hwstats.services

# Then you can reboot the CloudKey. The script has a 40 second delay. It takes approx. 40 seconds for the initial boot to complete. You can adjust this.

# Some of the code in the script comes from another BitBucket user: Daniel Quigley-Skillin

# You can view the code here https://bitbucket.org/dskillin/cloudkey-g2-display/src/main/

# Until I have confirmed what license he released his code under, please consider this code licensed under GPL3.

# You can obtain the latest version of HWStats from https://bitbucket.org/thisiszeev/hwstats/src/main/



#This variable is for switching between Hostname and IP Address.
cnt=0

#This variable is for deginined the font name.
myfont=NotoMono-Regular

#This variable is for placing the hostname in a pretty lowercase variable (Gotta love my OCD).
myhost=$HOSTNAME

#This variable is from the original script created by Daniel. It defines the device IP address.
myip=$(/sbin/ifconfig eth0 | /bin/sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

#Wait 10 seconds for device to boot before starting the script.
sleep 10s

#Play the 150 frame video at boot.
for ((a=1; a<151; a++))
do
	val=$(printf "%03d\n" $a)
	frame="/srv/hwstats/video/frame-"$val".png"
	ck-splash -s image -f $frame
	sleep 0.02s
done

#Hold the last frame for 5 seconds.
sleep 2s

#Find the current download and upload bytes.
nettemp=$( cat /proc/net/dev | grep eth0 )
read -a netstats <<< $nettemp
netdlold=${netstats[1]}
netulold=${netstats[9]}

#Script updates the display every 2.5 seconds, so we need to wait 2.5 seconds before we continue to create sufficent time delay between getting old bytes and new bytes.
sleep 2.5s

#Loop forever and ever and happily ever after.
while [ true ]
do

#Get MEM utilization. From the original script from Daniel.
	mempercent=$(/usr/bin/free -m | /usr/bin/awk 'NR==2{printf "%.1f%%\n", $3*100/$2 }')

#Get device temperature.
	cputemp=$( ubnt-systool cputemp )

#Get CPU Load
	cpuload=$( ubnt-systool cpuload )

#Update current download and upload bytes.
	nettemp=$( cat /proc/net/dev | grep eth0 )
	read -a netstats <<< $nettemp
	netdlnew=${netstats[1]}
	netulnew=${netstats[9]}

#Work the difference out in kilobits per second.
	netdlspeed=$(( (netdlnew-netdlold)/320 ))
	netulspeed=$(( (netulnew-netulold)/320 ))

#I used this for logging. Not vital for functionality.
	#datetime=$( date )
	#echo "$datetime,$cpuload,$cputemp,$mempercent,$netdlspeed,$netulspeed" >> hwstats.log

#Quick calculation to see if we can display speed in megabits rather than kilobits.
	if [ $netdlspeed -gt 1024 ]
	then
		netdlspeed=$(( (netdlnew-netdlold)/327680 ))
		netdlsymbol="Mbps"
	else
		netdlsymbol="Kbps"
	fi

	if [ $netulspeed -gt 1024 ]
	then
		netulspeed=$(( (netulnew-netulold)/327680 ))
		netulsymbol="Mbps"
	else
		netulsymbol="Kbps"
	fi

#Replace first byte count with second byte count so we can wash rinse repeat.
	netdlold=$netdlnew
	netulold=$netulnew

#Create a black png file using ImageMagick.
	convert -size 160x60 xc:black hwstats.png

#Top text will toggle between Hostname and IP Address.
	if [ $cnt == 1 ]
	then
		convert hwstats.png -gravity north -undercolor black -fill white -font $myfont -pointsize 14 -annotate +0+1 "$myhost" hwstats.png
		cnt=0
	else
		convert hwstats.png -gravity north -undercolor black -fill white -font $myfont -pointsize 14 -annotate +0+1 "$myip" hwstats.png
		((cnt++))
	fi

#Now fill in the rest of the data.
	convert hwstats.png -gravity south -undercolor black -fill white -font $myfont -pointsize 10 -annotate +0+30 "DL: $netdlspeed $netdlsymbol UL: $netulspeed $netulsymbol" hwstats.png
	convert hwstats.png -gravity south -undercolor black -fill white -font $myfont -pointsize 10 -annotate +0+15 "TEMP: $cputemp°" hwstats.png
	convert hwstats.png -gravity south -undercolor black -fill white -font $myfont -pointsize 10 -annotate +0+1 "CPU: $cpuload  MEM: $mempercent" hwstats.png

#Boom! Spit the png file out to the LCD.
	ck-splash -s image -f hwstats.png

#And wait...
	sleep 2.5s

done
