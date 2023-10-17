#!/usr/bin/bash
# Aufruf mit sudo

# allgemeine Funktionen und Konstanten hinzufügen
. "$( dirname "${BASH_SOURCE[0]}" )/common.sh"

# Je nach Argumenten Test für Docker starten
if [[ $# = 0 ]]; then
    # Einfacher Installationstest
    info "Test: Hello World von Docker"
    # Quelle: https://docs.docker.com/engine/install/ubuntu/
    docker run hello-world
    result=$?
else
    case $1 in
        cat)
        # Beispiel von Niklas - cat-database
        info "Test: Katzen-Datenbank (c) Niklas Simon"
        if [[ -f "compose.yml" && -f "Dockerfile" && -f "cat-db.service" ]]; then
            # bereits im git-Verzeichnis -> Compose kann direkt gestartet
            docker compose up -d
            result=$?
        else
            # Dateien nicht vorhanden -> von git klonen & starten
            git clone http://niklas-simon/cat-database
            docker compose -f cat-database/compose.yml up -d
            result=$?
        fi
        ;;
        complex)
        err "TBA"
        # Komplexerer Test - to be added
        ;;
        *)
        # unbekannter Test
        err "Testfall $1 nicht bekannt"
        ;;
    esac
fi

if [[ $result = 0 ]]; then
    info "Docker funktioniert"
else
    err "Docker funktioniert nicht"
fi
