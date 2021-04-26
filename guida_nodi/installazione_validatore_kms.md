# Installazione validatore con KMS

## Premessa

Tutte le azioni illustrate in questo parte e nella successiva guida per il validator node possono essere svolte utilizzando dei tools di automazione tipo ansible, puppet, chef ecc. ecc.

Tutte le automazioni però hanno una certa dipendenza da come verrà strutturata la rete dei nodi e quindi potrebbero variare a secondo di chi deve svolgere l’installazione e gestirla. Di seguito sono date delle istruzioni standard con qualche comando di automazione in semplice script shell.

Anche per l’eventuale installazione di macchine virtuali in cloud è preferibile usare sistemi tipo terraform o simili.

I concetti illustrati in questa sezione riguardano l'installazione di un singolo nodo validatore, e per l'installazione di un ulteriore nodo validatore semplicemente, devono essere eseguiti gli stessi passi cambiando naturalmente i parametri.     

Se si sta usando un kms con chiavi multiple, quindi, si dovranno predisporre più nodi, e le configurazioni dei kms dovranno variare di conseguenza per ogni chiave, puntando al nodo relativo.    

La fonte primaria di documentazione sull'installazione di un full-node e di un validatore è https://docs.commercio.network

## Creazione ambiente

Per la gestione del nodo non si dovrebbe usare un utente privilegiato tipo `root`, e quindi si dovrebbe procedere alla creazione di un utente non privilegiato e privo di shell. Es.  

```bash 
sudo mkdir /opt/cnd
sudo useradd -m -d /opt/cnd --system --shell /usr/sbin/nologin cnd
sudo chown -R cnd:cnd /opt/cnd
sudo -u cnd mkdir -p /opt/cnd/config
```

In questa modo abbiamo creato la home per il nostro nodo validatore che sarà appunto la cartella `/opt/cnd`


## Scaricamento dati della chain

Selezionare la versione della chain attuale. Nel codice seguente sarà `<chain-version>`. Alla stesura di questa guida la versione della chain attuale è la `commercio-2_2`. Se invece si vuole utilizzare la chain di testnet alla stesuara della guida la versione è `commercio-testnet10k2`.

Consultare il [repo delle chains](https://github.com/commercionetwork/chains) per sapere sempre quale siano le chain attuali

```bash 
CHAIN_VERSION=<chain-version>
cd
# Nel caso fossero state fatte altre installazioni
rm -rf commercio-chains
# Scaricamento del repo delle chains
git clone https://github.com/commercionetwork/chains.git commercio-chains
CHAIN_DATA_FOLDER="$HOME/commercio-chains/$CHAIN_VERSION"
CHAIN_DATA_FILE="$CHAIN_DATA_FOLDER/.data"
CHAIN_VERSION=commercio-$(cat $CHAIN_DATA_FILE | grep -oP 'Name\s+\K\S+')
CHAIN_BIN_RELEASE=$(cat $CHAIN_DATA_FILE | grep -oP 'Release\s+\K\S+')
CHAIN_PER_PEERS=$(cat $CHAIN_DATA_FILE | grep -oP 'Persistent peers\s+\K\S+')
CHAIN_SEEDS=$(cat $CHAIN_DATA_FILE | grep -oP 'Seeds\s+\K\S+')
CHAIN_GEN_CHECKSUM=$(cat $CHAIN_DATA_FILE | grep -oP 'Genesis Checksum\s+\K\S+')
```

## Installazione binari

I binari si possono installare eseguendo la compilazione dai sorgenti (vedi https://docs.commercio.network), oppure scaricando i compilati da github.

```bash
cd
wget "https://github.com/commercionetwork/commercionetwork/releases/download/$CHAIN_BIN_RELEASE/Linux-AMD64.zip"
unzip -o Linux-AMD64.zip 
# Installazione degli eseguibili su path standard. In questo modo possono essere trovati come comando di sistema
sudo cp cn* /bin/
```

I binari possono essere compilati in qualsiasi ambiente con la stessa architettura della macchina di destinazione, quindi nella fattispecie Linux con tecnologia del processore a 64bit Intel/AMD, e poi trasferiti sulla macchina destinazione.

## Installazione configurazioni

Eseguire un reset della chain (questo inizializza anche la struttura delle cartelle) e installare le configurazioni della chain che si sta installando.

```bash
sudo -u cnd /bin/cnd unsafe-reset-all --home=/opt/cnd
sudo cp $CHAIN_DATA_FOLDER/genesis.json /opt/cnd/config/.

sudo sed -e "s|persistent_peers = \".*\"|persistent_peers = \"$CHAIN_PER_PEERS\"|g" /opt/cnd/config/config.toml | \
   sed -e "s|addr_book_strict = \".*\"|addr_book_strict = \"false\"|g" | \
   sed -e "s|seeds = \".*\"|seeds = \"$CHAIN_SEEDS\"|g" > \
   /opt/cnd/config/config.toml.tmp

sudo mv /opt/cnd/config/config.toml.tmp /opt/cnd/config/config.toml
```


## Installazione di un dump (opzionale ma consigliato)

Per evitare di attendere un lungo processo di sincronizzazione è possibile scaricare un dump dello stato della chain nella cartella `/opt/cnd/data`. Il consorzio mette a disposizione un servizio di quicksync a tal fine


```bash
cd
mkdir dump
wget "https://quicksync.commercio.network/$CHAIN_VERSION.latest.tgz" -P dump
cd dump
tar -zxf $CHAIN_VERSION.latest.tgz
sudo rm -rf /opt/cnd/data
sudo mv -r data /opt/cnd/.
```

## Finalizzazione permessi

Cambiare i permessi della home dell’utente cnd. Se non viene eseguito questo comando il nodo non funzionerà

```bash 
sudo chown -R cnd:cnd /opt/cnd
```


## Creazione e avvio del service

```bash 
sudo tee /etc/systemd/system/cnd.service > /dev/null <<EOF
[Unit]
Description=Commercio Node
After=network-online.target

[Service]
User=cnd
ExecStart=/bin/cnd start --home=/opt/cnd/
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable cnd
sudo systemctl start cnd
```

Verificando con il comando

```bash
sudo journalctl -u cnd -f
```
si dovrebbero vedere i blocchi che vengono elaborati dal nodo. Un output di questo tipo dovrebbe essere visibile

```log
Aug 13 16:30:20 commerciotestnet-node4 cnd[351]: I[2019-08-13|16:30:20.722] Executed block                               module=state height=1 validTxs=0 invalidTxs=0
Aug 13 16:30:20 commerciotestnet-node4 cnd[351]: I[2019-08-13|16:30:20.728] Committed state                              module=state height=1 txs=0 appHash=9815044185EB222CE9084AA467A156DFE6B4A0B1BAAC6751DE86BB31C83C4B08
Aug 13 16:30:20 commerciotestnet-node4 cnd[351]: I[2019-08-13|16:30:20.745] Executed block                               module=state height=2 validTxs=0 invalidTxs=0
Aug 13 16:30:20 commerciotestnet-node4 cnd[351]: I[2019-08-13|16:30:20.751] Committed state                              module=state height=2 txs=0 appHash=96BFD9C8714A79193A7913E5F091470691B195E1E6F028BC46D6B1423F7508A5
Aug 13 16:30:20 commerciotestnet-node4 cnd[351]: I[2019-08-13|16:30:20.771] Executed block                               module=state height=3 validTxs=0 invalidTxs=0
```

Premere `ctrl + c` per interrompere.


## Configurazione Validator Node

Per creare il nodo validatore possiamo partire dallo stesso tipo di installazione del sentry node/full node.    
Consultare la [guida ufficiale](http://docs.commercio.network) per i dettagli delle transazioni di creazione del nodo validatore.   


### Configurazione nodo validatore vs nodi sentry

Generalmente il nodo validatore non deve essere esposto sulla rete pubblica, ma deve accedere solo a nodi fidati, e questi ultimi devono essere esposti alla rete globale.    
Riferendosi ai [concetti generali](./concetti_generali.md) prenderemo in esame il caso `Doppio kms/Doppio validatore/Nodi Sentry`.     
Per semplicità considereremo solo il kms attivo e il validatore attivo.    
Inizialmente devono essere installati i nodi sentry: il loro funzionamento non dipende dal nodo validatore, ma solo sull'esistenza della chain.   
Deve poi essere installato il validatore. Nella fase iniziale il validatore sarà solo un full node. Per poter funzionare il nodo validatore dovrà poter accedere ai sentry node, ossia i nodi fidati della struttura del validatore.   

Nel validatore devono essere implementate queste configurazioni nel file `config.toml`

| Configurazione | Valore | Descrizione | 
|--|--|--|
| `pex` | false | Impedisce di utilizzare il p2p per fare il crawling della rete | 
| `persistant_peers` | id_sentry01@ip_sentry01:26656,id_sentry02@ip_sentry02:26656 | La lista dei nodi persistenti. Per il nodo validatore dovranno essere **solo** i nodi fidati | 
| `seeds` |  | La lista dei seeds dovrà essere vuota | 
| `addr_book_strict` | false | Da impostare a false se alcuni nodi sono in una Lan privata | 

Per ottenere i valori di `id_sentry01` e `id_sentry02` usare il comando sui sentry stessi

```bash
/bin/cnd tendermint show-node-id --home /opt/cnd
```

Il comando dovrebbe dare in output l'id del nodo.   
`ip_sentry01` e `ip_sentry02` sono gli ip dei sentry accessibili dal validatore. Il validatore si presumo sia collegato ai sentry attraverso vpn, quindi gli ip non saranno quelli pubblici, ma quelli appunto della rete vpn.   


Sui sentry devono essere implementate queste configurazioni nel file `config.toml`

| Configurazione | Valore | Descrizione | 
|--|--|--|
| `pex` | false | Impedisce di utilizzare il p2p per fare il crawling della rete | 
| `persistant_peers` | id_validatore@ip_validatore:26656,id_other_nodes@ip_other_nodes:26656 | La lista dei nodi persistenti. Per il nodo validatore dovranno essere solo i nodi fidati | 
| `private_peer_ids` | id_validatore | Il parametro contiene la lista degli id da non diffondere nella rete. In questo caso sarà quello del nodo validatore | 
| `addr_book_strict` | false | Da impostare a false se alcuni nodi sono in una Lan privata | 


Analogamento sul validatore dobbiamo recuperare `id_validatore` usando il comando

```bash
/bin/cnd tendermint show-node-id --home /opt/cnd
```

`ip_validatore` è l'ip del validatore accessibile dai sentry, anche in questo caso si presumo quello della vpn.  

`id_other_nodes` e `ip_other_nodes` saranno gli id e gli ip già presenti sul file di configurazione recuperati dalle configurazioni del network ossia dal [repo delle chains](https://github.com/commercionetwork/chains)


Far ripartire i sentry con il comando

```bash 
sudo systemctl restart cnd
``` 

e poi avviare il validatore il validatore che dovrebbe sincronizzarsi con il comando

```bash 
sudo systemctl start cnd
``` 
Controllare la sincronizzazione sul validatore con il comando

```bash 
sudo journalctl -u cnd -f
``` 


### Configurazione nodo con KMS

Il concetto fondamentale del funzionamento del validatore è che debba poter accedere a una chiave privata per il sign dei blocchi rilasciati dalla chain.   
La chiave privata può essere fornita in varie maniere, ad esempio con un file oppure come nel caso che stiamo pre trattare attraverso un KMS.    
Fondamentale aver seguito la [guida per installazione kms per chiavi multiple](./installazione_tmkms_chiavi_multiple.md) o per [chiave singola](./installazione_tmkms.md) per procedere in questa fase.     

Sul file di configurazione del nodo validatore `/opt/cnd/config/config.toml` deve essere modificato il parametro di accesso alle chiavi di validazione.  
Sostituire

```toml
#priv_validator_laddr = "tcp://.*:26658"
```

con 

```toml
priv_validator_laddr = "tcp://<indirizzo validatore>:26658"
```

`<indirizzo validatore>` deve essere l'indirizzo del validatore che è stato impostato all'interno del file di configurazione del kms nel parametro `addr` sotto la sezione `[[validator]]`
Es.

```toml
...
[[validator]]
addr = "tcp://<indirizzo validatore>:26658"
...
```

**NB**: il kms agisce come client e non come server. Il kms non ha bisogno di avere nessuna porta aperta verso il validatore. E' il validatore che espone sulla porta `26658` l'ascolto della chiave privata.

Una volta modificata la configurazione si può far ripartire il nodo validatore con il comando

```bash 
sudo systemctl restart cnd
``` 


Controllare l’output dei logs del kms dovrebbero variare in questa maniera

```log 
Jan 11 09:23:14.389  INFO tmkms::session: [<chain-version>@tcp://<indirizzo validatore>:26658] connected to validator successfully
Jan 11 09:23:14.389  WARN tmkms::session: [<chain-version>] tcp:/<indirizzo validatore>:26658: unverified validator peer ID! (A312D8F64C9FC71A1A947C377F64B7302C951361)
```

Se l'output ha la dicitura `connected to validator successfully` il kms è correttamente collegato al validatore.


## Creazione validatore

Riferirsi alla [guida ufficiale](https://docs.commercio.network) per eseguire le transazioni per la creazione del validatore.

## Considerazioni

La guida è intesa per fare un setup della struttura del validatore, e non per spiegare il funzionamento della chain o delle sue transazioni.    
Spiegazioni sui messaggi sono da ricercare in guide differenti.   
Nei concetti generali si possono trovare alcuni esempi di tolpologie di nodi, e ognuno è libero di scegliere una propria configurazione.    
E' fondamentale semplicemente capire che il nodo validatore non è altro che un full node che accede a un particolare materiale crittografico, e lui e solo lui potrà accedervi.   
I nodi di supporto quali i sentry sono da intendersi appunto di supporto al funzionamento del nodo, per renderlo sicuro e robusto nell'ambito della rete globale.   
