#!/usr/bin/bash
# Aufruf mit sudo

# allgemeine Funktionen und Konstanten hinzufügen
. "$( dirname "${BASH_SOURCE[0]}" )/common.sh"

# Sicherstellen, dass mit sudo ausgeführt wird
ensureRoot

# Quelle zu apt hinzufügen
if  [[ ! -f "/etc/apt/sources.list.d/docker.list" ]]; then
    info "Hinzufügen des Docker-Repositories zu den apt-Quellen"
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
info "Installation der Komponenten"
for pkg in 'docker-ce' 'docker-ce-cli' 'containerd.io' 'docker-buildx-plugin' 'docker-compose-plugin'; do
    installPkg $pkg
done

# Konfiguration
info "Docker konfigurieren"

# Gruppe "docker" erstellen und Nutzer hinzufügen
# dadurch kann docker auch ohne root-rechte genutzt werden
info "Gruppe einrichten"
if ! cat /etc/group | grep -q docker; then
    groupadd docker
fi
usermod -aG docker ${SUDO_USER:-$USER}

# Autostart für dockerd
info "Autmoatische Ausführung des Docker Daemon einrichten"
systemctl enable docker.service
systemctl enable containerd.service

# Proxy-Konfiguration aus /etc/environment auslesen und für Docker speichern
if cat /etc/environment | grep -q "proxy"; then
    info "Proxy-Einstellungen übernehmen"
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
	systemctl daemon-reload
	systemctl restart docker
fi

if [[ $1 = "-r" ]]; then
    reboot
else
    info "Starten sie den Rechner neu, um Docker nutzen zu können"
fi
