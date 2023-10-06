# Cat Database
A simple nodejs server giving access to a database containing images of cats.

## Environment Variables
Key         | Description                         | Default
------------|-------------------------------------|----------
DB_HOST     | Hostname of DB-Server to connect to | 172.17.0.1
DB_USER     | Username of DB-Server to use        | root
DB_PASSWORD | Password for User                   | root
DB_NAME     | Name of Database to use             | cats

## Database Setup
```
docker run -dit --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=cats -v data:/var/lib/mysql --restart unless-stopped mysql
```
> [!WARNING]  
> Please note that for security reasons, you should never use sensitive data inside a command

## Docker Build Command
```
docker build -t cat-database .
```

## Docker Run Command
```
docker run -dit --name cat-database -p 80:80 -e DB_HOST=172.17.0.1 -e DB_USER=root -e DB_PASSWORD=root -e DB_NAME=cats -v images:/home/node/app/images --restart unless-stopped cat-database
```
> [!WARNING]  
> Please note that for security reasons, you should never use sensitive data inside a command