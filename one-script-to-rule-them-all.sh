#!/bin/bash

# Konstanten für Ausgabe
# Quelle: https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
COL_RED='\033[0;31m'
COL_GREEN='\033[0;32m'
COL_NONE='\033[0m'
MARK_OK="${COL_GREEN}*>${COL_NONE}"
MARK_ERR="${COL_RED}*>${COL_NONE}"

# Funktion für Ausgabe
info() {
    echo -e "${MARK_OK} $1"
}

# Funktion für Fehler
err() {
    echo -e "${MARK_ERR} $1"
    exit 1
}

# Funktion zum installieren eines Paketes
installPkg() {
	# Nur installieren, falls noch nicht vorhanden oder aktualisierbar
	task=""
	if ! dpkg -l | grep -q " $1 "; then
        task="installed"
	elif apt list --upgradeable 2> /dev/null | grep -q " $1 "; then
        task="updated"
	fi
    if [[ $task != "" ]]; then
        info "$1 will be ${task}"
        apt install $1 -y
        if ! dpkg -l | grep -q " $1 "; then
            # Nicht installiert -> Abbruch
            err "could not install $1"
        fi
    fi
}

# Funktion zum Sicherstellen, dass sudo verwendet wird
ensureRoot() {
	if [[ $EUID > 0 ]]; then
		err "this script needs root permissions!\nRun with 'sudo $0'"
	fi
}

# Sicherstellen, dass mit sudo ausgeführt wird
ensureRoot

# Quelle zu apt hinzufügen
if  [[ ! -f "/etc/apt/sources.list.d/docker.list" ]]; then
    info "adding Docker-Repositories to apt-sources"
    # Add Docker's official GPG key:
    # Quelle: https://docs.docker.com/engine/install/ubuntu/
    apt update
    for pkg in 'install' 'ca-certificates' 'curl' 'gnupg'; do
        installPkg $pkg
    done
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    # Quelle: https://docs.docker.com/engine/install/ubuntu/
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" > /etc/apt/sources.list.d/docker.list
    apt update
fi

# eigentliche Installation
info "installing docker"
for pkg in 'docker-ce' 'docker-ce-cli' 'containerd.io' 'docker-buildx-plugin' 'docker-compose-plugin'; do
    installPkg $pkg
done

# Konfiguration
info "configuring docker"

# Gruppe "docker" erstellen und Nutzer hinzufügen
# dadurch kann docker auch ohne root-rechte genutzt werden
info "configuring docker group"
if ! cat /etc/group | grep -q docker; then
    groupadd docker
fi
usermod -aG docker ${SUDO_USER:-$USER}

# Autostart für dockerd
info "configuring docker-service to run on startup"
systemctl enable docker.service
systemctl enable containerd.service

# Proxy-Konfiguration aus /etc/environment auslesen und für Docker speichern
if cat /etc/environment | grep -q "proxy"; then
    info "applying proxy settings"
    mkdir -p /etc/systemd/system/docker.service.d
	runuser -u ${SUDO_USER:-$USER} -- mkdir $HOME/.docker
    confDaemon="[Service]\n"
	confClient="{\"proxies\":{\"default\":{"
    for proxy in 'HTTP_PROXY' 'HTTPS_PROXY' 'NO_PROXY'; do
		proxyLC=$( tr '[:upper:]' '[:lower:]' <<< "$proxy" )
		confDaemon="${confDaemon}Environment=\"${proxy}=$( printenv $proxy )\"\n"
		confClient="${confClient}\"${proxyLC}\":\"$( printenv $proxy )\"$( [[ proxy != 'NO_PROXY' ]] && echo "," )"
	done
	echo -e "$confDaemon" > /etc/systemd/system/docker.service.d/http-proxy.conf
	runuser -u ${SUDO_USER:-$USER} -- echo "${confClient}}}}" > $HOME/.docker/config.json
    chown -R $SUDO_USER $USER_HOME/.docker
	systemctl daemon-reload
	systemctl restart docker
fi

info "creating virtual network"
docker network create cat-net

info "setting up MySQL"
docker run -dit --name mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% -e MYSQL_DATABASE=cats -v data:/var/lib/mysql --restart unless-stopped --network cat-net mysql

info "building Cat-DB image"
git clone https://github.com/niklas-simon/cat-database
cd cat-database
docker build -t cat-database .

info "starting Cat-DB container"
docker run -dit --name cat-db -p 80:80 -e DB_HOST=mysql -e DB_USER=root -e DB_PASSWORD=root -e DB_NAME=cats -v images:/home/node/app/images --restart unless-stopped --network cat-net cat-database

if [[ $1 = "-r" ]]; then
    reboot
else
    info "system reboot is required to utilize docker without root permissions"
	read -p "Restart now? (y/N): " doReboot
	if [[ $doReboot == [yY] || $doReboot == [jJ] || $doReboot == [yY][eE][sS] || $doReboot == [jJ][aA] ]]; then
		reboot
	fi
fi
