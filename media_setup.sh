#!/bin/bash
# ZSEC Media Server Setup
# This is a script to automate(to an extent), the creation of a media server on Debian
# The Script must be run as root ideally, this should not be deployed to the naked internet...
# I built it for HOME use behind a decent firewall setup.
# It is a creation from various guides for setup
#
# Note: This has been created alongside a blog post; https://blog.zsec.uk
#  __    __  ________  _______    ______            
# /  |  /  |/        |/       \  /      \           
# $$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |          
# $$ |__$$ |   $$ |   $$ |__$$ |$$ |  $$/           
# $$    $$ |   $$ |   $$    $$/ $$ |                
# $$$$$$$$ |   $$ |   $$$$$$$/  $$ |   __           
# $$ |  $$ |   $$ |   $$ |      $$ \__/  |          
# $$ |  $$ |   $$ |   $$ |      $$    $$/           
# $$/   $$/    $$/    $$/        $$$$$$/            
#                                                   
#                                                   
#                                                   
#   ______               __                         
#  /      \             /  |                        
# /$$$$$$  |  ______   _$$ |_    __    __   ______  
# $$ \__$$/  /      \ / $$   |  /  |  /  | /      \ 
# $$      \ /$$$$$$  |$$$$$$/   $$ |  $$ |/$$$$$$  |
#  $$$$$$  |$$    $$ |  $$ | __ $$ |  $$ |$$ |  $$ |
# /  \__$$ |$$$$$$$$/   $$ |/  |$$ \__$$ |$$ |__$$ |
# $$    $$/ $$       |  $$  $$/ $$    $$/ $$    $$/ 
#  $$$$$$/   $$$$$$$/    $$$$/   $$$$$$/  $$$$$$$/  
#                                         $$ |      
#                                         $$ |      
#                                         $$/       


# Declare Colours, Make things pretty


b='\033[1m'
u='\033[4m'
r='\E[31m'
g='\E[32m'
y='\E[33m'
m='\E[35m'
c='\E[36m'
w='\E[37m'
endc='\E[0m'
enda='\033[0m'

root_check() {
if [[ $EUID -ne 0 ]]; then
                echo -e "${r} [!] Please Note: This script must be run as root!${endc}"
                exit 1
        fi
echo -e " Checking For Root or Sudo: ${g}G0t r00t${endc}"
}

# Run the root check!
root_check

# Got to ask the user if they're still happy to run said script
# If you're deploying you can comment out the function below
read -p "[!] You have selected to run $0. Do you want to continue? [Y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

# Update the OS First
echo -n "[+] Do you want to update the OS or skip? (y/n)? "
old_stty_cfg=$(stty -g)
stty raw -echo
answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg
if echo "$answer" | grep -iq "^y" ;then
    apt update
	apt upgrade -y  
else
    echo
        echo -e  "[-] ${r}Skipped...  ${enda}"
fi

# Setup core utils

echo -e "[+] ${g}Do you want to install core utils?${endc} (y/n)" 
old_stty_cfg=$(stty -g)
stty raw -echo
answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg
if echo "$answer" | grep -iq "^y" ; then
        apt install byobu sudo apache2 nano screenfetch wget curl net-tools
else
	echo
        echo  -e "[-] ${r}Skipped... ${enda}"
fi


# Download the Files We need
# Be sure to grab the latest version of plex
# Create an accoutn on plex.tv and navigate to downloads
echo -e  "[+] ${g}Installing Plex...  ${enda}"
cd /tmp
wget https://downloads.plex.tv/plex-media-server/1.13.0.5023-31d3c0c65/plexmediaserver_1.13.0.5023-31d3c0c65_amd64.deb -O plex.deb
dpkg -i plex.deb

# Install Transmission
# Installs the files & creates the users
apt install transmission-cli transmission-common transmission-daemon
usermod -a -G debian-transmission user

# Change /mnt/Media to wherever your files are going to be stored
# sudo chgrp -R debian-transmission /mnt/Media
# sudo chmod -R 775  /mnt/Media

# Edit the commands commented out to include userpaths
echo "alias transstop='sudo service transmission-daemon stop'" >> /home/user/.bashrc
echo "alias transstart='sudo service transmission-daemon start'" >>  /home/user/.bashrc
echo "alias transreload='sudo service transmission-daemon reload'" >>  /home/user/.bashrc

# Setup the Daemon and config files
cd /etc/transmission-daemon
sudo cp -a settings.json settings.json.default
mkdir /home/user/.config/transmission-daemon
sudo cp -a /etc/transmission-daemon/settings.json transmission-daemon/
sudo chgrp -R debian-transmission /home/user/.config/transmission-daemon
sudo chmod -R 770 /home/user/.config/transmission-daemon
cd /etc/transmission-daemon
sudo rm settings.json 
sudo ln -s /home/user/.config/transmission-daemon/settings.json settings.json
sudo chgrp -R debian-transmission /etc/transmission-daemon/settings.json
sudo chmod -R 770 /etc/transmission-daemon/settings.json

# Edit Transmission Configuration Files
# "download-dir": "/path/to/downloads/folder",
# ...
# "incomplete-dir": "/path/to/incomplete/folder",
# "incomplete-dir-enabled": true,
# ...
# "rpc-authentication-required": true,
# "rpc-bind-address": "0.0.0.0",
# "rpc-enabled": true,
# "rpc-password": "password",
# "rpc-port": 9091,
# "rpc-username": "username",
# "rpc-whitelist": "127.0.0.1,*.*.*.*",
# "rpc-whitelist-enabled": true,
# ...
# "umask": 2,
# ...
# "watch-dir": "/mnt/Media/downloads",
# "watch-dir-enabled": true
# The default rpc-username and password is â€œtransmissionâ€.


# Install Mono
# Mono is used to run Radarr, Sonarr & Jackett
echo -e  "[+] ${g}Installing Mono...  ${enda}"
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/ubuntu xenial main" | sudo tee /etc/apt/sources.list.d/mono-official.list
sudo apt-get update
sudo apt-get install mono-complete libmono-cil-dev -y

# Grab Radarr & Sonarr 
#read -p "[!] The next step is going to install Radarr & Sonarr are you happy to cont? [Y/N] " -n 1 -r
#echo
#if [[ ! $REPLY =~ ^[Yy]$ ]]
#then
#    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
#fi

# Sonarr
echo -e  "[+] ${g}Installing Sonarr...  ${enda}"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC
sudo echo "deb http://apt.sonarr.tv/ master main" | sudo tee /etc/apt/sources.list.d/sonarr.list
apt update
apt install nzbdrone -y

# Radarr
# Install dependencies
apt install mediainfo -y

# Grab Radarr from Source
echo -e  "[+] ${g}Installing Radarr...  ${enda}"
cd /opt
wget $( curl -s https://api.github.com/repos/Radarr/Radarr/releases | grep linux.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4 )
tar -xvzf Radarr.develop.*.linux.tar.gz

# Install Jackett
echo -e  "[+] ${g}Installing Jackett...  ${enda}"
cd /opt
git clone https://github.com/Jackett/Jackett.git

# Install Cockpit Dashboard(optional)
echo -e "[+] ${g}[+] Do you want to install cockpit(http://cockpit-project.org)? ${endc} (y/n)" 
old_stty_cfg=$(stty -g)
stty raw -echo
answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg
if echo "$answer" | grep -iq "^y" ; then
        echo 'deb http://deb.debian.org/debian stretch-backports main' > /etc/apt/sources.list.d/backports.list
	apt-get update
	apt install cockpit
else
        echo
        echo  -e "[-] ${r}Skipped... ${enda}"
fi


echo -e "[!] ${b} Media Apps Install Complete"

# Creation of Dashboard in HTML, downloads from a gist
# All you need to do is grab your IP and change it in the sed command to make the dashboard work

echo -e "[+] ${g}Do you want to create a HTML Dashboard for launching various applications? ${endc} (y/n)" 
old_stty_cfg=$(stty -g)
stty raw -echo
answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg
if echo "$answer" | grep -iq "^y" ; then

		echo -e "[+] ${g}Creating Dashboard...${enda}"
		wget https://gist.githubusercontent.com/ZephrFish/6e998b7244e83f6ec63bbb65326bd670/raw/af9b47c76f00dafa19ff8c701487b8c239aac534/MediaDash.html -O /var/www/html/index.html
		echo -e "[!] Your IP Address is ${g} $( ifconfig | grep "inet " | cut -d "t" -f 2 | cut -d "n" -f 1 | sed -e 1b -e '$!d' | grep -v "127.0.0.1") ${enda}"
		echo "Enter this into your HTML page by using the command:  sed -i 's/media.zlocal/YOURIPHERE/g' "
else
        echo
        echo  -e "[-] ${r}Skipped... Install Completed!!! ${enda}"
fi


echo  -e "[-] ${g}Install Completed!!! ${enda}"
