# Guida aggiornamento chain da commercio-devnet02 a commercio-devnet03

## Premessa

Tutto il processo avverrà alle 10.40 ora italiano = 8.40 UTC.     
Dovreste eseguire tutti i passaggi fino al punto 3 anche prima dello scadere dell'orario.    
Nel processo di aggiornamento **bisogna fermarsi al punto 8** per poter confrontare il checksum del nuovo genesis per non avere genesis diffrenti tra i vari nodi validatori.    

## Prerequisiti

Installare jq: usare il comando 

```bash
apt install jq -y
```

## 1) Configurare i path e le variabili 

(ricordarsi di ricaricarle ad ogni login o creare un file da cui fare il source: source ./nome_file)

```bash
export HOME_CND="/root/.cnd"
export HOME_CND_CONFIG="$HOME_CND/config"
export HOME_CND_DATA="$HOME_CND/data"
export APP_TOML="$HOME_CND_CONFIG/app.toml"
export BIN_DIR="/root/go/bin"
export SRC_GIT_DIR="/root/commercionetwork" #Cambiare
export BUILD_DIR="$SRC_GIT_DIR/build"
export NEW_CHAIN_ID="commercio-devnet03"
export NEW_GENESIS_TIME="2020-06-12T08:25:00Z"
export ALT_BLOCK=55904
export VERSIONE_BINARI=master
export VERSIONE_BUILD="2.1.1-15-g8d591614"
```

Eventualmente creare il file e impostarlo 

```bash
cd
echo 'export HOME_CND="/root/.cnd"' > env_update_chain.txt
echo 'export HOME_CND_CONFIG="$HOME_CND/config"' >> env_update_chain.txt
echo 'export HOME_CND_DATA="$HOME_CND/data"' >> env_update_chain.txt
echo 'export APP_TOML="$HOME_CND_CONFIG/app.toml"' >> env_update_chain.txt
echo 'export BIN_DIR="/root/go/bin"' >> env_update_chain.txt
echo 'export SRC_GIT_DIR="/root/commercionetwork"' >> env_update_chain.txt
echo 'export BUILD_DIR="$SRC_GIT_DIR/build"' >> env_update_chain.txt
echo 'export NEW_CHAIN_ID="commercio-devnet03"' >> env_update_chain.txt
echo 'export NEW_GENESIS_TIME="2020-06-12T08:55:00Z"' >> env_update_chain.txt
echo 'export ALT_BLOCK=55904' >> env_update_chain.txt
echo 'export VERSIONE_BINARI=master' >> env_update_chain.txt
echo 'export VERSIONE_BUILD="2.1.1-15-g8d591614"' >> env_update_chain.txt

source ./env_update_chain.txt

echo '. /root/env_update_chain.txt' >> ~/.profile

```



## 2) Compilare i nuovi binari

Se non è già stato scaricato clonare il repository

```bash
git clone https://github.com/commercionetwork/commercionetwork.git $SRC_GIT_DIR
```

Cambiare cartella ed eseguire il build

```bash
cd $SRC_GIT_DIR
git pull
git checkout $VERSIONE_BINARI
git pull
make build
./build/cnd version
#dovrebbe corrispondere a $VERSIONE_BUILD
cd
```

### 3) Impostare l'altezza di stop della chain (si bloccherà in automatico)

```bash
sed -e "s|halt-height = .*|halt-height = $ALT_BLOCK|g" $APP_TOML > $APP_TOML.tmp; mv $APP_TOML.tmp $APP_TOML; service cnd stop; service cnd start
```


### 4) Controllo dell'effettivo stop della chain 

Dopo il blocco: dovrebbe apparire un messaggio di stop delle chain al blocco indicato.     
Il blocco dovrebbe essere fissato per 15 minuti prima del nuovo geneis time, ossia alle 10.40.    
Per verificare che effettivamente la chain sia bloccata verificare con la lettura dei logs    

```bash
journalctl -u cnd -f
```

## 5) Assicurarsi di aver stoppato servizi e eseguire l'esportazione della chain

```bash
service cnd stop
service cncli stop
pkill cnd
pkill cncli
```

Esporate la chain

```bash
cnd export --for-zero-height > export_for_03.json
```


## 6) Cambiare i binari

```bash
cp $BUILD_DIR/cn* $BIN_DIR/.
```

## 7) Eseguire la migrazione

```bash
cat export_for_03.json | jq '.genesis_time="'$NEW_GENESIS_TIME'"' | jq '.chain_id="'$NEW_CHAIN_ID'"' > new_genesis_2_3.json
```

## 8) Verificare il nuovo genesis con gli altri validatori. 

**ATTENZIONE**: se il nuovo genesis non dovesse essere verificato il migrate non avverrà e si dovrà far partire nuovamente la chain

```bash
jq -S -c -M '' new_genesis_2_3.json | shasum -a 256
```

## 9) Creare un salvataggio dei dati della chain e delle configurazioni

```bash
mv  $HOME_CND_DATA data_backup_chain_02_03
cp -r $HOME_CND_CONFIG config_backup_chain2_02_03
```

## 10) Reset della chain

```bash
cnd unsafe-reset-all
```

## 11) Sostituzione del genesis

```bash
cp new_genesis_2_3.json $HOME_CND_CONFIG/genesis.json
```

## 12) Ripartenza della chain

```bash
sed -e "s|halt-height = .*|halt-height = 0|g" $APP_TOML > $APP_TOML.tmp; mv $APP_TOML.tmp $APP_TOML; service cnd start
```

## 13) La nuova chain dovrebbe ripartire all'orario fissato nel genesis time 

```bash
journalctl -u cnd -f
```
