#!/bin/bash

NEW_GENESIS_TIME="2021-03-12T15:15:00Z"
NEW_CHAIN_ID="commercio-2_2"
ALT_BLOCK="58750"
VERSIONE_BUILD="v2.2.0"

ask_param() {
    echo "Inserisci $message"
    read answer
    if [ ! "$answer" ]; then
        export $parameter=$def_parameter
    else
        export $parameter=$answer
    fi
    #var="$parameter"
    #echo ${!var}
}

messages=(
    "Inserisci il path del file di configurazione da creare (default /root/env_update_2.2.0.txt): "
    "Inserisci home del servizio cnd (default /root/.cnd): "
    "Inserisci il path dei binari del cnd (default /root/go/bin): "
    "Inserisci path dove scaricare i sorgenti (default /root/commercionetwork): "
    #"Inserisci il nuovo genesis time (es. 2021-03-12T15:15:00Z): "
    #"Inserisci il nuovo chain id (es. commercio-2_2): "
    #"Inserisci l'altezza di blocco (es. 58750): "
    #"Inserisci versione build (es. v2.2.0): "
)

params=(
    "ENV_FILE"
    "HOME_CND"
    "BIN_DIR"
    "SRC_GIT_DIR"
    #"NEW_GENESIS_TIME"
    #"NEW_CHAIN_ID"
    #"ALT_BLOCK"
    #"VERSIONE_BUILD"
)

def_params=(
    "/root/env_update_2.2.0.txt"
    "/root/.cnd"
    "/root/go/bin"
    "/root/commercionetwork"
    #"NEW_GENESIS_TIME"
    #"NEW_CHAIN_ID"
    #"ALT_BLOCK"
    #"VERSIONE_BUILD"
)

for k in ${!messages[@]}; do
    message=${messages[$k]}
    parameter=${params[$k]}
    def_parameter=${def_params[$k]}
    ask_param
done

echo "[Ok] Questi i tuoi parametri"
echo " File di env"
echo "  $ENV_FILE"

echo "[OK] Creerò il file con i seguenti parametri"
read -r -d '' SETUP_ENV <<END
export HOME_CND="$HOME_CND"
export HOME_CND_CONFIG="$HOME_CND/config"
export HOME_CND_DATA="$HOME_CND/data"
export APP_TOML="$HOME_CND_CONFIG/app.toml"
export BIN_DIR="$BIN_DIR"
export SRC_GIT_DIR="$SRC_GIT_DIR"
export BUILD_DIR="$SRC_GIT_DIR/build"
export NEW_CHAIN_ID="$NEW_CHAIN_ID"
export NEW_GENESIS_TIME="$NEW_GENESIS_TIME"
export ALT_BLOCK=$ALT_BLOCK
export VERSIONE_BUILD="$VERSIONE_BUILD"
END

printf "======================================\n\n"

echo "$SETUP_ENV"
printf "======================================\n\n"

echo "Confermi i dati? (y/n)"

read ANSW

if [ "$ANSW" = "y" ] || [ "$ANSW" = "Y" ]; then
    printf "[OK] Hai risposto di SI. Scrivo il file\n"
    CARTELLA_ENV=$(dirname $ENV_FILE)
    if [ ! -d "$CARTELLA_ENV" ]; then
        echo "Non esiste la cartella dell'env. Devo crearla (mkdir \"$CARTELLA_ENV\")? (y/n)"
        read ANSW
        if [ "$ANSW" = "y" ] || [ "$ANSW" = "Y" ]; then
            mkdir "$CARTELLA_ENV"
        fi
    fi
    touch $ENV_FILE
    tee $ENV_FILE > /dev/null <<EOF
$SETUP_ENV
EOF
else
    printf "[OK] Hai risposto di NO. puoi configurare manualmente l'env usando il comando\n\n"
    echo "tee $ENV_FILE > /dev/null <<EOF 
$SETUP_ENV
EOF
"
fi
