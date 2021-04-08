# Installazione validatore con KMS

## Premessa

Tutte le azioni illustrate in questo parte e nella successiva guida per il validator node possono essere svolte utilizzando dei tools di automazione tipo ansible, puppet, chef ecc. ecc.

Tutte le automazioni però hanno una certa dipendenza da come verrà strutturata la rete dei nodi e quindi potrebbero variare a secondo di chi deve svolgere l’installazione e gestirla. Di seguito sono date delle istruzioni standard con qualche comando di automazione in semplice script shell.

Anche per l’eventuale installazione di macchine virtuali in cloud è preferibile usare sistemi tipo terraform o simili.

I concetti illustrati in questa sezione riguardano l'installazione di un singolo nodo validatore, e per l'installazione di un ulteriore nodo validatore semplicemente, devono essere eseguiti gli stessi passi cambiando naturalmente i parametri.     

Se si sta usando un kms con chiavi multiple, quindi, si dovranno predisporre più nodi, e le configurazioni dei kms dovranno variare di conseguenza per ogni chiave, puntando al nodo relativo.    

La fonte primaria di documentazione sull'installazione di un full-node e di un validatore è https://docs.commercio.network

## Creazione ambiente

Per la gestione del nodo non si dovrebbe usare un utente privilegiato tipo `root`, e quindi si dvorebbe procedere alla creazione di un utente non privilegiato e privo di shell. Es.  

```bash 
mkdir /opt/cnd
sudo useradd -m -d /opt/cnd --system --shell /usr/sbin/nologin cnd
sudo -u cnd mkdir -p /opt/cnd/config
```

In questa modo abbiamo creato la home per il nostro nodo validatore che sarà appunto la cartella `/opt/cnd`


## Scaricamento dati della chain

Selezionare la versione della chain attuale. Nel codice seguente sarà `<chain-version>`. Alla stesura di questa guida la versione della chain attuale è la `commercio-2_2`.

```bash 
CHAIN_VERSION=<chain-version>
cd
# Nel caso fossero state fatte altre installazioni
rm -rf commercio-chains
# Scaricamento del repo delle chains
git clone https://github.com/commercionetwork/chains.git commercio-chains
CHAIN_DATA_FOLDER=”$HOME/commercio-chains/$CHAIN_VERSION”
CHAIN_DATA_FILE=”$CHAIN_DATA_FOLDER/.data”
CHAIN_VERSION=commercio-$(cat $CHAIN_DATA_FILE | grep -oP 'Name\s+\K\S+')
CHAIN_BIN_RELEASE=commercio-$(cat $CHAIN_DATA_FILE | grep -oP 'Release\s+\K\S+')
CHAIN_PER_PEERS=commercio-$(cat $CHAIN_DATA_FILE | grep -oP 'Persistent peers\s+\K\S+')
CHAIN_SEEDS=commercio-$(cat $CHAIN_DATA_FILE | grep -oP 'Seeds\s+\K\S+')
CHAIN_GEN_CHECKSUM=commercio-$(cat $CHAIN_DATA_FILE | grep -oP Genesis Checksum\s+\K\S+')
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
sed -e "s|seeds = \".*\"|seeds = \"$CHAIN_SEEDS\"|g" \ >
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

Per creare il nodo validatore possiamo partire dallo stesso tipo di installazione del sentry node.


### Configurazione nodo con KMS

Configurare il nome che si vuole attribuire al nodo (i sentry node di default prendono il nome host).


NODENAME="**nome_nodo**"

Accedere ai sentry node e ottenere gli id. Per ogni sentry node usare il comando

```sh 
sudo printf $(/bin/cnd tendermint show-node-id --home /opt/cnd)@$(ifconfig | fgrep "inet " | fgrep -v "127.0.0.1" | fgrep "10.1." | fgrep -v "10.1.1" | awk '{print $2}'):26656 > node_id.$(/bin/cnd tendermint show-node-id --home /opt/cnd).txt
``` 
	


<img src="img/attetion.png" width="30"> **Attenzione**: in questo comando si è supposto che il sentry node sia su una rete separata rispetto alla vpn del validator node e del kms. Le istruzioni in grassetto hanno questa implicazione. Questa estrazione delle informazioni è strettamente legato alla struttura delle rete che si sta implementando e che generalmente non può essere omogenea in generale sulle varie installazione di nodi.

E’ necessario modificare la configurazione del nodo validatore  in modo che il KMS possa connettersi e che possa connettersi ai sentry node.

Ottenere le informazioni del validator node

```sh 
sudo printf $(/bin/cnd tendermint show-node-id --home /opt/cnd)@$(ifconfig | fgrep "inet " | fgrep -v "127.0.0.1" | fgrep "10.1.1" | awk '{print $2}'):26656 > node_id.val.txt
```

Ottenere le configurazioni dai sentry node

```sh 
for S_NODE in $LIST_S_NODES; do
scp $S_NODE:node_id* .
done
```

Costruire la stringa di configurazione per il config.toml

```sh 
for S_NODE_INFO  in node_id*; do
S_NODES_IDS=$S_NODES_IDS”,”$S_NODE_INFO
done
```

Immettere le configurazioni nel config.toml del nodo validatore

```sh 
sudo sed -e "s|priv_validator_key_file = 
\"config/priv_validator_key.json\"|#priv_validator_key_file = \"config/priv_validator_key.json\"|g" /opt/cnd/config/config.toml | \
sed -e "s|#priv_validator_laddr = \"tcp://.*:26658\"|priv_validator_laddr = \"tcp://10.1.1.254:26658\"|g" | \
sed -e "s|moniker = \".*\"|moniker = \"$NODENAME\"|g" | \ 
sed -e "s|persistent_peers = \"(.*)\"|persistent_peers = \"\1$S_NODES_IDS\"|g" | \
sed -e "s|pex = \".*\"|pex = \"false\"|g" | \
sed -e "s|addr_book_strict = \".*\"|addr_book_strict = \"false\"|g" > \
/opt/cnd/config/config.toml.tmp
sudo mv /opt/cnd/config/config.toml.tmp /opt/cnd/config/config.toml
sudo chown -R cnd /opt/cnd
```


<img src="img/attetion.png" width="30"> **Attenzione**: non deve essere fatto ripartire il validator node in questo momento, perché dobbiamo ancora trasferire le informazioni del nodo validatore ai nodi sentry, per non diffondere le proprie informazioni

Trasferire le informazioni del validator node ai senry node

```sh 
for S_NODE in $LIST_S_NODES; do
  scp node_id.val.txt $S_NODE:.
done
```

Per ogni sentry node deve essere inserito nelle configurazioni le informazioni del validator node per non diffonderle nella rete p2p

```sh 
sed -e "s|private_peer_ids = \".*\"|private_peer_ids = \"$(cat node_id.val.txt)\"|g" /opt/cnd/config/config.toml > /opt/cnd/config/config.toml.tmp
sudo mv /opt/cnd/config/config.toml.tmp /opt/cnd/config/config.toml
sudo chown -R cnd /opt/cnd
sudo systemctl stop cnd; sleep 7; sudo systemctl start cnd
```

Avviare il nodo validatore

```sh 
sudo systemctl start cnd
``` 

Controllare l’output dei logs del kms dovrebbero variare in questa maniera

```log 
Jan 11 09:23:14.389  INFO tmkms::session: [commercio-testnet6002@tcp://10.1.1.254:26658] connected to validator successfully
Jan 11 09:23:14.389  WARN tmkms::session: [commercio-testnet6002] tcp:/10.1.1.254:26658: unverified validator peer ID! (A312D8F64C9FC71A1A947C377F64B7302C951361)
```


Controllare l’output dei logs del validator node. Dovrebbero riportare il funzionamento normale. Se qualcosa non funziona i blocchi in teoria non dovrebbero poter essere rilasciati


## Creazione sulla chain nodo Validator Node

Se tutti i passaggi sono corretti e il nodo validatore funziona correttamente si può eseguire la transazione di creazione del nodo validatore.

Da qualsiasi postazione dotata del client cncli, il wallet, e un accesso a un full node possiamo lanciare il comando di creazione del nodo

```sh 
cncli tx staking create-validator \
  --amount=50000000000ucommercio \
  --pubkey=did:com:valconspub1zcjduepq592mn6xucyqvfrvjegruhnx55cruffkrfq0rryu809fzkgwg684qmetxxs \
  --moniker="nome_nodo" \
  --chain-id="commercio-testnet6002" \ 
  --details="nodo validatore di Commercio" \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --from=did:com:1zcjduep… \
  --node=tcp://10.1.2.1:26657 \
  --fees=10000ucommercio \
  -y
```

Dove

*   **--pubkey**: la chiave pubblica del validatore fornita dal kms
*   **--moniker**: Nome del nodo
*   **--chain-id**: Id della chain per cui si sta creando il nodo (parametro non necessario se nelle configurazioni del client è già stato inserito)
*   **--from**: wallet contenente i token da delegare al validatore
*   **--node**: un full node a cui si ha accesso con la porta 26657 in ascolto

Se la transazione di creazione del nodo è andata a buon fine i logs del kms dovrebbe cominciare a mostrare le operazioni di PreVote e PreCommit.


## Considerazioni
