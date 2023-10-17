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
        task="installiert"
    elif apt list --upgradeable 2> /dev/null | grep -q " $1 "; then
        task="aktualisiert"
    fi
    if [[ $task != "" ]]; then
        info "Paket $1 wird ${task}"
        apt install $1 -y
        if ! dpkg -l | grep -q " $1 "; then
            # Nicht installiert -> Abbruch
            err "Paket $1 konnte nicht installiert werden."
        fi
    fi
}

# Funktion zum Sicherstellen, dass sudo verwendet wird
ensureRoot() {
    if [[ $EUID > 0 ]]; then
        err "Rootrechte benötigt!\nAufruf: sudo $0"
    fi
}

# Nutzung:
# 1. Shell-skrpit inkludieren, Befehl:
# . "$( dirname "${BASH_SOURCE[0]}" )/common.sh"
# 2. Funktionen aufrufen
# info "Starte das Skript"
# installPkg openssh-server
# err "Installation abgebrochen"