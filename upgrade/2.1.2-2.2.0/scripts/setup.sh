#!/bin/bash

ask_param () {
 echo "Inserisci $message"
 read answer
 export $parameter=$answer
 #var="$parameter"
 #echo ${!var}
}
NEW_GENESIS_TIME="2021-03-12T15:15:00Z"
NEW_CHAIN_ID="commercio-2_2"
ALT_BLOCK="58750"
VERSIONE_BUILD="v2.2.0"


messages=(
  "Inserisci il path del file di configurazione da creare (es. /home/utente/env_update_2.2.0.txt): "
  "Inserisci home del servizio cnd (es. /home/utente(.cnd)): "
  "Inserisci il path dei binari del cnd (es. /home/utente/go/bin): "
  "Inserisci path dove scaricare i sorgenti (es. /home/utente/commercionetwork): "
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


for k in ${!messages[@]}; do
  message=${messages[$k]}
  parameter=${params[$k]}
  ask_param
done


echo "[Ok] Questi i tuoi parametri"
echo " File di env"
echo "  $ENV_FILE"

echo "[OK] Creerò il file con i seguenti parametri"
printf "\n\n"
echo "export HOME_CND=\"$HOME_CND\""
echo "export HOME_CND_CONFIG=\"$HOME_CND/config\""
echo "export HOME_CND_DATA=\"$HOME_CND/data\""
echo "export APP_TOML=\"$HOME_CND_CONFIG/app.toml\""
echo "export BIN_DIR=\"$BIN_DIR\""
echo "export SRC_GIT_DIR=\"$SRC_GIT_DIR\""
echo "export BUILD_DIR=\"$SRC_GIT_DIR/build\""
echo "export NEW_CHAIN_ID=\"$NEW_CHAIN_ID\""
echo "export NEW_GENESIS_TIME=\"$NEW_GENESIS_TIME\""
echo "export ALT_BLOCK=$ALT_BLOCK"
echo "export VERSIONE_BUILD=\"$VERSIONE_BUILD\""

echo "Confermi i dati?"
