#========================#
# Funktionen & Variablen #
#========================#

# Farbkonstanten für Ausgabe
# Quelle: https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
declare -A colors=( [none]='\033[0m' [red]='\033[0;31m' [green]='\033[0;32m' [yellow]='\033[0;93m' [blue]='\033[0;34m' [orange]='\033[0;33m' )

# Funktion für Informative Ausgabe
info() {
    echo -e "${colors[green]}*>${colors[none]} $1"
    [[ -w $logFile ]] && echo "$( date "+%T" ) [INFO] $1" >> $logFile
}

# Funktion für Warnungen
warn() {
    echo -e "${colors[yellow]}*>${colors[none]} $1"
    [[ -w $logFile ]] && echo "$( date "+%T" ) [WARN] $1" >> $logFile
}

# Funktion für Fehler
err() {
    echo -e "${colors[red]}*>${colors[none]} $1"
    [[ -w $logFile ]] && echo "$( date "+%T" ) [ERR]  $1" >> $logFile
    exit 1
}

# Definition Assoziatives Array für Rahmen der Überschriften
declare -A border=( [0,0]='+' [0,1]='-' [0,2]='|' [1,0]='#' [1,1]='=' [1,2]='#' [2,0]='###' [2,1]='#' [2,2]='## ' )

# Funktion zum schreiben einer Überschrift
# Aufruf: header "Text" [-t [0|1|2]] [-f color] [-c color]
# mögliche Farben: none, red, green, yellow, blue, orange
header() {
    # Text speichern 
    l_text=$1
    shift 1
    # Standardwerte setzen
    l_type=0
    l_frameCol=blue
    l_textCol=frame
    # Parameter verabeiten
    while [[ $# > 0 ]]; do
        case $1 in
            # Parameter Typ
            -t|--type)
            l_type=$2
            shift 2
            ;;
            # Parameter Rahmenfarbe
            -f|--frameCol)
            l_frameCol=$2
            shift 2
            ;;
            # Parameter Textfarbe
            -c|--textCol)
            l_textCol=$2
            shift 2
            ;;
            *)
            # Unbekannter Parameter
            shift 1
            ;;
        esac
    done
    # Prüfen, dass sinnvolle werte als Parameter angegeben wurden
    [[ -z ${colors[$l_frameCol]} ]] && l_frameCol=blue
    [[ -z ${colors[$l_textCol]} ]] && l_textCol=$l_frameCol
    [[ 0 > $l_type || $l_type > 2 ]] && l_type=0
    # Texte erzeugen
    botTop="${border[$l_type,0]}$( echo " $l_text " | sed s/./${border[$l_type,1]}/g )${border[$l_type,0]}"
    midLog="${border[$l_type,2]} $l_text $( echo "${border[$l_type,2]}" | rev )"
    midCol="${border[$l_type,2]}${colors[$l_textCol]} $l_text ${colors[$l_frameCol]}$( echo "${border[$l_type,2]}" | rev )"
    # Texte ausgeben
    echo -e "${colors[$l_frameCol]}$botTop"
    echo -e "$midCol"
    echo -e "$botTop${colors[none]}"
    # Log-Ausgabe
    if [[ -w $logFile ]]; then
        echo "$(date "+%T") [INFO] $botTop" >> $logFile
        echo "$(date "+%T") [INFO] $midLog" >> $logFile
        echo "$(date "+%T") [INFO] $botTop" >> $logFile
    fi
}

# Funktion, um Namen des Skriptes als Überschrift auszugeben
startScript() {
    header "Starte Skript $0" -t 1
}

# Ende des Skriptes ausgeben
endScript() {
    header "Skript $0 erfolgreich beendet" -t 1 -f green
}

# Funktion zum installieren eines Paketes
installPkg() {
    # Nur installieren, falls noch nicht vorhanden oder aktualisierbar
    l_task=''
    if ! dpkg -l "$1" 2> /dev/null | grep -q ^ii; then
        l_task='installiert'
    elif apt list --upgradeable 2> /dev/null | grep -q " $1 "; then
        l_task='aktualisiert'
    fi
    if [[ $l_task != "" ]]; then
        info "Paket $1 wird $l_task"
        if [[ $EUID > 0 ]]; then
            sudo apt install $1 -y
        else
            apt install $1 -y
        fi
        if ! dpkg -l "$1" | grep -q ^ii; then
            # Nicht installiert -> Abbruch
            err "Paket $1 konnte nicht installiert werden."
        fi
    fi
}

# Funktion zum Sicherstellen, dass sudo verwendet wird
ensureRoot() {
    # prüfen der effektiven User ID
    if [[ $EUID > 0 ]]; then
        err "Rootrechte benötigt!\nAufruf: sudo $0"
    fi
}

# wie ensureRoot, nur dass ohne root gestartet werden muss
ensureNoRoot() {
    if [[ $EUID = 0 ]]; then
        err "Bitte ohne sudo starten!"
    fi
}

#=====================#
# Ausgeführte Befehle #
#=====================#

# Automatische Hilfefunktion
if [[ $helpStr != '' ]] && [[ $1 = '-h' || $1 = '--help' ]]; then
    echo -e $helpStr
    exit 0
fi

# Funny
if [[ $1 = '--unfunny' ]]; then
    shift 1
else
    if [[ ${SUDO_USER:-$USER} = 'mat' ]]; then
        info "Ähh... Dodelido"
    else
        info "Why does the image go to jail?"
        warn "Because it was framed"
    fi
fi

# Log-Datei als Parameter
if [[ $1 = '--logFile' ]]; then
    logFile=$2
    shift 2
fi

# Erstellen der Log-Datei
if ! [[ -z $logFile || -f $logFile ]]; then
    touch $logFile
    if [[ $EUID = 0 ]]; then
        chown ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} $logFile
    fi
    info "Log-Datei $logFile erstellt"
fi

# Nutzung:
# 1. Shell-skrpit inkludieren, Befehl:
# . "$( dirname "${BASH_SOURCE[0]}" )/common.sh"
# 2. Funktionen aufrufen
# info "Starte das Skript"
# installPkg openssh-server
# err "Installation abgebrochen"
