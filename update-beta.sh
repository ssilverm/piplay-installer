#!/bin/bash
#if [ "$(id -u)" != "0" ]; then
#   echo "This script must be run like: sudo ./install.sh" 1>&2
#   exit 1
#fi

echo "Starting Update…"
VERSION=$(cat /home/pi/pimame/version )
echo "current version:"
echo $VERSION

sudo apt-get -y install bc

if [ $(echo $VERSION '<' "8.7" | bc -l) == 1 ]; then
    sudo apt-get -y -f install
    wget -N http://sheasilverman.com/rpi/raspbian/installer/vice_2.3.21-1_armhf.deb
    sudo dpkg -i vice_2.3.21-1_armhf.deb
    sudo apt-get -y install python-requests python vsftpd xboxdrv stella python-pip python-requests python-levenshtein libsdl1.2-dev
fi

cd ~/pimame
if [ $(echo $VERSION '==' "8.7" | bc -l) == 1 ]; then
  git fetch --all
  git reset --hard origin/master
fi
git config --global user.email "none@none.com"
git config --global user.name "none@none.com"
git pull
git submodule update --recursive
cd pimame-menu
#version 8 beta 4.1
git checkout master
git stash
git pull
git stash pop
git config --global --unset user.email
git config --global --unset user.name
cd ~/pimame

if [ $(echo $VERSION '<=' "8.6" | bc -l) == 1 ]; then
###mednafen
echo "Removing old version of mednafen..."
rm -rf /home/pi/pimame/emulators/mednafen
echo "Cloning new version of mednafen..."
git clone https://github.com/ssilverm/mednafen-dispmanx-sdl /home/pi/pimame/emulators/mednafen

###NES
wget http://pimame.org/8files/fceux.zip
mkdir /home/pi/pimame/emulators/fceux
mv fceux.zip /home/pi/pimame/emulators/fceux
cd /home/pi/pimame/emulators/fceux
unzip -o fceux.zip
rm fceux.zip
cd /home/pi/pimame

###dgen
rm -rf /home/pi/pimame/emulators/dgen-sdl-1.32
git clone https://github.com/ssilverm/dgen-sdl /home/pi/pimame/emulators/dgen-sdl-1.32
fi


if [ $(echo $VERSION '<' "8.7" | bc -l) == 1 ]; then
#8.8 / 8.0 beta 6
cd /home/pi/pimame/emulators/gpsp
ln -s /home/pi/pimame/roms/gba/gba_bios.bin gba_bios.bin
fi

if [ $(echo $VERSION '<' "9" | bc -l) == 1 ]; then #START 9
#8.8 / 8.0 beta 6
echo "Updating to 0.8 Beta 7"
sudo apt-get update
sudo apt-get install gunicorn 

if grep --quiet pimame-web-frontend /home/pi/.profile; then
        sed -i "s|sudo python /home/pi/pimame/pimame-web-frontend/app.py|cd /home/pi/pimame/pimame-web-frontend/; sudo gunicorn app:app -b 0.0.0.0:80|g" /home/pi/.profile
else
  echo "Did not change web frontend."
fi

fi #end 9

if [ $(echo $VERSION '<' "10" | bc -l) == 1 ]; then #START 10
sudo apt-get update
sudo apt-get -y upgrade
mkdir /home/pi/pimame/roms/zxspectrum
sudo pip install flask pyyaml flask-sqlalchemy flask-admin
fi #end 10

if [ $(echo $VERSION '<' "11" | bc -l) == 1 ]; then #START 11
sudo apt-get update
sudo apt-get -y install sqlite3 supervisor
sudo cp /home/pi/pimame/supervisor_scripts/file_watcher.conf /etc/supervisor/conf.d/file_watcher.conf
sudo cp /home/pi/pimame/supervisor_scripts/gunicorn.conf /etc/supervisor/conf.d/gunicorn.conf
#sudo cp /home/pi/pimame/supervisor_scripts/pimame_menu.conf /etc/supervisor/conf.d/pimame_menu.conf
sudo supervisorctl reload

LINE=$(grep -n  "DISPLAY" .profile | cut -f 1 -d ':')
LASTLINE=$((LINE+5))
sed -e "${LINE},${LASTLINE}d" /home/pi/.profile > /home/pi/profile.tmp && mv /home/pi/profile.tmp /home/pi/.profile

echo 'if [ "$DISPLAY" == "" ] && [ "$SSH_CLIENT" == "" ] && [ "$SSH_TTY" == "" ]; then' >> /home/pi/.profile

if grep --quiet /home/pi/pimame/pimame-menu /home/pi/.profile; then
  echo "menu already exists, ignoring."
else
        echo 'cd /home/pi/pimame/pimame-menu/' >> /home/pi/.profile
        echo 'python launchmenu.py' >> /home/pi/.profile
fi
echo 'fi' >> /home/pi/.profile


sudo pip install watchdog
cd /home/pi/pimame/emulators
rm -rf cavestory_rpi-master fba gpsp pcsx_rearmed usp_0.0.43 dgen-sdl-1.32 fceux mednafen pisnes
cd /home/pi/pimame/
git pull
git submodule init
git submodule update --recursive

cd /home/pi/pimame/emulators
git submodule init
git submodule update

sqlite3 /home/pi/pimame/pimame-menu/database/config.db "update menu_items set command = '/home/pi/pimame/emulators/scummvm/scummvm' where label = 'SCUMMVM'"
sqlite3 /home/pi/pimame/pimame-menu/database/config.db "update menu_items set command = 'python /home/pi/pimame/pimame-menu/scraper/scrape_script.py --ask True' where label = 'SCRAPER'"
sqlite3 /home/pi/pimame/pimame-menu/database/config.db "ALTER TABLE options ADD COLUMN roms_added INT DEFAULT 0"
sqlite3 /home/pi/pimame/pimame-menu/database/config.db "update menu_items set command = 'cd /home/pi/pimame/emulators/pcsx_rearmed && ./pcsx' WHERE label = 'Playstation 1'" 



fi #end 11


echo "You are now updated. Please restart to activate PiMAME :)"
