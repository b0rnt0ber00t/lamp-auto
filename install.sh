#!/bin/bash

# LAMPP AUTO INSTALLER
# @ Author -> b0rnt0ber00t

# color
l_red='\033[0;91m'
l_green='\033[0;92m'
l_yello='\033[0;93m'
l_blue='\033[0;94m'
l_magenta='\033[0;95m'
l_cyan='\033[0;96m'
N='\033[00m'

# check root user
if [[ $(id -u) == 0 ]];
    then
        sleep 0.1
    else
        echo -e $l_red"please run $(basename $0) as administrator (su or sudo)$N"
        exit
fi

clear

# banner
banner()
{
	echo -e $l_cyan' _      _   __  __ ___ ___  '
	echo '| |    /_\ |  \/  | _ \ _ \ '
	echo '| |__ / _ \| |\/| |  _/  _/ '
	echo '|____/_/ \_\_|  |_|_| |_|   '
	echo '   _  _   _ _____ ___  '
	echo '  /_\| | | |_   _/ _ \ '
	echo ' / _ \ |_| | | || (_) |'
	echo '/_/ \_\___/  |_| \___/          '
	echo ' ___ _  _ ___ _____ _   _    _    '
	echo '|_ _| \| / __|_   _/_\ | |  | |   '
	echo ' | || .` \__ \ | |/ _ \| |__| |__'
	echo '|___|_|\_|___/ |_/_/ \_\____|____|'
	echo ; sleep 0.5
}

# service
service_path="/lib/systemd/system/"

# Error message
error=$(echo -e $l_yello"[!] Please Check the Install Services, There is some $(tput bold)$(tput setaf 1)Problem$(tput sgr0)$l_yello Try fix using manual command!"; echo -e $N ; exit 0)

# Packages
web_server_package='apache2'
php_package='php7.0 php7.0-cli php7.0-common php7.0-curl php7.0-dev php7.0-gd php7.0-imap php7.0-intl php7.0-json php7.0-mbstring php7.0-mcrypt php7.0-mysql php7.0-pgsql php7.0-sqlite3 php7.0-xml php7.0-xmlrpc php7.0-xsl php7.0-zip libapache2-mod-php7.0'
database_service='mariadb'

# Process
uppackages()
{
	echo -e $l_green"[+] Updating packages"
	apt-get update &>/dev/null
}

apache2()
{
	echo -e $l_green"[+] Checking $web_server_package web service"; sleep 0.5
	if [[ -f $service_path$web_server_package'.service' ]];
		then
			echo -e $l_yello"[!] $web_server_package alredy installed"; sleep 0.5
		else
			echo -e $l_green"[+] Installing $web_server_package web server"
			apt-get install -y --allow-unauthenticated $web_server_package &>/dev/null
			echo -e $l_yello"[!] Installing $web_server_package done"; sleep 0.5
			if [[ -f $service_path$web_server_package'.service' ]];
				then
					echo -e $l_green"[+] Starting $web_server_package service"; sleep 0.5
					echo -e $l_green"[+] $web_server_package\t $(systemctl start $web_server_package 2>/dev/null ) $N[$l_blue$(systemctl status $web_server_package | grep "Active:" | awk {'print $2'} )$N] "; sleep 0.5
				else
					echo $error
			fi
	fi
}

php()
{
	echo -e $l_green"[+] Checking PHP package"; sleep 0.5
	if [[ -f /usr/bin/php ]];
		then
			echo -e $l_yello"[!] PHP alredy installed"; sleep 0.5
		else
			echo -e $l_green"[+] Installing PHP package"
			apt-get install -y --allow-unauthenticated $php_package &>/dev/null
			echo -e $l_yello"[!] Inporting php info to /var/www/html"; sleep 0.5
			echo -e "<?php phpinfo(); ?>" > /var/www/html/info.php
			echo -e $l_yello"[!] You can access php info from http://$(hostname -i)/info.php"; sleep 0.5
			if [[ -f /usr/bin/php7.0 && -f /usr/bin/php ]];
				then
					echo -e $l_yello"[!] Installing PHP done"; sleep 0.5
				else
					echo $error
			fi
	fi 				
}

db()
{
	echo -e $l_green"[+] Checking Database ($database_service) service"; sleep 0.5
	if [[ -f $service_path$database_service'.service' ]];
		then
			echo -e $l_yello"[!] Database ($database_service) alredy installed"; sleep 0.5
		else
			echo -e $l_green"[+] Installing Database ($database_service)"
			apt-get install -y --allow-unauthenticated $database_service-server &>/dev/null
			echo -e $l_yello"[!] Installing Database ($database_service) done"; sleep 0.5
			echo -e $l_green"[+] Starting Database service"; sleep 0.5
			echo -e $l_green"[+] $database_service\t $(systemctl start $database_service 2>/dev/null ) $N[$l_blue$(systemctl status $database_service | grep "Active:" | awk {'print $2'} )$N] "; sleep 0.5
			if [[ $(systemctl status mysql | grep 'Active:' | awk {'print $2'} ) == 'active' ]];
				then
					echo -e $l_yello"[!] Configuring database"; sleep 0.5
					echo -en $l_yello"[!] Input password for database configuration : "; read pass_database
					echo -e $l_yello"[!] Please wait..."
					apt install -y --allow-unauthenticated expect &>/dev/null
					SECURE_MYSQL=$(expect -c "
					set timeout 10
					spawn mysql_secure_installation
					expect \"Enter current password for root (enter for none):\"
					send \"$blank_variabel\r\"
					expect \"Change the root password?\"
					send \"y\r\"
					expect \"New password\"
					send \"$pass_database\r\"
					expect \"Re-enter new password\"
					send \"$pass_database\r\"
					expect \"Remove anonymous users?\"
					send \"y\r\"
					expect \"Disallow root login remotely?\"
					send \"y\r\"
					expect \"Remove test database and access to it?\"
					send \"y\r\"
					expect \"Reload privilege tables now?\"
					send \"y\r\"
					expect eof
					")
					mysql -u root --password=$pass_database -D mysql -e "update user set plugin='' where User='root';"
					mysql -u root --password=$pass_database -D mysql -e "flush privileges;"
					echo -e $l_green"[+] Configuring done";sleep 0.5
				else
					echo $error
			fi
	fi
}

phpmyadmin()
{
	if [[ $(systemctl status mysql | grep 'Active:' | awk {'print $2'} ) == 'active' ]];
		then
			echo -e $l_green"[+] Checking phpmyadmin package"; sleep 0.5
			if [[ -d /etc/phpmyadmin && -d /var/lib/phpmyadmin ]];
				then
					echo -e $l_yello"[!] Package phpmyadmin alredy installed";sleep 0.5
				else
					echo -en $l_yello"[!] Do you want to install phpmyadmin package (y/N)? "; read phpmyadmin_install
					if [[ $phpmyadmin_install == 'y' || $phpmyadmin_install == 'Y' ]];
						then
							echo -e $l_green"[+] Installing phpmyadmin package"
							apt-get install -y --allow-unauthenticated debconf-utils &>/dev/null
							echo -e "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
							echo -e "phpmyadmin phpmyadmin/app-password-confirm password $pass_database" | debconf-set-selections
							echo -e "phpmyadmin phpmyadmin/mysql/admin-pass password $pass_database" | debconf-set-selections
							echo -e "phpmyadmin phpmyadmin/mysql/app-pass password $pass_database" | debconf-set-selections
							echo -e "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
							apt-get install -y --allow-unauthenticated phpmyadmin &>/dev/null
							if [[ -d /etc/phpmyadmin && -d /var/lib/phpmyadmin ]];
								then
									echo -e $l_yello"[!] Installing phpmyadmin done"; sleep 0.5
								else
									echo $error
							fi
						else
							echo -e $l_red"[-] Skip it"; sleep 0.5
					fi
			fi
	fi
}

restartingservice()
{
	echo -e $l_green"[+] Restarting all service"; sleep 0.5
	echo -e $l_blue"============================================"
	echo -e $l_red" SERVICE\t  RUNNING\t STATUS"
	echo -e $l_blue"============================================"; sleep 0.5
	echo -e $l_red" $web_server_package\t $l_green Status\t $N[$l_blue$(systemctl restart $web_server_package; systemctl status $web_server_package | grep "Active:" | awk {'print $2'})$N]"; sleep 0.5
	echo -e $l_red" $database_service\t $l_green Status\t $N[$l_blue$(systemctl restart $database_service; systemctl status $database_service | grep "Active:" | awk {'print $2'})$N]"; sleep 0.5
}

# Starting process
banner
uppackages
apache2
php
db
phpmyadmin
restartingservice
echo -en $N
