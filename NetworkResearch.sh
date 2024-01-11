#!/bin/bash

#Making a log to store data collection.
#Script will not make a new log file if one already exists.
function makelog
{

fileavailable=$(ls | grep nr.log | wc -l)
if [ $fileavailable -gt 0 ]

then

echo ' [#] Log file exists.'

else

touch nr.log
echo '[#] Log file created.'

fi
}
makelog


#Checking if relevant programs have been installed.
#tor
#sshpass
#nipe
#Using <dpkg -s> command will help check if package is installed.

function checkinstalled
{
torstatus=$(dpkg -s tor | grep Status | awk '{print $4}')
sshpassstatus=$(dpkg -s sshpass | grep Status | awk '{print $4}')
nipestatus=$(find -type d -name nipe | grep nipe | wc -l)

if [ $torstatus == installed ]
then
echo '[#] tor is already installed'
else 
echo '[#] installing tor'
sudo apt-get install tor
fi
if [ $sshpassstatus == installed ]
then
echo '[#] sshpass is already installed'
else
echo '[#] installing sshpass'
sudo apt-get install sshpass
fi

if [ $nipestatus -ge 1 ]
 then
    echo "[#] nipe is installed."
else
echo "[#] installing nipe.."
git clone https://github.com/htrgouvea/nipe && cd nipe
cpanm --installdeps .
cd ..
fi
}
checkinstalled


#Creating a function to SSH into a remote server if local server is spoofed.
#Run a Whois scan or a target domain through SSH and save contents into a file.
#Acquire saved files from remote server into local server.

# To get IP of local server 

myIP=$(curl -s ifconfig.io)

function main
{

#Look up the country of current IP address.

curl ifconfig.io
IPcountry=$(whois $myIP | grep -i country | head -n1 | awk '{print $2}')



#If country of current IP Address is in SG, script will automatically end.
#If IP Address is spoofed, server will prompt user for an IP, user and password of a server to ssh into.
#Server will also prompt for a target domain to do a Whois scan on.

if [ $IPcountry == SG ]

then
echo 'You current IP is not anonymous'
echo 'Please check that relevant tools have also been properly installed. Tor, nipe & sshpass.'
exit

else
echo "You are anonymous. Your spoofed country is $IPcountry"
sleep 5
echo "Enter Remote Server IP: "
read ubuntuIP
echo "Enter Remote Server User: "
read ubuntu_user
echo "Enter Remote Server Password: "
read -s ubuntu_pass
echo "Enter A Target Domain Or IP You Wish To Scan: "
read targetIP

#Nmap scan on remote server to check for open ports.

echo 'Searching for open ports on remote server.. '
sleep 3

nmap $ubuntuIP


echo '[#] You Are Currently Connecting To A Remote Server....'
sleep 3

#Showing the remote server's country and uptime.

countryserver=$(whois $ubuntuIP | grep -i country | head -n1)
serveruptime=$(uptime -p)


#Using sshpass command to ssh into requested server.

sshpass -p "$ubuntu_pass" ssh -t "$ubuntu_user@$ubuntuIP" '

echo '[#] You are successfully connected to remote server.'

echo 'Your IP Address is: $ubuntuIP' 
echo '$countryserver'
echo '$serveruptime'

echo '[#] Currently running Whois scan of target domain on remote server....'

sleep 3

whois '$targetIP' > whois.txt
'


#After Whois scan is done and saved into file, it will automatically exit from remote server.

sleep 5


#Server will now ftp into Ubuntu

echo 'Obtaining saved file from remote server..'

sleep 3

#Using wget syntax to aquire the saved text file in the remote server.


wget ftp://$ubuntuIP/whois.txt --ftp-user=$ubuntu_user --ftp-password=$ubuntu_pass 


echo 'Files have been succesfully saved into your current directory.'
ls
datetime=$(date)

#Date and time of Whois data for the target IP will be logged in nr.log file.
      
sudo echo "'$datetime' WHOIS data collected for $targetIP" >> nr.log

echo '[#] Activity have been successfully logged.'
fi

}
main
