# Guida aggiornamento 22/03/2021 
# ATTENZIONE LE ISTRUZIONI SONO ANCORA IN FASE DI REDAZIONE: IL PARAMETRI NON SOSNO ANCORA QUELLI UFFICIALI


- [Guida aggiornamento 22/03/2021](#guida-aggiornamento-22032021)
- [ATTENZIONE LE ISTRUZIONI SONO ANCORA IN FASE DI REDAZIONE: IL PARAMETRI NON SOSNO ANCORA QUELLI UFFICIALI](#attenzione-le-istruzioni-sono-ancora-in-fase-di-redazione-il-parametri-non-sosno-ancora-quelli-ufficiali)
  - [Premessa](#premessa)
  - [Aggiornamento validator](#aggiornamento-validator)
    - [Prerequisiti](#prerequisiti)
    - [1) Configurare i path e le variabili](#1-configurare-i-path-e-le-variabili)
    - [2) Compilare i nuovi binari](#2-compilare-i-nuovi-binari)
    - [3) Impostare l'altezza di stop della chain (si bloccherà in automatico)](#3-impostare-laltezza-di-stop-della-chain-si-bloccherà-in-automatico)
    - [4) Controllo dell'effettivo stop della chain](#4-controllo-delleffettivo-stop-della-chain)
    - [5) Assicurarsi di aver stoppato servizi](#5-assicurarsi-di-aver-stoppato-servizi)
    - [6) Eseguire l'esportazione della chain](#6-eseguire-lesportazione-della-chain)
    - [7) Creare un salvataggio dei dati della chain e delle configurazioni](#7-creare-un-salvataggio-dei-dati-della-chain-e-delle-configurazioni)
    - [8) Controllare sul gruppo Telegram se l'export corrisponde](#8-controllare-sul-gruppo-telegram-se-lexport-corrisponde)
    - [9) Cambiare i binari](#9-cambiare-i-binari)
    - [10) Eseguire la migrazione](#10-eseguire-la-migrazione)
    - [11) Verificare il nuovo genesis con gli altri validatori.](#11-verificare-il-nuovo-genesis-con-gli-altri-validatori)
    - [12) Reset della chain](#12-reset-della-chain)
    - [13) Sostituzione del genesis e dei file di configurazione](#13-sostituzione-del-genesis-e-dei-file-di-configurazione)
    - [14) Ripartenza della chain](#14-ripartenza-della-chain)
    - [15) La nuova chain dovrebbe ripartire all'orario fissato nel genesis time](#15-la-nuova-chain-dovrebbe-ripartire-allorario-fissato-nel-genesis-time)
  - [Full node (sentry)](#full-node-sentry)
    - [1) Configurare i path e le variabili](#1-configurare-i-path-e-le-variabili-1)
    - [2) Compilare i nuovi binari](#2-compilare-i-nuovi-binari-1)
    - [3) Impostare l'altezza di stop della chain (si bloccherà in automatico)](#3-impostare-laltezza-di-stop-della-chain-si-bloccherà-in-automatico-1)
    - [4) Controllo dell'effettivo stop della chain](#4-controllo-delleffettivo-stop-della-chain-1)
    - [5) Assicurarsi di aver stoppato servizi](#5-assicurarsi-di-aver-stoppato-servizi-1)
    - [6) Creare un salvataggio dei dati della chain e delle configurazioni](#6-creare-un-salvataggio-dei-dati-della-chain-e-delle-configurazioni)
    - [7) Reset della chain](#7-reset-della-chain)
    - [8) Sostituzione del genesis e dei file di configurazione](#8-sostituzione-del-genesis-e-dei-file-di-configurazione)
    - [9) Condivisione informazioni full node](#9-condivisione-informazioni-full-node)
    - [10) Ripartenza della chain](#10-ripartenza-della-chain)
    - [11) La nuova chain dovrebbe ripartire all'orario fissato nel genesis time](#11-la-nuova-chain-dovrebbe-ripartire-allorario-fissato-nel-genesis-time)
  - [Ripristino](#ripristino)


## Premessa

Questa guida è stata costruita riducendo tutti i passaggi. Per una guida più descrittiva si invita a leggere il documento in fase di redazione in [questa pagina](./upgrade.md).

Tutto il processo avverrà a partire dalle 16.00 (15.00 UTC) del 22/03/2021.      
**Chiunque usi un `tmkms` deve leggere obbligatoriamente le seguenti guide**
* [Nodo singolo](./aggiornamento-tmkms.md)  
* [Nodo multiplo](./aggiornamento-tmkms-chiavi-multiple.md)  

I passaggi fino al punto 3 **DEVONO** essere eseguiti prima dell'orario.    
Si invita a predisporre tutta una serie di configurazioni per rendere il lavoro il più agevole possibile, anche sulla base di questa guida.    
Nel processo di aggiornamento **bisogna fermarsi al punto 8**  e al **punto 10** per poter confrontare il checksum del nuovo genesis per non avere genesis differenti tra i vari nodi validatori.    

**Chiunque usi un `tmkms` deve leggere obbligatoriamente la [sezione dedicata ai kms](#kms)** 


## Aggiornamento validator

### Prerequisiti

Installare jq: usare il comando 

```bash
apt install jq -y
```

Controllare la versione di `go` che sia almeno `1.15+`

### 1) Configurare i path e le variabili 

Impostare le variabili di ambiente per l'aggiornamento. **NB: I dati sono variabili da ambiente ad ambiente e quindi le configurazioni vanno adattate**

```bash
cd
ENV_FILE="~/env_update_chain_2.2.0.txt"
echo 'export HOME_CND="/root/.cnd"' > $ENV_FILE
echo 'export HOME_CND_CONFIG="$HOME_CND/config"' >> $ENV_FILE
echo 'export HOME_CND_DATA="$HOME_CND/data"' >> $ENV_FILE
echo 'export APP_TOML="$HOME_CND_CONFIG/app.toml"' >> $ENV_FILE
echo 'export BIN_DIR="/root/go/bin"' >> $ENV_FILE
echo 'export SRC_GIT_DIR="/root/commercionetwork"' >> $ENV_FILE
echo 'export BUILD_DIR="$SRC_GIT_DIR/build"' >> $ENV_FILE
echo 'export NEW_CHAIN_ID="commercio-meeting02"' >> $ENV_FILE
echo 'export NEW_GENESIS_TIME="2021-03-12T15:15:00Z"' >> $ENV_FILE
echo 'export ALT_BLOCK=<DA COMUNICARE>' >> $ENV_FILE
echo 'export VERSIONE_BINARI=master' >> $ENV_FILE
echo 'export VERSIONE_BUILD="v2.2.0"' >> $ENV_FILE

source $ENV_FILE

echo ". $ENV_FILE" >> ~/.profile
```

provare a disconnettersi dal nodo e ricollegarsi verificando che le variabili vengono impostate.

### 2) Compilare i nuovi binari

Se non è già stato scaricato clonare il repository

```bash
git clone https://github.com/commercionetwork/commercionetwork.git $SRC_GIT_DIR
```

Cambiare cartella ed eseguire il build

```bash
cd $SRC_GIT_DIR
git pull
git checkout $VERSIONE_BUILD
git pull
make GENERATE=0 build
./build/cnd version  --long
#dovrebbe corrispondere a $VERSIONE_BUILD
```
Il comando dovrebbe visualizzare i seguenti dati
```
name: commercionetwork
server_name: cnd
client_name: cndcli
version: 2.2.0
commit: <DA COMUNICARE>
build_tags: netgo,ledger
go: go version go1.15.8 linux/amd64
```


### 3) Impostare l'altezza di stop della chain (si bloccherà in automatico)

```bash
cd
sed -e "s|halt-height = .*|halt-height = $ALT_BLOCK|g" $APP_TOML > $APP_TOML.tmp; mv $APP_TOML.tmp $APP_TOML
systemctl restart cnd
```

**Questo operazione DEVE essere eseguita su tutti i nodi validatori e full-node (sentry compresi) prima della data di aggiornamento.**


### 4) Controllo dell'effettivo stop della chain 

Per verificare che effettivamente la chain sia bloccata verificare con la lettura dei logs    

```bash
journalctl -u cnd -f
```

### 5) Assicurarsi di aver stoppato servizi

```bash
sudo systemctl stop cnd
sudo systemctl stop cncli
sudo pkill cnd
sudo pkill cncli
```

### 6) Eseguire l'esportazione della chain

```bash
cnd export --for-zero-height > ~/commercio-2_1_genesis_export.json
```

### 7) Creare un salvataggio dei dati della chain e delle configurazioni

```bash
mkdir -p ~/data_backup/bin
mv $HOME_CND_DATA ~/data_backup/.
cp -r $HOME_CND_CONFIG data_backup/.
cp $BIN_DIR/cn* ~/data_backup/bin/.
```

### 8) Controllare sul gruppo Telegram se l'export corrisponde  

```bash
jq -S -c -M '' ~/commercio-2_1_genesis_export.json | shasum -a 256
```

**ATTENZIONE**: se il nuovo genesis non dovesse essere **verificato** il migrate non avverrà e si dovrà far partire nuovamente la chain


### 9) Cambiare i binari


```bash
cp $BUILD_DIR/cn* $BIN_DIR/.
```

### 10) Eseguire la migrazione

```bash
cd
$BIN_DIR/cnd migrate v2.2.0 ~/ommercio-2_1_genesis_export.json \
--chain-id=$NEW_CHAIN_ID \
--genesis-time=$NEW_GENESIS_TIME \
> ~/genesis.json
```

Validare il nuovo genesis

```bash
$BIN_DIR/cnd validate-genesis ~/genesis.json
```

**ATTENZIONE**: se il nuovo genesis non dovesse essere **validato** il migrate non avverrà e si dovrà far partire nuovamente la chain

### 11) Verificare il nuovo genesis con gli altri validatori. 


```bash
jq -S -c -M '' ~/genesis.json | shasum -a 256
```

**ATTENZIONE**: se il nuovo genesis non dovesse essere **verificato** il migrate non avverrà e si dovrà far partire nuovamente la chain


### 12) Reset della chain

```bash
$BIN_DIR/cnd unsafe-reset-all --home $HOME_CND_CONFIG
```

### 13) Sostituzione del genesis e dei file di configurazione

```bash
cp genesis.json $HOME_CND_CONFIG
```

Creare un template con i nuovi file di configurazione `toml`

```bash
$BIN_DIR/cnd init templ --home $BUILD_DIR/template_home
```
e copiare i template nella cartella ufficiale

```bash
cp $BUILD_DIR/template_home/config/app.toml $APP_TOML
```


### 14) Ripartenza della chain

Quando si sono completate le operazioni e sono presenti un buon numero di peer persistenti lanciare il comando

```bash
systemctl start cnd
```

### 15) La nuova chain dovrebbe ripartire all'orario fissato nel genesis time 

```bash
journalctl -u cnd -f
```
Ci potrebbe essere un periodo in cui bisogna attendere che si raggiunga il consenso, che potrebbe andare oltre il genesis time.

## Full node (sentry)

### 1) Configurare i path e le variabili 

Impostare le variabili di ambiente per l'aggiornamento. **NB: I dati sono variabili da ambiente ad ambiente e quindi le configurazioni vanno adattate**

```bash
cd
ENV_FILE="~/env_update_chain_2.2.0.txt"
echo 'export HOME_CND="/root/.cnd"' > $ENV_FILE
echo 'export HOME_CND_CONFIG="$HOME_CND/config"' >> $ENV_FILE
echo 'export HOME_CND_DATA="$HOME_CND/data"' >> $ENV_FILE
echo 'export APP_TOML="$HOME_CND_CONFIG/app.toml"' >> $ENV_FILE
echo 'export BIN_DIR="/root/go/bin"' >> $ENV_FILE
echo 'export SRC_GIT_DIR="/root/commercionetwork"' >> $ENV_FILE
echo 'export BUILD_DIR="$SRC_GIT_DIR/build"' >> $ENV_FILE
echo 'export NEW_CHAIN_ID="commercio-meeting02"' >> $ENV_FILE
echo 'export NEW_GENESIS_TIME="2021-03-12T15:15:00Z"' >> $ENV_FILE
echo 'export ALT_BLOCK=<DA COMUNICARE>' >> $ENV_FILE
echo 'export VERSIONE_BINARI=master' >> $ENV_FILE
echo 'export VERSIONE_BUILD="v2.2.0"' >> $ENV_FILE

source $ENV_FILE

echo ". $ENV_FILE" >> ~/.profile
```

provare a disconnettersi dal nodo e ricollegarsi verificando che le variabili vengono impostate.

### 2) Compilare i nuovi binari


Se sono già stati compilati i binari potete direttamente copiare i binari nei path dei precedenti binari.   
I binari possono essere anche copiati da un'altra macchina (validatore ad esempio) con la stessa architettura della macchina del full node.

Se non è già stato scaricato clonare il repository

```bash
git clone https://github.com/commercionetwork/commercionetwork.git $SRC_GIT_DIR
```

Cambiare cartella ed eseguire il build

```bash
cd $SRC_GIT_DIR
git pull
git checkout $VERSIONE_BUILD
git pull
make GENERATE=0 build
./build/cnd version  --long
#dovrebbe corrispondere a $VERSIONE_BUILD
```
Il comando dovrebbe visualizzare i seguenti dati
```
name: commercionetwork
server_name: cnd
client_name: cndcli
version: 2.2.0
commit: <DA COMUNICARE>
build_tags: netgo,ledger
go: go version go1.15.8 linux/amd64
```


### 3) Impostare l'altezza di stop della chain (si bloccherà in automatico)

```bash
cd
sed -e "s|halt-height = .*|halt-height = $ALT_BLOCK|g" $APP_TOML > $APP_TOML.tmp; mv $APP_TOML.tmp $APP_TOML
systemctl restart cnd
```

**Questo operazione DEVE essere eseguita su tutti i nodi validatori e full-node (sentry compresi) prima della data di aggiornamento.**


### 4) Controllo dell'effettivo stop della chain 

Per verificare che effettivamente la chain sia bloccata verificare con la lettura dei logs    

```bash
journalctl -u cnd -f
```

### 5) Assicurarsi di aver stoppato servizi

```bash
sudo systemctl stop cnd
sudo systemctl stop cncli
sudo pkill cnd
sudo pkill cncli
```


### 6) Creare un salvataggio dei dati della chain e delle configurazioni

```bash
mkdir -p ~/data_backup/bin
mv $HOME_CND_DATA ~/data_backup/.
cp -r $HOME_CND_CONFIG data_backup/.
cp $BIN_DIR/cn* ~/data_backup/bin/.
```

### 7) Reset della chain

```bash
$BIN_DIR/cnd unsafe-reset-all --home $HOME_CND_CONFIG
```

### 8) Sostituzione del genesis e dei file di configurazione

Da un nodo validatore o dal repo della chains copiare il genesis.

```bash
scp <UTENTE VALIDATORE>@<IP VALIDATORE>:$HOME_CND_CONFIG/genesis.json $HOME_CND_CONFIG/.
```

Creare un template con i nuovi file di configurazione `toml`

```bash
$BIN_DIR/cnd init templ --home $BUILD_DIR/template_home
```
e copiare i template nella cartella ufficiale

```bash
cp $BUILD_DIR/template_home/config/app.toml $APP_TOML
```


### 9) Condivisione informazioni full node

Lanciare il comando

```bash
echo $($BIN_DIR/cnd tendermint show-node-id --home $HOME_CND)@$(wget -qO- icanhazip.com):26656
```

Il risultato del comando sono quelli che faranno da peer persistenti per la nuova chain. Condividere il dato su

`https://hackmd.io/<DA COMUNICARE>` 

Al file di configurazione `config.toml` vanno aggiunti i vari `persistent_peers`.    
Questa procedura mette la chain in condizione di collegare i nodi tra loro più velocemente.   
Se non presente aggiungere sempre nel file `~/.cnd/config/config.toml` anche il proprio ip pubblico nel parametro `external_address` in questa maniera
```toml
external_address="tcp://<IP PUBBLICO>:26656"
```



### 10) Ripartenza della chain

Quando si sono completate le operazioni e sono presenti un buon numero di peer persistenti lanciare il comando

```bash
systemctl start cnd
```

### 11) La nuova chain dovrebbe ripartire all'orario fissato nel genesis time 

```bash
journalctl -u cnd -f
```
Ci potrebbe essere un periodo in cui bisogna attendere che si raggiunga il consenso, che potrebbe andare oltre il genesis time.

## Ripristino
