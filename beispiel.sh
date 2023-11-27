#!/usr/bin/bash
# Zweck: Funktionen des common.sh-Skriptes erklären

# String festlegen, der bei -h bzw. --help angezeigt werden soll
helpStr="Dies ist eine Hilfe"

# Log-Datei festlegen
logFile="example.log"

# Befehle in common.sh ausführen
. "$( dirname "${BASH_SOURCE[0]}" )/common.sh"

# Sicherstellen, dass nicht als root ausgeführt wird
ensureNoRoot

# Anfangsüberschrift
startScript

# Information
info "Eine Information"

# Paket installieren
installPkg "${1:-curl}"

# weitere Überschriften
header "Überschrift" -t 2 -f orange -c green
header "Eine Unterüberschrift" -f yellow

# zufälliger Fehler
if [[ 0 = $(( $RANDOM % 3 )) ]]; then
    err "Ein zufälliger Fehler ist aufgetreten"
fi

# Warnung
warn "Script ist bald vorbei"

# Endüberschrift
endScript
