purple(){
	printf "\033[0;35m$@\033[0m\n"

}

turq(){
	printf "\033[0;36m$@\033[0m\n"

}

mgrctl="/usr/local/mgr5/sbin/mgrctl"
if [ $($mgrctl > /dev/null 2>&1 ; echo $?) = "1" ]; then
	mgr=$($mgrctl mgr | awk '/mgr/' | cut -d = -f2)	
	cd /usr/local/mgr5
	core="bin/core"
	
	if [ -f /etc/redhat-release ]; then
		osname=$(rpm -qf /etc/redhat-release)
		reponame=$(cat /etc/yum.repos.d/ispsystem.repo | awk '/name/ && !/#/' | cut -d - -f 2)
	elif [ -f /etc/debian_version ]; then
		osname=$(lsb_release -s -i -c -r | xargs echo |sed 's; ;-;g')-$(dpkg --print-architecture)
		reponame=$(cat /etc/apt/sources.list.d/ispsystem.list | awk '/ispsystem/{print $3}' | cut -d - -f 1)
	else
		osname="Unnamed"
	fi
	
	purple "========"
	turq "ОС: $osname"
	turq "$($core $mgr -i)"
	turq "$($core core -i)"
	turq "Репозиторий: $reponame"
	purple "========"

else
	purple "Сервак без панели ISP"
fi

