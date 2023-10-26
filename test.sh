#!/usr/bin/bash
# Zweck: Verwawltung von Beispielanwendungen

# Hilfe
helpStr="Verwaltung von Beispielanwendungen\n
Aufruf: $0 [Beispiel] [Optionen]\n
Mögliche Beispiele: simple, complex\n
Optionen:\n
    -s | --stop        Stoppt die bereits laufenden Container der Beispiele\n
    -k | --keep        Container werden nicht automatisch beendet, sondern laufen weiter.\n
    -o | --open        (In Kombination mit -k) Öffnet Firefox auf localhost"

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
    # in Verzeichnis mit Skripten wechseln
    cd $( dirname "${BASH_SOURCE[0]}" )
    # Prüfen, ob man sich im benötigten git-Repo befindet
    if ! git config --get remote.origin.url | grep -q "niklas-simon/cat-database"; then
        if [[ -d "cat-database" ]]; then
            cd cat-database
            if ! git config --get remote.origin.url | grep -q "niklas-simon/cat-database"; then
                err "Verzeichnis cat-database existiert bereits, ist jedoch nicht das benötigte Git-Repository"
            fi
        else
            info "Git-Repository wird geklont"
            # Repo klonen und Verzeichnis wechseln
            git clone https://github.com/niklas-simon/cat-database
            cd cat-database
        fi
    fi
    # Prüfen, auf welchem Branch man ist
    if ! git rev-parse --abbrev-ref HEAD | grep -q "bernhard"; then
        # auf benötigten Branch wechseln
        git checkout bernhard
    fi
}

# Prüft mehrfach, ob Container erfolgreich gestartet wurden
getResult() {
    maxTries=5
    info "Versuche: $maxTries"
    retry=0
    curl localhost > /dev/null 2>&1
    result=$?
    while [[ $retry < $maxTries && $result != 0 ]]; do
        sleep 3
        curl localhost > /dev/null 2>&1
        result=$?
        if [[ $result != 0 ]]; then
            info "Versuch $retry fehlgeschlagen ..."
        else
            break
        fi
        ((retry++))
    done
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
    # Variablen ermitteln
    testName=$1
    [[ $2 = '-s' || $2 = '--stop' ]] && stopTest="true" || stopTest="false" 
    [[ $2 = '-k' || $2 = '--keep' ]] && killAfter="false" || killAfter="true" 
    [[ $3 = '-o' || $3 = '--open' ]] && [[ $killAfter = "false" ]] && openBrowser="true" || openBrowser="false" 
    case $testName in
        #------------------------------------#
        # Beispiel von Niklas - cat-database #
        #------------------------------------#
        simple)
        info "Test: Katzen-Datenbank (c) Niklas Pein"
        testGit
        # -s oder --stop um die Container zu stoppen
        if [[ $stopTest = "true" ]]; then
            if ! docker container ls | grep -q "cat-service"; then
                err "Container laufen nicht"
            fi
            info "Container werden gestoppt"
            docker stop mysql
            docker stop cat-service
            docker container prune -f
            exit
        fi
        # Prüfen, ob die Container bereits laufen
        if docker container ls | grep -q "cat-service"; then
            err "Container laufen bereits"
        elif docker container ls --all | grep -q "cat-service"; then
            docker container prune -f
        fi
        # Netzwerk erstellen
        if ! docker network ls | grep -q "cat-net"; then
            info "Netzwerk erstellen"
            docker network create cat-net
        fi
        # mysql-Container aus öffentlichem Image starten
        info "MySQL-Container starten"
        docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=root -e MYSQL_ROOT_HOST=% -e MYSQL_DATABASE=cats -v data:/var/lib/mysql --restart unless-stopped --network cat-net mysql
        # cat-service Image aus Dockerfile erstellen
        if ! docker images | grep -q "cat-service"; then
            info "Eigenes Image bauen"
            docker build -t cat-service --build-arg HTTP_PROXY=$HTTP_PROXY --build-arg HTTPS_PROXY=$HTTPS_PROXY cat-service
        fi
        # cat-service Container aus erstelltem Image starten
        info "Container aus eigenem Image starten"
        docker run -d --name cat-service -p 80:80 -e DB_HOST=mysql -e DB_USER=root -e DB_PASSWORD=root -e DB_NAME=cats -v images:/home/node/app/images --restart unless-stopped --network cat-net cat-service
        # Ergebnis feststellen
        getResult
        if [[ $killAfter = "true" ]]; then
            # Container stoppen
            info "Container werden gestoppt"
            docker stop mysql
            docker stop cat-service
            docker container prune -f
        elif [[ $openBrowser = "true" ]]; then
            # -o bzw. --open: Firefox auf localhost öffnen
            firefox localhost > /dev/null 2>&1 &
        fi
        ;;
        #------------------#
        # Komplexerer Test #
        #------------------#
        complex)
        err "Not yet implemented"
        info "Test: Katzen-Datenbank v2 (c) Niklas Pein, Bernhard Lindner"
        testGit
        # -s oder --stop um die Container zu stoppen
        if [[ $stopTest = "true" ]]; then
            info "Container werden gestoppt"
            docker compose down
            exit
        fi
        # Prüfen, ob die Container bereits laufen
        if docker container ls | grep -q "cat-service"; then
            err "Container laufen bereits"
        fi
        # Container starten
        docker compose up -d
        # Ergebnis feststellen
        getResult
        if [[ $killAfter = "true" ]]; then
            # Container stoppen
            info "Container werden gestoppt"
            docker compose down
        elif [[ $openBrowser = "true" ]]; then
            # -o bzw. --open: Firefox auf localhost öffnen
            firefox localhost > /dev/null 2>&1 &
        fi
        ;;
        #---------------------#
        # kein bekannter Test #
        #---------------------#
        *)
        err "Testfall ${testName} nicht bekannt"
        ;;
    esac
fi

if [[ $result = 0 ]]; then
    info "Docker funktioniert"
else
    err "Docker funktioniert nicht"
fi
