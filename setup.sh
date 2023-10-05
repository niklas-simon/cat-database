echo '##########################################'
echo '#####       Setting up MySQL        ######'
echo '##########################################'

docker run -dit --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=cats -v data:/var/lib/mysql --restart unless-stopped mysql

# wait for mysql to be ready
#while ! mysqladmin ping -h 127.0.0.1 --silent; do
#    sleep 1
#done

echo '##########################################'
echo '#####     Building Cat-DB Image     ######'
echo '##########################################'

docker build -t cat-database .

echo '##########################################'
echo '#####   Starting Cat-DB Container   ######'
echo '##########################################'

docker run -dit --name cat-database -p 80:8080 -e DB_HOST=172.17.0.1 -e DB_USER=root -e DB_PASSWORD=root -e DB_NAME=cats -v images:/home/node/app/images --restart unless-stopped cat-database