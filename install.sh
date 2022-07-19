#!/usr/bin/env bash

hdd1="hdd_name"
hdddir="cloud_folder"
sqldb="sqldb"
sqluser="sqluser"
sqlpass="sqlpass"
URL_NEXTCLOUD="https://download.nextcloud.com/server/releases/latest.tar.bz2"
TAR_NEXTCLOUD="latest.tar.bz2"
fstabLOC="/etc/fstab"
DOWNLOADMAP="/var/www/"
rood='\e[1;91m'
groen='\e[1;92m'
oranje='\e[1;93m'
geen='\e[0m'

test_internet(){
if ! ping -c 1 8.8.8.8 -q &> /dev/null; then
  echo -e "$rood[ERROR]$geen - Uw computer heeft geen internetverbinding. Controleer het netwerk."
  exit 1
else
  echo -e "$groen[INFO]$geen  - Internetverbinding werkt normaal."
fi
}

apt_update(){
echo -e "$groen[INFO]$geen  - Updaten van het systeem!"
sudo apt update -y && sudo apt full-upgrade -y
}

add_phprepo(){
echo "$groen[INFO]$geen  - PHP architectuur toevoegen!"
sudo wget -qO /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
}

just_apt_update(){
echo -e "$groen[INFO]$geen  - Het archief bijwerken!"
sudo apt update -y
sudo apt upgrade -y
}

setup_externalhdd(){
echo -e "$groen[INFO]$geen  - Externe hardeschijf instellen!"
echo -e "Hardeschijf nu ingeplugd? (y/n)"
read input
if [[ "$input" == "y" ]] || [[ "$input" == "j" ]]; then
 echo -e "$groen[INFO]$geen  - Goedzo, en doorrrrrrrr :)!"
fi
sudo umount /media/gerwin/$hdd1
sudo umount /mnt/$hdd1
sudo rm -rf /mnt/$hdd1
sudo parted /dev/sda mklabel gpt
sudo parted -a opt /dev/sda mkpart primary ext4 0% 100%
sudo mkfs.ext4 -L new-volume-label /dev/sda1
sudo mkdir /mnt/$hdd1
sudo mkdir -p /mnt/$hdd1/$hdddir
sudo mount /dev/sda1 /mnt/$hdd1
lsblk --fs
echo -e "Kopieer de uuid van: $hdd1 Heb je die gekopieerd? (Y/n)"
read input
if [[ "$input" == "y" ]] || [[ "$input" == "j" ]]; then
 echo -e "Plak nu hier de uuid"
 read input
 echo "UUID=$input /mnt/$hdd1 ext4 defaults,auto,users,rw,nofail 0 0" | sudo tee -a $fstabLOC
fi
}

install_apt(){
echo -e "$groen[INFO]$geen  - Addon pakketten installeren vanuit de repository"
sudo apt install apache2 mariadb-server redis-server redis-tools fail2ban iptables iptables-persistent php8.1 php8.1-gd php8.1-sqlite3 php8.1-curl php8.1-zip php8.1-xml php8.1-mbstring php8.1-mysql php8.1-bz2 php8.1-intl php8.1-smbclient php8.1-imap php8.1-gmp php8.1-imagick php8.1-bcmath libapache2-mod-php8.1 libmagickcore-6.q16-6-extra php8.1-redis php8.1-igbinary php8.1-opcache python3-certbot-apache -y
}

extra_config1(){
echo -e "$groen[INFO]$geen  - Zet permissies van het systeem!"
sudo chown -R www-data:www-data /mnt/$hdd1/$hdddir
sudo chmod 777 /mnt/$hdd1/$hdddir
}

apache_restart(){
sudo service apache2 restart
}

setup_mysql(){
echo -e "$groen[INFO]$geen  - Database voorbereiden!"
sudo mysql_secure_installation
sudo mysql -u root -p
}

setup_nextcloud(){
echo -e "$groen[INFO]$geen - Nextcloud downloaden en installeren!"
sudo wget $URL_NEXTCLOUD -P $DOWNLOADMAP
sudo tar -xvf /var/www/${TAR_NEXTCLOUD} -C /var/www
}

extra_config2(){
echo -e "$groen[INFO]$geen  - Zet permissies van het systeem!"
sudo chown -R www-data:www-data /mnt/$hdd1/$hdddir
sudo chmod 777 /mnt/$hdd1/$hdddir
sudo chown -R www-data:www-data /var/www/nextcloud
sudo chmod 777 /var/www/nextcloud
}

create_nextconfig(){
echo -e "$groen[INFO]$geen - Apache configuratie aanmaken en instellen!"
sudo touch /etc/apache2/sites-available/nextcloud.conf
sudo ed /etc/apache2/sites-available/nextcloud.conf << END
a
Alias /nextcloud "/var/www/nextcloud/"

<Directory /var/www/nextcloud/>
  Require all granted
  AllowOverride All
  Options FollowSymLinks MultiViews

  <IfModule mod_dav.c>
    Dav off
  </IfModule>


  <IfModule mod_headers.c>
    Header always set Strict-Transport-Security "max-age=15552000; includeSubDo>
  </IfModule>

</Directory>

# ---------------------
# Nextcloud stuff below
# ---------------------
Redirect 301 /.well-known/carddav /nextcloud/remote.php/dav
Redirect 301 /.well-known/caldav /nextcloud/remote.php/dav
Redirect 301 /.well-known/webfinger /nextcloud/index.php/.well-known/webfinger
Redirect 301 /.well-known/nodeinfo /nextcloud/index.php/.well-known/nodeinfo
.
w
q
END
echo -e "$groen[INFO]$geen - Nabewerking apache server!"
sudo a2ensite nextcloud
sudo systemctl reload apache2
echo -e "$groen[INFO]$geen  - Klaar, nu het web gedeelte.."
echo -e "$groen[INFO]$geen  - Installatie pagina opent na invullen ipadres, gebruik volgende info:"
echo -e "$groen[INFO]$geen  - Verander sqllite naar mysql database!"
echo -e "$groen[INFO]$geen  - Zet data map op deze locatie: /mnt/$hdd1/$hdddir "
echo -e "$groen[INFO]$geen  - Mysql database: $sqldb "
echo -e "$groen[INFO]$geen  - Mysql user: $sqluser "
echo -e "$groen[INFO]$geen  - Mysql pass: $sqlpass "
echo -e "$rood[BELANGRIJK]$geen === INSTALLEER ADDONS NIET NA INSTALLATIE === $rood[BELANGRIJK]$geen "
echo -e "$groen[INFO]$geen - Ga naar ipadres in browser e.g. xxx.xxx.xxx..XXX/nextcloud"
echo -e "$oranje[WAARSCHUWING]Druk pas op y/j wanneer de web-installatie klaar is..$geen "
read input
if [[ "$input" == "y" ]] || [[ "$input" == "j" ]]; then
 echo -e "$groen[INFO]$geen  - Goedzo we gaan verder!"
fi
echo -e "$groen[INFO]$geen - Office downloaden en installeren, dit kan even duren!"
sudo -u www-data php -d memory_limit=512M /var/www/nextcloud/occ app:install richdocumentscode_arm64
echo -e "$groen[INFO]$geen - Nextcloud configuratie bewerken"
sudo chmod 777 /var/www/nextcloud/config/
sudo cp -p /var/www/nextcloud/config/config.php /var/www/nextcloud/config/config.php.bk
sudo ed /var/www/nextcloud/config/config.php << END
6i
  'memcache.local' => '\OC\Memcache\Redis',
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => [
  'host' => 'localhost',
  'port' => 6379,
  ],
  'log_rotate_size' => 100 * 1024 * 1024,
.
w
q
END
sudo chmod 750 /var/www/nextcloud/config/
sudo chmod 777 /etc/php/8.1/apache2/php.ini
echo -e "$groen[INFO]$geen - PHP instellen!"
sudo cp -v -p -f php.ini /etc/php/8.1/apache2
sudo chmod 750 /etc/php/8.1/apache2/php.ini
sudo systemctl reload apache2
sudo sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config #SSH PORT
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo install -d -m 700 ~/.ssh
sudo ed ~/.ssh/authorized_keys << END
a
##### PRIVATE SSH KEY SHOULD GO HERE #####
.
w
q
END
}

extra_config3(){
echo -e "$groen[INFO]$geen  - Zet permissies van het systeem!"
sudo chown -R www-data:www-data /mnt/$hdd1/$hdddir
sudo chmod 750 /mnt/$hdd1/$hdddir
sudo chown -R www-data:www-data var/www/nextcloud
sudo chmod 750 /var/www/nextcloud
echo -e "$groen[INFO]$geen  - Starten van cronjob!"
sudo crontab -u www-data -l > mycron
echo '*/5  *  *  *  * php -f /var/www/nextcloud/cron.php' >> mycron
sudo crontab -u www-data mycron
sudo rm mycron
sudo a2enmod headers
}

security_setup(){
echo -e "$groen[INFO]$geen - Firewall instellen!"
sudo systemctl enable iptables
sudo systemctl start iptables
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT #internet
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT # SSH
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT #SSL
sudo iptables -A INPUT -s xxx.xxx.xxx.xxx -j ACCEPT
sudo iptables -A INPUT -s xxx.xxx.xxx.xxx -j ACCEPT
sudo iptables -A INPUT -s xxx.xxx.xxx.xxx -j ACCEPT
sudo iptables -A INPUT -s xxx.xxx.xxx.xxx -j ACCEPT
sudo apt-get install iptables-persistent
echo -e "$groen[INFO]$geen - Letsencrypt licentie verkrijgen!"
echo -e "$oranje[Kopieer en plak]$geen - sudo certbot --apache"
read input
$input
sudo systemctl reload apache2
echo -e "$groen[INFO]$geen - Fail2ban instellen!"
sudo cp -v -p -f jail.local /etc/fail2ban
echo -e "$oranje[Kopieer en plak]$geen - sudo service fail2ban restart"
read input
$input
}

system_clean(){
echo -e "$groen[INFO]$geen  - Systeem opschonen!"
sudo apt update -y
sudo apt autoclean -y
sudo apt autoremove -y
echo -e "$oranje[Kopieer en plak]$geen - sudo reboot (indien geen reboot nodig druk op ENTER)"
read input
$input
}

test_internet
just_apt_update
add_phprepo
apt_update
setup_externalhdd
install_apt
extra_config1
apache_restart
setup_mysql
setup_nextcloud
extra_config2
create_nextconfig
extra_config3
security_setup
system_clean

## install voltooid
echo -e "$groen[INFO]$geen  - Script voltooid, installatie geslaagd! Reboot getriggerd :)"
