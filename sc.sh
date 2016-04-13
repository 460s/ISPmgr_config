#!/bin/sh
# qq: d.syrovatskiy@ispsystem.com
# Спасибо, unstall.5.sh, ты меня многому научил

#подсветка
green(){
	printf "\033[32;1m$@\033[0m\n"

}

red(){
	printf "\033[31;1m$@\033[0m\n"

}

#детектим ОС
OSParams() { 
	if [ -f /etc/redhat-release ]; then
		ostype=centos
		osname=$(rpm -qf /etc/redhat-release)
	elif [ -f /etc/debian_version ]; then
		ostype=debian
		osname=$(lsb_release -s -i -c -r | xargs echo |sed 's; ;-;g')-$(dpkg --print-architecture)
		read osversion < /etc/debian_version  
		if [ "$(echo ${osversion} | cut -c 1)" = 8 ]; then
			osversion=jessie
		elif [ "$(echo ${osversion} | cut -c 1)" = 7 ]; then
			osversion=wheezy			
		fi
	else
		red "На данной ОС скрипт не работает"
		exit 0
	fi
}

#детектим ОС
MgrReload() { 
	#while killall core; do echo "yes"; done
	killall -9 core
	green "Панель перезапущена"
}

IpAddr(){
	ipaddr=$(ip addr show | awk '$1 ~ /inet/ && $2 !~ /127.0.0|::1|fe80:/ {print $2}' |cut -d/ -f1 | head -1)
	# Мир еще не готов к этому
	#if [ -z "$(curl lic.ispsystem.com/ispmgr.lic?ip=$ipaddr 2>/dev/null)" ]; then
	#	red "Лицензия отсутствует! Закажи на my.ispsystem.com"
	#fi
}

IpAddr
OSParams
	
#парсим аргументы
if ! [ -z $1 ]
then
	case "${1}" in
		1) select=inst; instv=5 ;;
		2) select=update ;;
		3) select=debug ;;
		4) select=mtest ;;
		5) select=inst; instv=4 ;;
		6) select=otherinst ;;
		*) red "Неверный аргумент";; 
	esac
else
	echo
	green $osname
	green "Выберите необходимое действие:"
	while [ -z $select ]
	do
		echo "1) Wget install.5.sh"
		echo "2) Обновиться из репозитория"
		echo "3) Установить debug.conf"
		echo "4) Включить магнитофон"
		echo "5) Wget install.4.sh"
		echo "6) Установить наш billmgr"
		echo

		read -p "Что будем делать: " n
		echo

		case "$n" in
			1) select=inst; instv=5 ;;
			2) select=update ;;
			3) select=debug ;;
			4) select=mtest ;;
			5) select=inst; instv=4 ;;
			6) select=otherinst ;;
			*) ;;
		esac
	done
fi

case "$select" in
	inst) 
		if [ -f install.$instv.sh ]; then
			red "Файл install.$instv.sh уже cуществует, запускаем"
			sh install.5.sh
		else
			if wget http://cdn.ispsystem.com/install.$instv.sh > /dev/null 2>&1
			then
				green "Файл install.$instv.sh загружен, запускаем"
				sh install.$instv.sh
				case "$ostype" in
        			centos)
					if ! rpm -q nano > /dev/null; then
						yum -y install nano
					fi
				;;
				debian)
					apt-get -y install nano
				;;
				*);;
				esac
				green "nano установлен"
			else
				red "Файл install.$instv.sh не загружен"
			fi
		fi	 
	;;
	update)
		#Получаем имя репозитория
		#Обновляемся из текущего репа или из введенного user'ом
		if [ $ostype = "debian" ]; then
			reponame=$(cat /etc/apt/sources.list.d/ispsystem.list | awk '/ispsystem/{print $3}' | cut -d - -f 1)
		elif [ $ostype = "centos" ]; then
			reponame=$(cat /etc/yum.repos.d/ispsystem.repo | awk '/name/ && !/#/' | cut -d - -f 2)
		fi
		
		printf "Произойдет обновление из \033[32;1m$reponame\033[0m\n"
		echo "Нажмите Enter для обновления из $reponame или введите имя нового репозитория"
		read answer
		if [ -n "$answer" ]; then
	                reponame=$answer
	    fi

		case "$ostype" in
        centos)
			rm -f /etc/yum.repos.d/ispsystem.repo #долго подключается к download
			wget -O /etc/yum.repos.d/ispsystem.repo "http://intrepo.download.ispsystem.com/repo/centos/ispsystem-template.repo" && sed -i -r "s/TYPE/$reponame/g" /etc/yum.repos.d/ispsystem.repo
			yum clean metadata
			yum clean all
			yum -y update			
		;;
		debian)
			rm -f /etc/apt/sources.list.d/ispsystem.list
			echo "deb http://intrepo.download.ispsystem.com/repo/debian $reponame-$osversion main" > /etc/apt/sources.list.d/ispsystem.list
			apt-get update # проверить надо ли -у
			apt-get -y dist-upgrade
		;;
		*);;
		esac
	;;
	debug)
		if [ -f /usr/local/mgr5/etc/debug.conf ]; then
			green "Конфиг какого manager необходим?:"
			echo $debugconf
			while [ -z "$debugconf" ]
			do
				echo "1) ISPmanager"
				echo "2) BILLmanager"
				echo

				read -p "Что будем делать: " n
				echo

				case "$n" in
					1) 
						debugconf="* 9\n*.conn 4\n*.cache 4\n*.longtask 4\n*.cache 4\n*.sprite 4\n*.merge 4\n*.config 4\n*.stdconfig 4\n*.xml 4\n*.action 4\n*.period 4\n*.libmgr 4\n*.core_decoration 4\n*.output 4"
					;;
					2) 
						debugconf="* 6\n*.db 6\n*.core 4\n*.conn 4\n*.merge 4\n*.xmli 4\n*.cache 4\n*.longtask 4" 				
					;;
					*) ;;
				esac
			done
			echo -e "$debugconf" > /usr/local/mgr5/etc/debug.conf
			green "Файл debug.conf изменен" 
			MgrReload
		else
			red "Файл debug.conf не существует"
		fi
	;;
	mtest)
		if [ -f /usr/local/mgr5/etc/ispmgr.conf ]; then
			echo "Option TestMode" >> /usr/local/mgr5/etc/ispmgr.conf
			MgrReload
			green "Option TestMode добавлена" 
		else
			red "Файл etc/ispmgr.conf не существует"
		fi
	;;
	otherinst)
		echo "Введите имя репозитория для установки Billmgr"
		read reponame

		case "$ostype" in
        centos)
			rm -f /etc/yum.repos.d/ispsystem.repo 
			wget -O /etc/yum.repos.d/ispsystem.repo "http://intrepo.download.ispsystem.com/repo/centos/ispsystem-template.repo" && sed -i -r "s/TYPE/$reponame/g" /etc/yum.repos.d/ispsystem.repo
			yum clean metadata
			yum clean all
			yum -y install billmanager			
		;;
		debian)
			rm -f /etc/apt/sources.list.d/ispsystem.list
			echo "deb http://intrepo.download.ispsystem.com/repo/debian $reponame-$osversion main" > /etc/apt/sources.list.d/ispsystem.list
			apt-get update 
			apt-get -y install billmanager
		;;
		*);;
		esac
	;;
	*) ;;
esac



