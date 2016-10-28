purple(){
	printf "\033[0;35m$@\033[0m\n"

}

turq(){
	printf "\033[0;36m$@\033[0m\n"

}

ipaddr=$(ip addr show | awk '$1 ~ /inet/ && $2 !~ /127.0.0|::1|fe80:/ {print $2}' |cut -d/ -f1 | head -1)

mgrctl="/usr/local/mgr5/sbin/mgrctl"
if [ $($mgrctl > /dev/null 2>&1 ; echo $?) = "1" ]; then
	mgr=$($mgrctl mgr | awk '/mgr/' | cut -d = -f2)	
	cd /usr/local/mgr5
	core="/usr/local/mgr5/bin/core"
fi

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
	turq "IP: $ipaddr"
	turq "OS: $osname"
if ! [ -z $mgr ]; then
	turq "$($core $mgr -i)"
	turq "$($core core -i)"
	turq "Repo: $reponame"
else
	turq "ISP panet not found"	
fi
purple "========"

