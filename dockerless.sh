echo '############################################'
echo '#####   Installing required packages   #####'
echo '############################################'

apt update
apt install -y git mysql-server mysql-client snapd

echo '############################################'
echo '#####        Configuring mysql         #####'
echo '############################################'

mysql --defaults-file=/etc/mysql/debian.cnf -e "create database cats"
mysql --defaults-file=/etc/mysql/debian.cnf -e "alter user 'root'@'localhost' identified with mysql_native_password by 'root'"

echo '############################################'
echo '#####        Installing Node.js        #####'
echo '############################################'

snap install node --classic --channel=18

echo '############################################'
echo '#####       Configuring Cat-DB       #####'
echo '############################################'

cd /etc/
git clone https://github.com/niklas-simon/cat-database
cd /etc/cat-database
npm i

echo '############################################'
echo '#####        Creating Log Files        #####'
echo '############################################'

mkdir /var/log/cat-db
touch /var/log/cat-db/default.log
touch /var/log/cat-db/error.log

echo '############################################'
echo '#####   Configuring Systemd Service    #####'
echo '############################################'

cp cat-db.service /etc/systemd/system
systemctl daemon-reload
systemctl enable cat-db
systemctl start cat-db