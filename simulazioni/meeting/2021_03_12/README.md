# Guida esercitazione aggiornamento 12/03/2021 

## Premessa

Questa guida è stata costruita riducendo tutti i passaggi. Per una guida più esaustiva si invita a leggere il documento in fase di redazione a questa pagina.

Tutto il processo avverrà a partire dalle 16.00 (15.00 UTC) del 12/03/2021.      
Per chi sta utilizzando il kms verifciare [in fondo la procedura da adottare](#kms).      
I passaggi prima del punto 3 possono essere eseguiti prima dell'orario. Nell'aggiornamento ufficiale si invita a predisporre tutta una serie di configurazioni per rendere il lavoro il più agevole possibile, anche sulla base di questa guida.    
Nel processo di aggiornamento **bisogna fermarsi al punto 8**  e al **punto 10** per poter confrontare il checksum del nuovo genesis per non avere genesis differenti tra i vari nodi validatori.    

**Chiunque usi un `tmkms` deve leggere obbligatoriamente la [sezione dedicata ai kms](#kms)** 

## Prerequisiti

Installare jq: usare il comando 

```bash
apt install jq -y
```

Controllare la versione di `go` che sia almeno `1.15+`

## 1) Configurare i path e le variabili 

Impostare le variabili di ambiente per l'aggiornamento. **NB: I dati sono variabili da ambiente ad ambiente e quindi le configurazioni vanno adattate**

```bash
cd
echo 'export HOME_CND="/root/.cnd"' > env_update_chain_meeting.txt
echo 'export HOME_CND_CONFIG="$HOME_CND/config"' >> env_update_chain_meeting.txt
echo 'export HOME_CND_DATA="$HOME_CND/data"' >> env_update_chain_meeting.txt
echo 'export APP_TOML="$HOME_CND_CONFIG/app.toml"' >> env_update_chain_meeting.txt
echo 'export BIN_DIR="/root/go/bin"' >> env_update_chain_meeting.txt
echo 'export SRC_GIT_DIR="/root/commercionetwork"' >> env_update_chain_meeting.txt
echo 'export BUILD_DIR="$SRC_GIT_DIR/build"' >> env_update_chain_meeting.txt
echo 'export NEW_CHAIN_ID="commercio-meeting02"' >> env_update_chain_meeting.txt
echo 'export NEW_GENESIS_TIME="2020-06-12T08:55:00Z"' >> env_update_chain_meeting.txt
echo 'export ALT_BLOCK=<DA COMUNICARE>' >> env_update_chain_meeting.txt
echo 'export VERSIONE_BINARI=master' >> env_update_chain_meeting.txt
echo 'export VERSIONE_BUILD="2.2.0-pre.2"' >> env_update_chain_meeting.txt

source ./env_update_chain_meeting.txt

echo '. /root/env_update_chain_meeting.txt' >> ~/.profile
```

provare a eseguire sconnettersi dal nodo e ricollegarsi verificando che le variabili vengono impostate.

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
sed -e "s|halt-height = .*|halt-height = $ALT_BLOCK|g" $APP_TOML > $APP_TOML.tmp; mv $APP_TOML.tmp $APP_TOML
systemctl restart cnd
```

**Questo operazione dovrebbe essere eseguita su tutti i nodi validatori e full-node (sentry compresi).**


### 4) Controllo dell'effettivo stop della chain 

Per verificare che effettivamente la chain sia bloccata verificare con la lettura dei logs    

```bash
journalctl -u cnd -f
```

## 5) Assicurarsi di aver stoppato servizi

```bash
systemctl stop cnd
systemctl stop cncli
pkill cnd
pkill cncli
```

## 6) Eseguire l'esportazione della chain

```bash
cnd export --for-zero-height > export_meeting01_genesis.json
```

## 7) Creare un salvataggio dei dati della chain e delle configurazioni

```bash
mv $HOME_CND_DATA data_backup_meeting01
cp -r $HOME_CND_CONFIG config_backup_meeting01
```

## 8) Controllare sul gruppo Telegram se l'export corrisponde  

```bash
jq -S -c -M '' export_meeting01_genesis.json | shasum -a 256
```


## 8) Cambiare i binari

```bash
git clone https://github.com/commercionetwork/commercionetwork.git
cd commercionetwork
git checkout v2.2.0-pre.2
make GENERATE=0 build # Long time to compile
$BUILD_DIR/cnd version
```
Il comando dovrebbe visualizzare i seguenti dati
```
name: commercionetwork
server_name: cnd
client_name: cndcli
version: 2.2.0-pre.2
commit: fab7f1d723466f02e5fa58b0d6e30ce09f8c24e3
build_tags: netgo,ledger
go: go version go1.15.8 linux/amd64
```
Se la versione e il tag corrisponde possiamo installarlo sulle nostre cartelle

```bash
cp $BUILD_DIR/cn* $BIN_DIR/.
```

## 9) Eseguire la migrazione

```bash
cd
$BIN_DIR/cnd migrate v2.2.0 ./export_meeting01_genesis.json \
--chain-id=$NEW_CHAIN_ID \
--genesis-time=$NEW_GENESIS_TIME \
> ./genesis.json
```

Validare il nuovo genesis

```bash
$BIN_DIR/cnd validate-genesis ./genesis.json
```

**ATTENZIONE**: se il nuovo genesis non dovesse essere validato il migrate non avverrà e si dovrà far partire nuovamente la chain

## 10) Verificare il nuovo genesis con gli altri validatori. 

**ATTENZIONE**: se il nuovo genesis non dovesse essere verificato il migrate non avverrà e si dovrà far partire nuovamente la chain

```bash
jq -S -c -M '' genesis.json | shasum -a 256
```


## 11) Reset della chain

```bash
cnd unsafe-reset-all
```

## 12) Sostituzione del genesis

```bash
cp genesis.json $HOME_CND_CONFIG
```

## 13) Ripartenza della chain

```bash
sed -e "s|halt-height = .*|halt-height = 0|g" $APP_TOML > $APP_TOML.tmp; mv $APP_TOML.tmp $APP_TOML
systemctl start cnd
```

## 14) La nuova chain dovrebbe ripartire all'orario fissato nel genesis time 

```bash
journalctl -u cnd -f
```


# KMS

In questa sezione viene indicato come aggiornare i kms basati su yubihsm e tmkms.   
Si precisa che si tratta di linne guida, ed è essenziale capire il processo che qui viene sintetizzato

1. Deve essere aggiornato il software
2. Devono essere modificate le configurazioni dei servizi di `tmkms` per poter operare con il nuovo core della chain
3. Tutto può essere preparato in precedenza: predisporre già i file con le configurazioni aggiornate in modo che al momento dell'upgrade della chain l'unica cosa da fare sia fermare i servizi e sostituire le configurazioni. Le precedenti configurazioni poi possono essere salvata in maniera da poterle recuperare velocemente nel caso di problemi.


## Aggiornamento tmkms prima dell'aggiornamento chain 

I kms possono essere aggiornati anche prima della procedura della chain.     

**ATTENZIONE**: __L'Aggiornamento dei tmkms prima dell'aggiornamento della chain è solo una procedura che rende più rapida poi le operazioni in fase di update, ma può essere svolta anche durante l'aggiornamento della chain.__

### Aggiornare tutti i service dei tmkms
1. Fermare il servizio `cnd` sul nodo validatore
    ```bash
   sudo systemctl stop cnd
   ```
2. Fermare i servizi `tmkms` 
   ```bash
   sudo systemctl stop tmkms-node
   ```
   dove `tmkms-node` è qualunque servzio associato a un qualsiasi nodo validatore.
3. Aggiornare il software
   ```bash
   rustup update
   cargo version
   ```

   la versione dovrebbe essere `1.50+`

   ```bash
   cargo install tmkms --features=yubihsm --locked --force --version=0.10.0
   tmkms version
   ```

   la versione dovrebbe essere `0.10.0`
4. Modificare le configurazioni
   Nella sezione `[[validator]]` dei vari file toml del validatore aggiungere `protocol_version = "legacy"`
   ```toml
   [[validator]]
   .....
   protocol_version = "legacy" 
   ```

5. Avviare il servizi `tmkms`
   ```bash
   sudo systemctl start tmkms-node
   ```
6. Avviare i nodi validatori
    ```bash
   sudo systemctl start cnd
   ```
7. Controllora se il sign viene eseguito


### Aggiornare un service per volta 
In questo caso possono essere aggiornati i nodi uno alla volta

1. Aggiornare il software sui kms
   ```bash
   rustup update
   cargo version
   ```

   la versione dovrebbe essere `1.50+`

   ```bash
   cargo install tmkms --features=yubihsm --locked \
     --force --version=0.10.0 \
     --target-dir /data_tmkms/tmkms/V010 \
     --root /data_tmkms/tmkms/V010
   /data_tmkms/tmkms/V010/bin/tmkms version
   ```
   la versione dovrebbe essere `0.10.0`

2. Aggiornare i file di configurazione
   ```bash
   cp tmkms-node.toml tmkms-nodeV010.toml
   ```
   Nella sezione `[[validator]]` dei vari file toml del validatore aggiungere `protocol_version = "legacy"`
   ```toml
   [[validator]]
   .....
   protocol_version = "legacy" 
   ```
3. Aggiornare i service
   Cambiare in `/etc/systemctl/system/tmkms-node.service`

   ```conf
   ExecStart=/data_tmkms/tmkms/V010/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms-nodeV010.toml
   ```
1. Fermare il demonee del sul nodo validatore
    ```bash
   sudo systemctl stop cnd
   ```
2. Fermare il servizi `tmkms` 
   ```bash
   sudo systemctl stop tmkms-node
   ```
1. Fare un reload del servizio `tmkms`
5. Avviare il servizio `tmkms`
   ```bash
   sudo systemctl start tmkms-node
   ```
6. Avviare il servizio sul nodo validatore
   ```bash
   sudo systemctl start cnd
   ```
7. Controllora se il sign viene eseguito


## Aggiornamento tmkms prima dell'aggiornamento chain 

### Aggiornarnamento software e servizi
Chiunque abbia svolto preliminarmente le operazioni vada direttamente alla sezione [Aggiornamento configurazioni](#aggiornamento-configurazioni)


1. Assicurarsi che il servizio sul validatore sia fermo con il seguente comando
    ```bash
   sudo systemctl stop cnd
   ```
2. Fermare i servizi `tmkms` 
   ```bash
   sudo systemctl stop tmkms-node
   ```
   dove `tmkms-node` è qualunque servzio associato a un qualsiasi nodo validatore.
3. Aggiornare il software
   ```bash
   rustup update
   cargo version
   ```

   la versione dovrebbe essere `1.50+`

   ```bash
   cargo install tmkms --features=yubihsm --locked --force --version=0.10.0
   tmkms version
   ```

   la versione dovrebbe essere `0.10.0`
4. Modificare le configurazioni
   Nella sezione `[[validator]]` dei vari file toml del validatore aggiungere `protocol_version = "0.33"`
   ```toml
   [[validator]]
   .....
   protocol_version = "v0.33" 
   ```
   
   Dovunque sia indicato `commercio-meeting01`, ossia l'id della chain, cambiare in `commercio-meeting02`

   Nella sezione `[[chain]]` cambiare la configurazione di `state_file` mettendo l'indicatore della chain
   ```toml
   [[chain]]
   .....
   state_file = "/path/to/cosmoshub_priv_validator_state-meeting02.json"
   ```
   **Alternativamente** potete lasciare le configurazioni e spostare il file di stato

   ```bash
   mv /path/to/cosmoshub_priv_validator_state.json /path/to/cosmoshub_priv_validator_state-backup.json
   ```
5. Avviare il servizi `tmkms`
   ```bash
   sudo systemctl start tmkms-node
   ```
6. Avviare i nodi validatori
    ```bash
   sudo systemctl start cnd
   ```
7. Controllora se il sign viene eseguito


### Aggiornamento configurazioni
Questa sezione riguarda solo chi ha precedentemente eseguito l'aggiornamento del software del `tmkms` 

1. Assicurarsi che il servizio sul validatore sia fermo con il seguente comando
    ```bash
   sudo systemctl stop cnd
   ```
2. Fermare i servizi `tmkms` 
   ```bash
   sudo systemctl stop tmkms-node
   ```
   dove `tmkms-node` è qualunque servzio associato a un qualsiasi nodo validatore.
4. Modificare le configurazioni
   Nella sezione `[[validator]]` dei vari file toml del validatore aggiungere `protocol_version = "0.33"`
   ```toml
   [[validator]]
   .....
   protocol_version = "v0.33" 
   ```

   Dovunque sia indicato `commercio-meeting01`, ossia l'id della chain, cambiare in `commercio-meeting02`


   Nella sezione `[[chain]]` cambiare la configurazione di `state_file` mettendo l'indicatore della chain
   ```toml
   [[chain]]
   .....
   state_file = "/path/to/cosmoshub_priv_validator_state-meeting02.json"
   ```
   **Alternativamente** potete lasciare le configurazioni e spostare il file di stato

   ```bash
   mv /path/to/cosmoshub_priv_validator_state.json /path/to/cosmoshub_priv_validator_state-backup.json
   ```
5. Avviare il servizi `tmkms`
   ```bash
   sudo systemctl start tmkms-node
   ```
6. Avviare i nodi validatori
    ```bash
   sudo systemctl start cnd
   ```
7. Controllora se il sign viene eseguito


