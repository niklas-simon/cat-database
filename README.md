# Cat Database
A simple nodejs server giving access to a database containing images of cats.

## Environment Variables
Key         | Description                         | Default
------------|-------------------------------------|----------
DB_HOST     | Hostname of DB-Server to connect to | mysql
DB_USER     | Username of DB-Server to use        | root
DB_PASSWORD | Password for User                   | root
DB_NAME     | Name of Database to use             | cats

## Network Setup
```
docker network create cat-net
```

## Database Setup
```
docker run -dit --name mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% -e MYSQL_DATABASE=cats -v data:/var/lib/mysql --restart unless-stopped --network cat-net mysql
```
> [!WARNING]  
> Please note that for security reasons, you should never use sensitive data inside a command

## Docker Build Command
```
docker build -t cat-database .
```

## Docker Run Command
```
docker run -dit --name cat-db -p 80:80 -e DB_HOST=mysql -e DB_USER=root -e DB_PASSWORD=root -e DB_NAME=cats -v images:/home/node/app/images --restart unless-stopped --network cat-net cat-database
```
> [!WARNING]  
> Please note that for security reasons, you should never use sensitive data inside a command

## Installation without Docker
I don't know why you'd want to do this, but here you go!
```
wget -qO- https://raw.githubusercontent.com/niklas-simon/cat-database/main/dockerless.sh | sudo sh
```