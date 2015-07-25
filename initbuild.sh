#!/bin/bash
#echo -e "\e[40;32;1m"
clear
username=`whoami`
thisDir=`pwd`
toolsDir=$thisDir/tools
logDir=$thisDir/logs

#Environment Tools
addRulesFunc(){
	read mIdVendor mIdProduct
	echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\""$mIdVendor"\", ATTR{idProduct}==\""$mIdProduct"\", MODE=\"0600\", OWNER=\"$username\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
	sudo /etc/init.d/udev restart
}

addRules(){
	clear
	lsusb
	echo -e "\nOK 上面列出了所有USB列表,大致内容如下:\n"
	echo -e "\033[40;37;7mBus 00x Device 00x: ID \033[40;34;7mxxxx\033[40;32;1m:\033[40;33;7mxxxx\033[40;30;0m \033[40;31;7mxxxxxxxxxxxxx\033[40;31;0m"
	echo -e "\e[40;32;1m"
	echo -e "如上，蓝色字符串为idVendor,黄色字符串为idProduct\n红色的是一些厂商信息(也可能没有)"
	echo -e "找第三个里面有没有你的手机厂商的名字,如:HUAWEI,ZTE 什么的"
	echo -e "当然没找到没关系,第三个什么都没有的就是了\n把idVendor和idProduct 打在下面,空格隔开,如:19d2 ffd0"
	echo -ne "\n输入:"
	addRulesFunc
	echo -e "添加成功"
}

installadbini(){
	echo -e "正在安装adb_usb.ini环境"
	cd $thisDir
	git clone https://github.com/GaHoKwan/adbusbini
	if [ "$?" -ne "0" ];then
		echo -e "下载环境配置文件错误，请检查错误！"
	else
		sudo rm -rf ~/.android
		sudo mv $thisDir/adbusbini ~/.android
	fi
}

installadb(){
	echo -e "\n配置adb环境变量..."
	sudo apt-get update
	sudo apt-get install android-tools-adb android-tools-fastboot
	installadbini
	curl https://raw.githubusercontent.com/GaHoKwan/Android-udev-rules/master/51-android.rules > $toolsDir/51-android.rules
	sudo cp $toolsDir/51-android.rules /etc/udev/rules.d/
	sudo chmod a+rx /etc/udev/rules.d/51-android.rules
	sudo /etc/init.d/udev restart
	echo "export PATH=$PATH:~/bin/" | sudo tee -a /etc/profile
	source /etc/profile
	sudo adb kill-server
	sudo adb devices
	echo "\n配置环境完成"
}

installia32(){
	if [ "$kind" == "1" ]; then
		sudo apt-get install ia32-libs
	elif [ "$kind" == "2" ]; then
#start
		cd /etc/apt/sources.list.d #进入apt源列表
		echo "deb http://old-releases.ubuntu.com/ubuntu/ raring main restricted universe multiverse" | sudo tee ia32-libs-raring.list
#添加ubuntu 13.04的源，因为13.10的后续版本废弃了ia32-libs
		sudo apt-get update #更新一下源
		if [ "$?" == "0" ]; then
			echo -e "下载完成"
			else
			echo -e "下载失败，正在重新尝试"
			sudo apt-get update
		fi
		sudo apt-get install ia32-libs #安装ia32-libs
		if [ "$?" == "0" ]; then
			echo -e "下载完成"
			else
			echo -e "下载失败，正在重新尝试"
			sudo apt-get install ia32-libs
		fi
		sudo rm ia32-libs-raring.list #恢复源
		sudo apt-get update #再次更新下源
#end
	else		
		kind=$(whiptail --backtitle "开始安卓开发环境..." --title "请选择使用的系统版本" --menu "请选择" 15 60 5 \
"1" "ubuntu 12.04 及以下(此项不安装编译环境）" \
"2" "ubuntu 14.04 以上及deepin等基于ubuntu14.04的系统" \
"3" "Linux mint 17(此项不安装ia32因为Mint系统自带）" \
"0" "离开脚本" 3>&1 1>&2 2>&3)
		case $kind in
			1)
				export kind=1
				installia32
			;;
			2)
				export kind=2
				installia32
			;;
			*)
				initSystemConfigure
			;;
		esac
	fi
}

initSystemConfigure(){
clear
configurechoose=$(whiptail --title "请输入你想安装的环境" --menu "请选择" 18 60 9 \
"1" "ia32运行库" \
"2" "JavaSE(Oracle Java JDK)" \
"3" "aosp&cm&recovery编译环境" \
"4" "adb运行环境"  \
"5" "AndroidSDK运行环境"  \
"6" "安卓开发必备环境(上面1234）"  \
"0" "离开" 3>&1 1>&2 2>&3)
case $configurechoose in
	1)
		installia32
		read -p "按回车键继续..."
		initSystemConfigure
	;;
	2)
		installJavaSE
		read -p "按回车键继续..."
		initSystemConfigure
	;;
	3)
		DevEnvSetup
		read -p "按回车键继续..."
		initSystemConfigure
	;;
	4)
		installadb
		read -p "按回车键继续..."
		initSystemConfigure
	;;
	5)
		installsdk
		initSystemConfigure
	;;
	6)
		kind=$(whiptail --backtitle "开始安卓开发环境..." --title "请选择使用的系统版本" --menu "请选择" 15 60 5 \
"1" "ubuntu 12.04 及以下(此项不安装编译环境）" \
"2" "ubuntu 14.04 以上及deepin等基于ubuntu14.04的系统" \
"3" "Linux mint 17(此项不安装ia32因为Mint系统自带）" \
"0" "离开脚本" 3>&1 1>&2 2>&3)
		case $kind in
			1)
					installrepo
					installia32
					installJavaSE
					installadb
					initSystemConfigure
			;;
			2)
					installrepo
					installia32
					installJavaSE
					installadb
					DevEnvSetup
					initSystemConfigure
			;;
			3)
					installrepo
					installJavaSE
					installadb
					DevEnvSetup
					initSystemConfigure
			;;
			*)
					initSystemConfigure
			;;
		esac
	;;
esac
}

installsdk(){
echo
echo "下载和配置 Android SDK!!"
echo "请确保 unzip 已经安装"
echo
sudo apt-get install unzip -y
if [ `getconf LONG_BIT` = "64" ];then
	echo
	echo "正在下载 Linux 64位 系统的Android SDK"
	wget http://dl.google.com/android/adt/adt-bundle-linux-x86_64-20140702.zip
	echo "下载完成!!"
	echo "展开文件"
	mkdir ~/adt-bundle
	mv adt-bundle-linux-x86_64-20140702.zip ~/adt-bundle/adt_x64.zip
	cd ~/adt-bundle
	unzip adt_x64.zip
	mv -f adt-bundle-linux-x86_64-20140702/* .
	echo "正在配置"
	echo -e '\n# Android tools\nexport PATH=${PATH}:~/adt-bundle/sdk/tools\nexport PATH=${PATH}:~/adt-bundle/sdk/platform-tools\nexport PATH=${PATH}:~/bin' >> ~/.bashrc
	echo -e '\nPATH="$HOME/adt-bundle/sdk/tools:$HOME/adt-bundle/sdk/platform-tools:$PATH"' >> ~/.profile
	echo "完成!!"
else
	echo
	echo "正在下载 Linux 32位 系统的Android SDK"
	wget http://dl.google.com/android/adt/adt-bundle-linux-x86-20140702.zip
	echo "下载完成!!"
	echo "展开文件"
	mkdir ~/adt-bundle
	mv adt-bundle-linux-x86-20140702.zip ~/adt-bundle/adt_x86.zip
	cd ~/adt-bundle
	unzip adt_x86.zip
	mv -f adt-bundle-linux-x86_64-20140702/* .
	echo "正在配置"
	echo -e '\n# Android tools\nexport PATH=${PATH}:~/adt-bundle/sdk/tools\nexport PATH=${PATH}:~/adt-bundle/sdk/platform-tools\nexport PATH=${PATH}:~/bin' >> ~/.bashrc
	echo -e '\nPATH="$HOME/adt-bundle/sdk/tools:$HOME/adt-bundle/sdk/platform-tools:$PATH"' >> ~/.profile
	echo "完成!!"
fi
rm -Rf ~/adt-bundle/adt-bundle-linux-x86_64-20140702
rm -Rf ~/adt-bundle/adt-bundle-linux-x86-20140702
rm -f ~/adt-bundle/adt_x64.zip
rm -f ~/adt-bundle/adt_x86.zip
read -p "按回车键继续..."
}

installkitchen(){
echo "安装安卓厨房"
		sudo apt-get install git -y
		cd ~/
		git clone https://github.com/kuairom/Android_Kitchen_cn
		if [ "$?" -ne "0" ];then
			read -p "安装失败，请检查报错信息，按回车键继续"
			main
		fi
		echo "安卓厨房已下载到主文件夹的Android_Kitchen_cn目录里！"
		cd $thisDir
		read -p "按回车键继续..."
}

installJavaSE(){
	sudo apt-get update
	echo -e "\n开始安装oracle java developement kit..."
	sleep 1
	sudo add-apt-repository ppa:webupd8team/java
	sudo apt-get update && sudo apt-get install oracle-java6-installer
	if [ "$?" == "0" ]; then
		echo -e "下载完成"
		else
		echo -e "下载失败，正在重新尝试"
		sudo apt-get install  openjdk-7-jdk
	fi
	echo -e "\n安装openjdk7..."
	sleep 1
	sudo apt-get install  openjdk-7-jdk
	if [ "$?" == "0" ]; then
		echo -e "下载完成"
		else
		echo -e "下载失败，正在重新尝试"
		sudo apt-get install  openjdk-7-jdk
	fi
	read -p "按回车键继续..."
	echo 'alias jar-switch="sudo update-alternatives --config jar"' | sudo tee -a ~/.bashrc
	echo -e "你可以使用jar-switch命令来切换jar版本"
	echo 'alias java-switch="sudo update-alternatives --config java"' | sudo tee -a ~/.bashrc
	echo 'alias javac-switch="sudo update-alternatives --config javac"' | sudo tee -a ~/.bashrc
	echo 'alias javah-switch="sudo update-alternatives --config javah"' | sudo tee -a ~/.bashrc
	echo 'alias javap-switch="sudo update-alternatives --config javap"' | sudo tee -a ~/.bashrc
	source ~/.bashrc
	echo -e "你可以使用java(c/h/p)-switch命令来切换java(c/h/p)版本"
}

DevEnvSetup(){
	echo -e "\n开始安装ROM编译环境..."
	sudo apt-get install bison ccache libc6 build-essential curl flex g++-multilib g++ gcc-multilib git-core gnupg gperf x11proto-core-dev tofrodos libx11-dev:i386 libgl1-mesa-dev libreadline6-dev:i386 libgl1-mesa-glx:i386 lib32ncurses5-dev libncurses5-dev:i386 lib32readLine-gplv2-dev lib32z1-dev libesd0-dev libncurses5-dev libsdl1.2-dev libwxgtk2.8-dev python-markdown libxml2 libxml2-utils lzop squashfs-tools xsltproc pngcrush schedtool zip zlib1g-dev:i386 zlib1g-dev	
	if [ "$?" == "0" ]; then
		echo -e "下载完成"
		else
		echo -e "下载失败，正在重新尝试"
		DevEnvSetup
	fi
	sudo ln -s /usr/lib/i386-linux-gnu/mesa/libGL.so.1 /usr/lib/i386-linux-gnu/libGL.so 
}

#Development tools
installrepo(){
	mkdir -p ~/bin
	curl https://raw.githubusercontent.com/FlymeOS/manifest/lollipop-5.0/repo > ~/bin/repo
 	chmod a+x ~/bin/repo
}

repoSource(){
	if [ ! -f ~/bin/repo ]; then
		installrepo
	fi
	clear
	sDir=$(dialog --backtitle "方向键上下选择,单击空格选择,双击空格进入目录,退格键返回上一层,回车键确认路径"  --title "输入存放源码的地址 "  --dselect ~/ 7 40 3>&1 1>&2 2>&3)
	cd ${sDir//\'//}
	echo -e "请稍等..."
	repo init -u https://github.com/FlymeOS/manifest.git -b lollipop-5.0
	repo sync -j4
	if [ "$?" == "0" ]; then
		echo -e "同步完成"
		else
		echo -e "同步失败，正在重新尝试"
		repo sync -j4
	fi
	cd $thisDir
	read -p "按回车键继续..."
}

fastrepoSource(){
	if [ ! -f ~/bin/repo ]; then
		installrepo
	fi
	clear
	sDir=$(dialog --backtitle "方向键上下选择,单击空格选择,双击空格进入目录,退格键返回上一层,回车键确认路径"  --title "输入存放源码的地址 "  --dselect ~/ 7 40 3>&1 1>&2 2>&3)
	cd ${sDir//\'//}
	echo -e "请稍等..."
	cd ${sDir//\'//}
	repo init --repo-url git://github.com/FlymeOS/repo.git -u https://github.com/FlymeOS/manifest.git -b lollipop-5.0 --no-repo-verify
	repo sync -c --no-clone-bundle -j4
	if [ "$?" == "0" ]; then
		echo -e "同步完成"
		else
		echo -e "同步失败，正在重新尝试"
		repo sync -c --no-clone-bundle -j4
	fi
		read -p "按回车键继续..."
	cd $thisDir
}

logcat(){
	source $toolsDir/logcat
}

screencap(){
shotcap=$(whiptail --title "截图工具" --menu "请选择" 20 60 10 \
"1" "截图" \
"2" "拉取截图" \
"3" "清理缓存" \
"0" "离开脚本" 3>&1 1>&2 2>&3)
case $shotcap in
	1)
		echo ">>> 正在获取截图..."
		source $toolsDir/cs
		adb shell mkdir -p /data/local/tmp/Screenshot
		adb shell 'screencap -p "/data/local/tmp/Screenshot/`date`.png"'
		if [ "$?" == "0" ]; then
			whiptail --title "提示" --msgbox "截图文件已经输出到/data/local/tmp/Screenshot." 10 60
		else
			whiptail --title "提示" --msgbox "截图错误，请检查adb是否正常工作." 10 60
		fi
		screencap
	;;
	2)
		mkdir $thisDir/Screenshot/
		source $toolsDir/cs
		adb pull "/data/local/tmp/Screenshot/" $thisDir/Screenshot/
		if [ "$?" == "0" ]; then
			whiptail --title "提示" --msgbox "截图文件已经输出到$thisDir/Screenshot." 10 60
		else
			whiptail --title "提示" --msgbox "输出错误，请检查adb是否正常工作." 10 60
		fi
		whiptail --title "提示" --msgbox "操作完成." 10 60
		main
	;;
	3)
		source $toolsDir/cs
		adb shell rm -rf /data/local/tmp/Screenshot
		whiptail --title "清理残留文件"  --yes-button "确定" --no-button "取消"  --yesno "是否清理残留文件？" 10 60
			if [ "$?" == "0" ]; then
				rm -rf $thisDir/Screenshot >/dev/null
				for i in {1..100} ;do echo $i;done | dialog --title \
"清理残留文件" --gauge "正在清理..." 8 30
			fi
		whiptail --title "提示" --msgbox "操作完成." 10 60
		main
	;;
	*)
	main
	;;
esac
}

zipcenop(){
	whiptail --title "这是刷机包或者apk&jar伪加密工具" --yes-button "加密" --no-button "解密" --yesno "请选择模式." 10 80
	if [ "$?" == "0" ]; then
		export cenopmode=1
	else
		export cenopmode=2
	fi
cenopfile=$(dialog --backtitle "方向键上下选择,单击空格选择,双击空格进入目录,退格键返回上一层,回车键确认路径"  --title "请把需要加密的刷机包或者apk&jar拖进来 "  --dselect / 7 40 3>&1 1>&2 2>&3)
case $cenopmode in
	1)
		java -jar $toolsDir/ZipCenOp.jar e ${cenopfile//\'//}	
		if [ "$?" == "0" ]; then
			whiptail --title "提示" --msgbox "加密错误，请检查文件路径是否正确." 10 60
		else
			whiptail --title "提示" --msgbox "加密完成." 10 60
		fi
	;;
	2)
		java -jar $toolsDir/ZipCenOp.jar r ${cenopfile//\'//}
		if [ "$?" == "0" ]; then
			whiptail --title "提示" --msgbox "解密错误，请检查文件路径是否正确." 10 60
		else
			whiptail --title "提示" --msgbox "解密完成." 10 60
		fi
	;;
	*)
		main
	;;
esac
}

clean(){
	cd $toolsDir
	rm -rf colored-adb-logcat.py 51-android.rules >/dev/null
	cd $thisDir
	for i in {1..100} ;do echo $i;done | dialog --title \
"清理环境文件" --gauge "正在清理..." 8 30
	whiptail --title "清理残留文件" --yesno "是否清理残留文件？" 10 60
	if [ "$?" == "0" ]; then
		rm -rf logs Screenshot >/dev/null
		for i in {1..100} ;do echo $i;done | dialog --title \
"清理残留文件" --gauge "正在清理..." 8 30
	else
		clear
	fi
	echo -e "\e[0m"
	exit
}

adbtools(){
adbtool=$(whiptail --title "Android Debug Bridge Tools" --menu "请选择" 14 60 6 \
"1" "使用root权限启动adb" \
"2" "重启到系统" \
"3" "重启到Recovery" \
"4" "重启到Download" \
"5" "重启到Bootloader(Fastboot)" \
"0" "离开脚本" 3>&1 1>&2 2>&3)
case $adbtool in
	1)
		echo -e "请稍等..."
		source $toolsDir/cs -s
		read -p "按回车键继续..."
		adbtools
	;;
	2)
		echo -e "请稍等..."
		source $toolsDir/cs -n
		source $toolsDir/sys
		read -p "按回车键继续..."
		adbtools
	;;
	3)
		echo -e "请稍等..."
		source $toolsDir/cs -n
		source $toolsDir/rec
		read -p "按回车键继续..."
		adbtools
	;;
	4)
		echo -e "请稍等..."
		source $toolsDir/cs -n
		source $toolsDir/dl
		read -p "按回车键继续..."
		adbtools
	;;
	5)
		echo -e "请稍等..."
		source $toolsDir/cs -n
		source $toolsDir/bl
		read -p "按回车键继续..."
		adbtools
	;;
	*)
	main
	;;
esac
}

devtools(){
tools=$(whiptail --title "Android开发工具" --menu "请选择" 12 60 4 \
"1" "伪加密工具" \
"2" "抓取log工具" \
"3" "手机截图" \
"0" "离开脚本" 3>&1 1>&2 2>&3)
case $tools in
	1)
		zipcenop
		devtools
	;;
	2)
		logcat
		devtools
	;;
	3)
		screencap
		devtools
	;;
	*)
	main
	;;
esac
}

ubtools(){
ubtool=$(whiptail --title "Ubuntu软件安装工具" --menu "请选择" 12 60 4 \
"1" "搜狗拼音输入法" \
"2" "WineQQ国际版" \
"0" "离开脚本" 3>&1 1>&2 2>&3)
case $ubtool in
	1)
		source $toolsDir/sogou
		ubtools
	;;
	2)
		kind=$(whiptail --backtitle "WineQQ国际版" --title "请选择使用的系统版本" --menu "请选择" 10 60 2 \
"1" "Ubuntu及其他" \
"2" "Linux deepin" 3>&1 1>&2 2>&3)
		case $kind in
			1)
				source $toolsDir/wineqq
			;;
			2)
				sudo apt-get update
				sudo apt-get install deepinwine-qqintl
			;;
		esac
		ubtools
	;;
	*)
	main
	;;
esac
}

main(){
clear 
inp=$(whiptail --backtitle "作者： 嘉豪仔_Kwan (QQ:625336209 微博：www.weibo.com/kwangaho)" --title "Android开发环境一键搭载脚本及开发工具-Flyme专版" --menu "请选择" 18 60 10 \
"1" "adb开发工具" \
"2" "Android开发工具"  \
"3" "Ubuntu软件安装工具"  \
"4" "设置环境变量" \
"5" "安装安卓厨房Android-Kitchen" \
"6" "依然无法识别手机？没关系，选这个"  \
"7" "同步源码"  \
"8" "快速同步源码(跳过谷歌认证)"  \
"0" "离开脚本" 3>&1 1>&2 2>&3)
case $inp in
	1)
		adbtools
	;;
	2)
		devtools
	;;
	3)
		ubtools
	;;
	4)
		initSystemConfigure
		main
	;;
	5)
		installkitchen
		main
	;;
	6)
		addRules
		main
	;;
	7)
		repoSource
		main
	;;
	8)
		fastrepoSource
		main
	;;
	0)
		clean
	;;
	*)
	main
	;;
esac
}

warning(){
	whiptail --title "警告" --yesno "本脚本仅适用于Ubuntu及各大Ubuntu发行版使用，并且建议在14.04LTS以上版本使用." 10 80
	if [ "$?" == "0" ]; then
		yourpassword=$(whiptail --title "Root" --passwordbox "请输入你的root密码." 10 60 3>&1 1>&2 2>&3)
		echo $yourpassword | sudo -S sudo echo -e "正在进入主界面..." 
		if [ "$?" -ne "0" ]; then
			warning
		fi
		main
	else
		exit
	fi
}
warning
