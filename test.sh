#!/usr/bin/bash
# Aufruf mit sudo

# allgemeine Funktionen und Konstanten hinzufügen
. "$( dirname "${BASH_SOURCE[0]}" )/common.sh"

###########################################
####            Funktionen            #####
###########################################

# Funktion zum sicherstellen dass Dateien vorhanden sind
# Ansonsten über git clone holen
testGit() {
	# sicherstellen, dass git installiert ist
	installPkg git
	changed=0
	# Prüfen, ob man sich im benötigten git-Repo befindet
	if ! git config --get remote.origin.url | grep -q "niklas-simon/cat-database"; then
		# Repo klonen und Verzeichnis wechseln
		git clone https://github.com/niklas-simon/cat-database
		cd cat-database
		# merken, dass das Verzeichnis gewechselt wurde
		changed=1
	fi
	# Prüfen, auf welchem Branch man ist
	if ! git rev-parse --abbrev-ref HEAD | grep -q "bernhard"; then
		# auf benötigten Branch wechseln
		git checkout bernhard
	fi
}

endGit() {
	# falls in testGit() das Verzeichnis gewechselt wurde
	if [[ $changed = 1 ]]; then
		# Verzeichnis zurückwechseln
		cd ..
	fi
}

# Prüfen, ob die Docker-Container beendet werden sollen oder nicht
keepAlive() {
	return [[ $# > 1 ]] && [[ $2 = '-k' || $2 = '--keep' ]]
}

stopInstead() {
	return [[ $# > 1 ]] && [[ $2 = '-s' || $2 = '--stop' ]]
}

###########################################
####              Anfang              #####
###########################################

# Je nach Argumenten Test für Docker starten
if [[ $# = 0 ]]; then
    # Einfacher Installationstest
    info "Test: Hello World von Docker"
    # Quelle: https://docs.docker.com/engine/install/ubuntu/
    docker run hello-world
    result=$?
else
    case $1 in
        #------------------------------------#
		# Beispiel von Niklas - cat-database #
        #------------------------------------#
		simple)
        info "Test: Katzen-Datenbank (c) Niklas Pein"
		testGit
		if stopInstead $@; then
			docker stop mysql
			docker stop cat-db
			exit
		fi
		# Netzwerk erstellen
		if ! docker network ls -f "name=cat-net"; then
			docker network create cat-net
		fi
		# mysql-Container aus öffentlichem Image starten
		docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% -e MYSQL_DATABASE=cats -v data:/var/lib/mysql --restart unless-stopped --network cat-net mysql
		# cat-database Image aus Dockerfile erstellen
		docker build -t cat-database --build-arg HTTP_PROXY=$HTTP_PROXY --build-arg HTTPS_PROXY=$HTTPS_PROXY cat-service
		# cat-db Container aus erstelltem Image starten
		docker run -d --name cat-db -p 80:80 -e DB_HOST=mysql -e DB_USER=root -e DB_PASSWORD=root -e DB_NAME=cats -v images:/home/node/app/images --restart unless-stopped --network cat-net cat-database
		# Ergebnis feststellen
		curl localhost > /dev/null
		result=$?
		# Container stoppen
		if ! keepAlive $@; then
			docker stop mysql
			docker stop cat-db
		fi
		endGit
        ;;
		#------------------#
        # Komplexerer Test #
		#------------------#
        complex)
        err "Not yet implemented"
		info "Test: Katzen-Datenbank v2 (c) Niklas Pein, Bernhard Lindner"
		testGit
		if stopInstead $@; then
			docker compose down
			exit
		fi
		# Container starten
		docker compose up -d
		# Ergebnis feststellen
		curl localhost > /dev/null
		result=$?
		# Container stoppen
		if ! keepAlive $@; then
			docker compose down
		fi
		endGit
        ;;
		#---------------------#
        # kein bekannter Test #
		#---------------------#
        *)
        err "Testfall $1 nicht bekannt"
        ;;
    esac
fi

if [[ $result = 0 ]]; then
    info "Docker funktioniert"
else
    err "Docker funktioniert nicht"
fi
