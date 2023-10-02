#!/bin/sh

echo " "
echo "   ########################################################"
echo "   ## Make sure you've got a stable Internet connection! ##"
echo "   ########################################################"
echo " "
read -p "Press [ENTER] to Continue ...or [ctrl+c] to exit"

# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

echo " "
echo "############################"
echo "### Klipper dependencies ###"
echo "############################"
echo " "

echo "Installing klipper dependencies..."

opkg update && opkg install git-http unzip htop gcc patch;

opkg install python3 python3-pip python3-cffi python3-dev python3-greenlet python3-jinja2 python3-markupsafe;
pip install --upgrade pip;
pip install python-can configparser

echo "Cloning 250k baud pyserial"
git clone https://github.com/pyserial/pyserial /root/pyserial;
cd /root/pyserial
python /root/pyserial/setup.py install;
cd /root/
rm -rf /root/pyserial;


echo " "
echo "##############################"
echo "### Moonraker dependencies ###"
echo "##############################"
echo " "


echo "Installing moonraker python3 packages..."
opkg install python3-tornado python3-pillow python3-distro python3-curl python3-zeroconf python3-paho-mqtt python3-yaml python3-requests ip-full libsodium --force-overwrite;

echo "Upgrading setuptools..."
pip install --upgrade setuptools;

echo "Installing pip3 packages..."
pip install pyserial-asyncio lmdb streaming-form-data inotify-simple libnacl preprocess-cancellation apprise ldap3 dbus-next;

#--use-pep517

echo " "
echo "###############"
echo "###  Nginx  ###"
echo "###############"
echo " "

echo "Installing nginx..."
opkg install nginx-ssl;

echo " "
echo "###############"
echo "### Klipper ###"
echo "###############"
echo " "

echo "Cloning Klipper..."
git clone https://github.com/KevinOConnor/klipper.git /root/klipper;

echo "Creating klipper service..."
wget https://raw.githubusercontent.com/ihrapsa/KlipperWrt/main/Services/klipper -P /etc/init.d/;
chmod 755 /etc/init.d/klipper;
/etc/init.d/klipper enable;

mkdir -p /root/printer_data/config;


echo " "
echo "#################"
echo "### Moonraker ###"
echo "#################"
echo " "

git clone https://github.com/Arksine/moonraker.git /root/moonraker;
git -C /root/moonraker checkout 06279d0e10ae4e0349f7b415756821d7ca38774b
wget https://raw.githubusercontent.com/ihrapsa/KlipperWrt/main/Services/moonraker -P /etc/init.d/
chmod 755 /etc/init.d/moonraker
/etc/init.d/moonraker enable
wget https://raw.githubusercontent.com/ihrapsa/KlipperWrt/main/nginx/upstreams.conf -P /etc/nginx/conf.d/
wget https://raw.githubusercontent.com/ihrapsa/KlipperWrt/main/nginx/common_vars.conf -P /etc/nginx/conf.d/
/etc/init.d/nginx enable


echo " "
echo "#################"
echo "###  Client   ###"
echo "#################"
echo " "

choose(){
	echo " "
	echo "Choose prefered Klipper client:"
	echo "  1) fluidd"
	echo "  2) Mainsail"
	echo "  3) Quit"
	echo " "
	read n
	case $n in
	  1) 
	   echo "You chose fluidd"
	   sleep 1
	   echo "Installing fluidd..."
	   sleep 1
	   echo " "
	   echo "***************************"
	   echo "**     Downloading...    **"
	   echo "***************************"
	   echo " "
	   mkdir /root/fluidd;
	   wget -q -O /root/fluidd/fluidd.zip https://github.com/cadriel/fluidd/releases/latest/download/fluidd.zip && unzip /root/fluidd/fluidd.zip -d /root/fluidd/ && rm /root/fluidd/fluidd.zip;
	   wget -q -O /root/printer_data/config/moonraker.conf https://raw.githubusercontent.com/ihrapsa/KlipperWrt/main/moonraker/fluidd_moonraker.conf;
	   wget -q -O /etc/nginx/conf.d/fluidd.conf https://raw.githubusercontent.com/ihrapsa/KlipperWrt/main/nginx/fluidd.conf;
     wget https://github.com/ihrapsa/KlipperWrt/raw/main/klipper_config/fluidd.cfg -P /root/printer_data/config/
     
	   
	   echo "***************************"
	   echo "**         Done!         **"
	   echo "***************************"
	   echo -ne '\n'
	   ;;
	  2) 
	   echo "You chose Mainsail"
	   echo "Installing Mainsail..."
	   echo " "
	   echo "***************************"
	   echo "**     Downloading...    **"
	   echo "***************************"
	   echo " "
	   mkdir /root/mainsail;
	   wget -q -O /root/mainsail/mainsail.zip https://github.com/mainsail-crew/mainsail/releases/latest/download/mainsail.zip && unzip /root/mainsail/mainsail.zip -d /root/mainsail/ && rm /root/mainsail/mainsail.zip;
	   wget -q -O /root/printer_data/config/moonraker.conf https://raw.githubusercontent.com/ihrapsa/KlipperWrt/main/moonraker/mainsail_moonraker.conf;
	   wget -q -O /etc/nginx/conf.d/mainsail.conf https://raw.githubusercontent.com/ihrapsa/KlipperWrt/main/nginx/mainsail.conf;
     wget https://github.com/ihrapsa/KlipperWrt/raw/main/klipper_config/mainsail.cfg -P /root/printer_data/config/
	   
	   echo "***************************"
	   echo "**         Done          **"
	   echo "***************************"
	   echo " "
	   ;;
	  3) 
	   echo "Quitting...";;
	  *) 
	   echo "invalid option";;
	esac
}

choose;

echo " "
echo "###################"
echo "### Hostname/ip ###"
echo "###################"
echo " "

echo "Using hostname instead of ip..."
opkg install avahi-daemon-service-ssh avahi-daemon-service-http;

opkg install wget-ssl;

rm -rf /tmp/opkg-lists 

echo " "
echo "########################"
echo "### tty hotplug rule ###"
echo "########################"
echo " "

echo "Install tty hotplug rule..."
opkg update && opkg install usbutils;
cat << "EOF" > /etc/hotplug.d/usb/22-tty-symlink
# Description: Action executed on boot (bind) and with the system on the fly
PRODID="1a86/7523/264" #change here according to "PRODUCT=" from grep command 
SYMLINK="ttyPrinter" #you can change this to whatever you want just don't use spaces. Use this inside printer.cfg as serial port path
if [ "${ACTION}" = "bind" ] ; then
  case "${PRODUCT}" in
    ${PRODID}) # mainboard product id prefix
      DEVICE_TTY="$(ls /sys/${DEVPATH}/tty*/tty/)"
      # Mainboard connected to USB1 slot
      if [ "${DEVICENAME}" = "1-1.4:1.0" ] ; then
        ln -s /dev/${DEVICE_TTY} /dev/${SYMLINK}
        logger -t hotplug "Symlink from /dev/${DEVICE_TTY} to /dev/${SYMLINK} created"

      # Mainboard connected to USB2 slot
      elif [ "${DEVICENAME}" = "1-1.2:1.0" ] ; then
        ln -s /dev/${DEVICE_TTY} /dev/${SYMLINK}
        logger -t hotplug "Symlink from /dev/${DEVICE_TTY} to /dev/${SYMLINK} created"
      fi
    ;;
  esac
fi
# Action to remove the symlinks
if [ "${ACTION}" = "remove" ]  ; then
  case "${PRODUCT}" in
    ${PRODID})  #mainboard product id prefix
     # Mainboard connected to USB1 slot
      if [ "${DEVICENAME}" = "1-1.4:1.0" ] ; then
        rm /dev/${SYMLINK}
        logger -t hotplug "Symlink /dev/${SYMLINK} removed"

      # Mainboard connected to USB2 slot
      elif [ "${DEVICENAME}" = "1-1.2:1.0" ] ; then
        rm /dev/${SYMLINK}
        logger -t hotplug "Symlink /dev/${SYMLINK} removed"
      fi
    ;;
  esac
fi
EOF

echo " "
echo "########################"
echo "###  Fixing logs...  ###"
echo "########################"
echo " "
echo "Creating system.log..."

uci set system.@system[0].log_file='/root/klipper_logs/system.log';
uci set system.@system[0].log_size='51200';
uci set system.@system[0].log_remote='0';
uci commit;

echo " "
echo "Installing logrotate..."
echo " "
opkg install logrotate;

echo " "
echo "Creating cron job..."
echo " "
echo "0 8 * * * *     /usr/sbin/logrotate /etc/logrotate.conf" >> /etc/crontabs/root


echo " "
echo "Creating logrotate configuration files..."
echo " "

cat << "EOF" > /etc/logrotate.d/klipper
/root/klipper_logs/klippy.log
{
    rotate 7
    daily
    maxsize 64M
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
}
EOF

cat << "EOF" > /etc/logrotate.d/moonraker
/root/klipper_logs/moonraker.log
{
    rotate 7
    daily
    maxsize 64M
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
}
EOF

echo " "
echo "#################"
echo "###   Done!   ###"
echo "#################"
echo " "

echo "Please reboot for changes to take effect...";
echo "...then proceed configuring your printer.cfg!";
