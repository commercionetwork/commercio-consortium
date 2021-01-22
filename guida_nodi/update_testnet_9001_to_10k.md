# Update da commercio-testnet9001 a commercio-testnet10k

## Contenuto

Il contenuto tratta il test di aggiornamento di un nodo dalla chain `commercio-testnet9001` alla `commercio-testnet10k`.     
La situazione esistente è un nodo spento sulla chain `commercio-testnet9001` che deve essere aggiornata alla nuova versione con aggiornamento relativo del **kms** associato dotato di **yubi-hsm**


## Operazioni da eseguire

Nel seguito le operazioni verranno distinte tra nodo validatore con l'indicazione `VAL`  e sul kms con l'indicazione `KMS`.
**NB**: si suppone che si stia lavorando con utente con sudo o privilegi di root

### 1. `VAL` Salvataggio database nodo validatore

Spegnere per prima cosa tutti i servizi

```bash
sudo systemctl stop cnd
sudo systemctl stop cncli
sudo pkill -9 cnd
sudo pkill -9 cncli
```
Eseguire una copia della cartella      
**NB**: si parte dal presupposto che i dati della chain siano all'interno della cartella `~/.cnd` se i dati sono su un altra cartella modificare di conseguenza.

```bash
mkdir ~/.cndBackup9001
cp -r ~/.cnd/config ~/.cndBackup9001/config
mv ~/.cnd/data ~/.cndBackup9001/data
```

### 2. `VAL` Ottenere nuovi sorgenti

Aggiornare l'ambiente

```bash
sudo apt update
sudo apt upgrade -y
```

Clonare il progetto della core di commercio network e spostarsi sul branch corretto
```bash
git clone https://github.com/commercionetwork/commercionetwork.git
cd commercionetwork
git checkout v2.2.0-pre.1
make install
```

Se il path per go è stato configurato correttamente si dovrebbe poter usare il comando 

```bash
cnd version
```

La versione dovrebbe risultare la **v2.2.0-pre.1**.   
Altrimenti i compilati saranno presenti su `~/go/bin/cnd`.    
Si veda [Installing the software requirements](https://docs.commercio.network/nodes/full-node-installation.html#_1-installing-the-software-requirements) se i path non sono configurati correttamente

### 3. `VAL` Installare le configurazioni della nuova chain

Scaricare il nuovo genesis
```bash
curl "https://raw.githubusercontent.com/commercionetwork/chains/master/commercio-testnet10k/genesis.json" > ~/.cnd/config/genesis.json
```

Cancellare il file di app.toml 
```bash
rm ~/.cnd/config/app.toml
```

Eseguire poi un reset della chain
```bash
cnd unsafe-reset-all
```


### 4. `KMS` Aggiornare il software per il kms

Fermare qualsiasi processo legato al tmkms

```bash
sudo systemctl stop tmkms
```

Se si sta utilizzando più service fermare i vari sistemi.    

Lanciare il comando
```bash
cargo install tmkms --features=yubihsm --locked --force --version=0.9.0
```

Verificare che la versione sia corretta con il comando
```bash
tmkms version
```

### 5. `KMS` Aggiornare le configurazioni

Nel file
```
/etc/systemd/system/tmkms.service
```

dovrebbe essere indicato il file di configurazione di cui si sta facendo uso nell'instruzione

```
ExecStart=/data_tmkms/tmkms/.cargo/bin/tmkms start -c /data_tmkms/tmkms/kms/tmkms.toml
```

Potete estrarre l'informazione con il seguente comando
```bash
fgrep "ExecStart" /etc/systemd/system/tmkms.service
```

Copiare il file originale
```bash
cp /data_tmkms/tmkms/kms/tmkms.toml /data_tmkms/tmkms/kms/tmkms.toml.testnet9001
```



A questo punto è possibile modificare la configurazione. La configurazione dovrebbe essere di questo tipo

```toml
[[chain]]
id = "commercio-testnet9001"
key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
state_file = "/data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state.json"

[[validator]]
addr = "tcp://10.10.10.10:26658" #ip del Validator Node
chain_id = "commercio-testnet9001"
reconnect = true # true is the default
secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection.key"

[[providers.yubihsm]]
adapter = { type = "usb" }
auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" } # è possibile immettere la password direttamente utilizzando il parametro password al posto di password_file
keys = [{ chain_ids = ["commercio-testnet9001"], key = 1 }]
serial_number = "1234567890" # identify serial number of a specific YubiHSM to connect to
```

Dove `10.10.10.10` è l'ip del validatore. Alcune configurazioni potrebbero variare a seconda dell'installazione eseguita.
Sostituire `commercio-testnet9001` con `commercio-testnet10k`.  
Rinominare il file indicato nella variabile `state_file` in un nuovo path. Nell'esempio

```bash
mv /data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state.json /data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state.json.9001
```

Sotto la riga   
```toml
secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection.key"
```   
aggiungere    
```toml
protocol_version = "v0.33"
```   

La configurazione risultante dovrebbe essere questa 


```toml
[[chain]]
id = "commercio-testnet10k"
key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
state_file = "/data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state.json"

[[validator]]
addr = "tcp://10.10.10.10:26658" #ip del Validator Node
chain_id = "commercio-testnet10k"
reconnect = true # true is the default
secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection.key"
protocol_version = "v0.33"

[[providers.yubihsm]]
adapter = { type = "usb" }
auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" } # è possibile immettere la password direttamente utilizzando il parametro password al posto di password_file
keys = [{ chain_ids = ["commercio-testnet10k"], key = 1 }]
serial_number = "1234567890" # identify serial number of a specific YubiHSM to connect to
```

### 6. `KMS` Avviare i servizi

A questo punto è possibile avviare i servizi

```bash
sudo systemctl start tmkms
```

Controllando i logs del servizio con il comando

```bash
sudo journalctl -u tmkms -f
```

Si dovrebbero visualizzare dei log di irraggiungibilità del nodo validatore: è normale.

### 7. `VAL` Sincronizzare e avviare il validatore

Per rendere più veloce la sincronizzazione si può utilizzare il servizio di quicksync: si tratta di un semplice servizio che mette a disposizione un tar.gz di un dump della chain.

```bash
wget "https://quicksync.commercio.network/commercio-testnet10k.latest.tgz" -P ~/.cnd/
cd ~/.cnd/
tar -zxf commercio-testnet10k.latest.tgz
```

A questo punto dovrebbe essere possibile far partire la chain

```bash
sudo systemctl start cnd
```

Controllare se il validatore si sta sincronizzando

```bash
sudo journalctl -u cnd -f
```
### 8. `KMS` Verifica kms


Controllando i logs del servizio con il comando

```bash
sudo journalctl -u tmkms -f
```

il kms ora dovrebbe riportare di essersi collegato al validatore.

### 9. `VAL` Unjail del nodo

Se il nodo è rimasto off-line per molto tempo è necessario eseguire una transazione di unjail.    
Controllare per prima cosa che il nodo abbia raggiunto l'altezza della chain.    
Su l'[explorer](https://testnet.commercio.network) della testnet si può visualizzare l'altezza.   
Confrontare con l'altezza raggiunta dal proprio nodo o con i log o con il comando 

```bash
cncli config chain-id commercio-testnet10k
cncli status | jq '.sync_info["latest_block_height"]' | tr -d '"'
```

Se il valore è in linea allora lanciare il seguento comando

```bash
cncli tx slashing \
  unjail \
  --from <your pub addr creator val> \
  --fees=10000ucommercio  \
  -y
```

dove `<your pub addr creator val>` è l'indirizzo del wallet utilizzato per creare il validatore.  Se la transazione è andata a buon fine il validatore dovrebbe riapparire sulla lista dei validatori nell'explorer.  

