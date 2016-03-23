#!/bin/sh
# v 0.81

#подсветка
green(){
	printf "\033[32;1m$@\033[0m\n"

}
red(){
	printf "\033[31;1m$@\033[0m\n"

}

#парсим аргументы
if ! [ -z $1 ]
then
	case "${1}" in
		1) select=inst ;;
		2) select=debug ;;
		3) select=test ;;
		*) red "Неверный аргумент";; 
	esac
else
	while [ -z $select ]
	do
		echo "1) Wget install.5.sh"
		echo "2) Установить debug.conf"
		echo "3) Включить тесты"
		echo

		read -p "Что будем делать: " n
		echo

		case "$n" in
			1) select=inst ;;
			2) select=debug ;;
			3) select=test ;;
			*) ;;
		esac
	done
fi

case "$select" in
	inst) 
		if [ -f install.5.sh ]
		then
			red "Файл install.5.sh уже cуществует, запускаем"
			sh install.5.sh
		else
			if wget http://cdn.ispsystem.com/install.5.sh > /dev/null 2>&1
			then
				green "Файл install.5.sh загружен, запускаем"
				sh install.5.sh
			else
				red "Файл install.5.sh не загружен"
			fi
		fi	 
	;;
	debug)
		if [ -f /usr/local/mgr5/etc/debug.conf ]
		then
			echo -e "* 9\n*.conn 4\n*.cache 4\n*.longtask 4\n*.cache 4\n*.sprite 4\n*.merge 4\n*.config 4\n*.stdconfig 4\n*.xml 4\n*.action 4\n*.period 4\n*.libmgr 4\n*.core_decoration 4\n*.output 4" > /usr/local/mgr5/etc/debug.conf
			green "Файл debug.conf изменен" 
		else
			red "Файл debug.conf не существует"
		fi
	;;
	test)
		if [ -f /usr/local/mgr5/etc/ispmgr.conf ]
		then
			echo "Option TestMode" >> /usr/local/mgr5/etc/ispmgr.conf
			green "Option TestMode добавлена" 
		else
			red "Файл etc/ispmgr.conf не существует"
		fi
	;;
	*) ;;
esac



