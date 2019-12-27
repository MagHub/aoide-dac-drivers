#!/bin/bash
driver_version="4.19.86"
firmware_hash="b9ecbe8d0e3177afed08c54fc938938100a0b73f"
driver_path="/lib/modules/"$driver_version+"/kernel/sound/soc/bcm/aoide-dacii.ko"
driver_url="https://github.com/howardqiao/aoide-dac-drivers/raw/master/drivers/aoide_dac_"$driver_version".tar.gz"
driver_filename="aoide_dac_"$driver_version".tar.gz"
kernel_installed=1
driver_installed=1
driver_selected="none"
dtoverlay=""
dac_current="none"

function welcome(){
	echo "Welcome..."
}
function menu_show(){
	echo ""
	echo "Aoide driver installer"
	echo "-----------------------"
	echo "1) Aoide DAC II"
	echo "2) Aoide DAC Pro"
	echo "3) Aoide Digi Pro"
	echo "4) Aoide Zero DAC+"
	echo "5) Aoide Zero Digi+"
	echo ""
	echo "5) Exit"
	echo "-----------------------"
	echo "Enabled DAC:"$dac_current
	echo "-----------------------"
}
function kernel_check(){
	echo "Driver Version:"
	echo $driver_version
	driver_version_length=${#driver_version}
	kernel_version=$(uname -r)
	echo "Current Kernel Version:"
	echo $kernel_version
	kernel_compare=${kernel_version:0:$driver_version_length}
	# echo "Kernel Compare:"
	# echo $kernel_compare
	if [ "$driver_version" = "$kernel_compare" ]; then
		return 0
	else
		return 1
	fi
}
function kernel_install(){
	echo "Install Raspberry PI Kernel "$driver_version
	apt update
	apt install binutils curl
	curl -L --output /usr/bin/rpi-update https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update && sudo chmod +x /usr/bin/rpi-update
	UPDATE_SELF=0 SKIP_BACKUP=1 rpi-update $firmware_hash
}
function driver_check(){
	echo $driver_path
	if [ -f "$driver_path" ]; then
		return 0
	else
		return 1
	fi
}
function driver_install(){
	echo "Install Aoide DACs driver V"$driver_version
	cd /
	if [ -f "$driver_filename" ]; then
		rm $driver_filename
	fi
	#wget https://github.com/howardqiao/aoide-dac-drivers/raw/master/drivers/aoide_dac_$driver_version.tar.gz
	echo "Download driver($driver_version) now..."
	echo "URL:"$driver_url
	echo "FILENAME:"$driver_filename
	curl -L $driver_url -o $driver_filename --progress --retry 10 --retry-delay 10  --retry-max-time 100
	#wget $driver_url 
	if [ -f "$driver_filename" ]; then
		tar zxvf $driver_filename
		rm $driver_filename
		depmod -b / -a $driver_version+
		depmod -b / -a $driver_version-v7+
		depmod -b / -a $driver_version-v7l+
		depmod -b / -a $driver_version-v8+
		sync
	else
		echo "Download driver failed"
	fi
}
function driver_disable(){
	sed -i "s/audio=on/audio=off/" /boot/config.txt
	sed -i '/dtoverlay=aoide-dacii/d' /boot/config.txt
	sed -i '/dtoverlay=aoide-dacpro/d' /boot/config.txt
	sed -i '/dtoverlay=aoide-digipro/d' /boot/config.txt
	sed -i '/dtoverlay=aoide-zero-dacplus/d' /boot/config.txt
	sed -i '/dtoverlay=aoide-zero-digiplus/d' /boot/config.txt
	sed -i "s/audio=on/audio=off/" /DietPi/config.txt
	sed -i '/dtoverlay=aoide-dacii/d' /DietPi/config.txt
	sed -i '/dtoverlay=aoide-digipro/d' /DietPi/config.txt
	sed -i '/dtoverlay=aoide-zero-dacplus/d' /DietPi/config.txt
	sed -i '/dtoverlay=aoide-zero-digiplus/d' /DietPi/config.txt
}
function driver_enable(){

	kernel_check
	if [ $? -eq 1 ]; then
		kernel_install
	else
		echo "Kernel OK!"
	fi
	driver_check
	if [ $? -eq 1 ]; then
		driver_install
	else
		echo "Driver OK!"
	fi
	driver_disable
	echo "dtoverlay="$dtoverlay >> /boot/config.txt
	echo "dtoverlay="$dtoverlay >> /DietPi/config.txt
	read -p "You should reboot to enable the selected DAC(y/n)" b
	case $b in 
	y)
	reboot
	;;
	*)
	exit 1
	;;
	esac
}
if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi
welcome
while true
do
	menu_show
	read -p "Select your DAC:" driver_selected

	case $driver_selected in 
	1)
	echo "You selected Aoide DAC II"
	dtoverlay="aoide-dacii"
	driver_enable
	;;
	2)
	echo "You selected Aoide DAC Pro"
	dtoverlay="aoide-dacpro"
	driver_enable
	;;
	3)
	echo "You selected Aoide Digi Pro"
	dtoverlay="aoide-digipro"
	driver_enable
	;;
	4)
	echo "You selected Aoide Zero DAC+"
	dtoverlay="aoide-zero-dacplus"
	driver_enable
	;;
	5)
	echo "You selected Aoide Zero Digi+"
	dtoverlay="aoide-zero-digiplus"
	driver_enable
	;;
	6)
	exit 1
	;;
	esac
	
done

