#!/bin/bash
# Purpose: installing firefox and opening new tab to http://localhost/

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

info "updating package list"

apt update

info "installing or upgrading firefox if required"

installPkg firefox

info "opening new tab to http://localhost/"

runuser -u $SUDO_USER -- firefox --new-tab "http://localhost/"