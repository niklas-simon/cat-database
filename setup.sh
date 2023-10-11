echo '##########################################'
echo '#####   Creating Virtual Network    ######'
echo '##########################################'

docker network create cat-net

echo '##########################################'
echo '#####       Setting up MySQL        ######'
echo '##########################################'

docker run -dit --name mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% -e MYSQL_DATABASE=cats -v data:/var/lib/mysql --restart unless-stopped --network cat-net mysql

echo '##########################################'
echo '#####     Building Cat-DB Image     ######'
echo '##########################################'

apt install git
git clone https://github.com/niklas-simon/cat-database
cd cat-database
docker build -t cat-database .

echo '##########################################'
echo '#####   Starting Cat-DB Container   ######'
echo '##########################################'

docker run -dit --name cat-db -p 80:80 -e DB_HOST=mysql -e DB_USER=root -e DB_PASSWORD=root -e DB_NAME=cats -v images:/home/node/app/images --restart unless-stopped --network cat-net cat-database