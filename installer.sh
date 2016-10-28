#!/bin/bash
#if [ "$(id -u)" != "0" ]; then
#   echo "This script must be run like: sudo ./install.sh" 1>&2
#   exit 1
#fi

echo "Starting Install..."

sudo apt-get clean
sudo apt-get update
sudo apt-get -y install vsftpd xboxdrv stella python-pip python-requests python-levenshtein libsdl1.2-dev bc gunicorn sqlite3 python-pygame
cd /home/pi/
git clone https://github.com/ssilverm/pimame-8 pimame
cd pimame

git submodule init
git submodule update
sudo pip install flask pyyaml flask-sqlalchemy flask-admin watchdog
cp -r config/.advance/ ~/
sudo cp config/vsftpd.conf /etc/
sudo cp config/inittab /etc/

wget http://sheasilverman.com/rpi/raspbian/8/sdl2_2.0.1-1_armhf.deb
sudo dpkg --force-overwrite -i sdl2_2.0.1-1_armhf.deb
rm sdl2_2.0.1-1_armhf.deb

cd /home/pi/pimame/emulators
git submodule init
git submodule update


###xboxdriver
sudo apt-get -y install xboxdrv

####c64
wget http://sheasilverman.com/rpi/raspbian/installer/vice_2.3.21-1_armhf.deb
sudo dpkg -i vice_2.3.21-1_armhf.deb
rm -rf vice_2.3.21-1_armhf.deb




echo 'if [ "$DISPLAY" == "" ] && [ "$SSH_CLIENT" == "" ] && [ "$SSH_TTY" == "" ]; then' >> /home/pi/.profile

if grep --quiet /home/pi/pimame/pimame-menu /home/pi/.profile; then
  echo "menu already exists, ignoring."
else
	echo 'cd /home/pi/pimame/pimame-menu/' >> /home/pi/.profile
	echo 'python launchmenu.py' >> /home/pi/.profile
fi

echo 'fi' >> /home/pi/.profile

sudo apt-get -y install supervisor
sudo cp /home/pi/pimame/supervisor_scripts/file_watcher.conf /etc/supervisor/conf.d/file_watcher.conf
sudo cp /home/pi/pimame/supervisor_scripts/gunicorn.conf /etc/supervisor/conf.d/gunicorn.conf
#sudo cp /home/pi/pimame/supervisor_scripts/pimame_menu.conf /etc/supervisor/conf.d/pimame_menu.conf
sudo supervisorctl reload

sudo apt-get -y install sqlite3
sqlite3 /home/pi/pimame/pimame-menu/database/config.db "update menu_items set command = '/home/pi/pimame/emulators/scummvm/scummvm' where label = 'SCUMMVM'"
sqlite3 /home/pi/pimame/pimame-menu/database/config.db "update menu_items set command = 'python /home/pi/pimame/pimame-menu/scraper/scrape_script.py --ask True' where label = 'SCRAPER'"
sqlite3 /home/pi/pimame/pimame-menu/database/config.db "ALTER TABLE options ADD COLUMN roms_added INT DEFAULT 0"
sqlite3 /home/pi/pimame/pimame-menu/database/config.db "update menu_items set command = 'cd /home/pi/pimame/emulators/pcsx_rearmed && ./run_pcsx.sh' WHERE label = 'Playstation 1'" 

echo "Please restart to activate PiMAME :)"
