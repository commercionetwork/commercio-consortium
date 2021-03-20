#!/bin/bash

ENV_FILE=$1

if [ ! "$1" ] || [ ! -f $ENV_FILE ]; then
    echo "[ERRORE] Non è presente il file di env. Ripetere la configurazione"
fi

. $ENV_FILE


commands=(
  "rm -rf $SRC_GIT_DIR"
  "git clone https://github.com/commercionetwork/commercionetwork.git $SRC_GIT_DIR"
  "cd $SRC_GIT_DIR && git pull && git checkout $VERSIONE_BUILD && git pull && make GENERATE=0 build"
  "$SRC_GIT_DIR/build/cnd version  --long"
  "sed -e \"s|halt-height = .*|halt-height = $ALT_BLOCK|g\" $APP_TOML > $APP_TOML.tmp; mv $APP_TOML.tmp $APP_TOML"
  #"git pull"
  #"git checkout $VERSIONE_BUILD"
  #"git pull"
  #"make GENERATE=0 build"
  #"./build/cnd version  --long"
)

echo "[OK] Vuoi verificare prima i comandi? (y/n)"
read ANSW
if [ "$ANSW" = "y" ] || [ "$ANSW" = "Y" ]; then
    printf "================================\n"
    for k in ${!commands[@]}; do
        echo ${commands[$k]}
    done
    printf "================================\n\n"
fi

echo "[OK] Procedo con il lancio dei comandi? (y/n)"
read ANSW
if [ "$ANSW" = "y" ] || [ "$ANSW" = "Y" ]; then
    for k in ${!commands[@]}; do
        echo "${commands[$k]}" | sh
    done

    echo "[OK] Sto per riavviare il nodo con il comando \"sudo systemctl restart cnd\" e subito dopo lancerò \"journalctl -u cnd -f\""
    sudo systemctl restart cnd
fi

exit

#```bash
#cd
#sed -e "s|halt-height =.*|halt-height = $ALT_BLOCK|g" $APP_TOML > $APP_TOML.tmp; mv $APP_TOML.tmp $APP_TOML
#sudo systemctl restart cnd
#```
