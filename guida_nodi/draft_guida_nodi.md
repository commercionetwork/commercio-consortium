# KMS YubiHSM - Nodo HW - Sentry DO


## By Marco Ruaro


# Versione 0.02 (DRAFT)


# Concetti generali


<table>
  <tr>
   <td><strong>Nome elemento</strong>
   </td>
   <td><strong>Significato</strong>
   </td>
   <td><strong>Descrizione</strong>
   </td>
  </tr>
  <tr>
   <td>KMS
   </td>
   <td>Key Management System
   </td>
   <td>Servizio preposto alla gestione delle chiavi
   </td>
  </tr>
  <tr>
   <td>HSM
   </td>
   <td>Hardware Secure Module
   </td>
   <td>Hardware per la segnatura utilizzato dal Kms
   </td>
  </tr>
  <tr>
   <td>Validator Node
   </td>
   <td>
   </td>
   <td>Nodo preposto alla validazione
   </td>
  </tr>
  <tr>
   <td>Sentry Node
   </td>
   <td>
   </td>
   <td>Nodo preposto alla connessione diretta alla chain sulla rete globale
   </td>
  </tr>
  <tr>
   <td>TmKms
   </td>
   <td>Tendermint Key Management System
   </td>
   <td>Servizio di Kms specifico per Tendermint
   </td>
  </tr>
</table>



# Installazione Kms -> Validator Node in Cloud (YubiHSM2)


## Requisiti



*   Server locale Kms
    *   Presa usb (preferibilmente interna)
    *   Sistema operativo Ubuntu 18.04. Il funzionamento è stato testato con tale sistema ma potrebbe funzionare con altri sistemi
    *   Accesso console protetto
*   Validator Node in Cloud 
    *   Sistema operativo Ubuntu 18.04
    *   Memoria minima 4Gb
    *   Spazio disco 100 Gb (espandibili in futuro)
    *   Senza accesso diretto in entrata a internet
*   Sentry Nodes (minimo 2)
    *   Sistema operativo Ubuntu 18.04
    *   Memoria minima 4Gb
    *   Spazio disco 100 Gb (espandibili in futuro)
*   Connessione vpn ridondante tra Kms e Validator Node in Cloud 
*   Connessione vpn, o protetta (lan privata) tra Validator Node e Sentry Node 
*   Connessione rete globale de Sentry Node 

**NB**: Le connessioni dovrebbero avere una velocità minima 100Mbit garantita.


## Schema di base/scenario

<img src="img/Kms2Cloud.jpg">


Per semplicità nella spiegazione possiamo supporre di avere una vpn che collega il Data Center con il Cloud con la classe di ip **10.1.1.0/24**.

L’ip del nodo validatore sarà **10.1.1.254**.

L’ip del kms sarà **10.1.1.1**.

Inoltre supponiamo che i sentry node siano su delle altre classi di ip, **10.1.2.0/24 per Regione 1** e **10.1.3.0/24 per Regione 2**

La protezione a livello di apertura porta sarà la seguente



*   **KMS**: nessuna porta aperta, solo accesso alla vpn verso il Validator node
*   **Validator Node**: porta in ascolto **sulla vpn limitata al KMS 26658. **Porta 26656 in ascolto sulle reti interne dei sentry node.
*   **Sentry Node**: Porta **26656** **in ascolto su tutti gli IP**. Porta **26657** **in ascolto in locale o su tutte gli ip ma con accesso limitato a specifici client** o mediata con un reverse proxy


## Configurazione server KMS


### Creazione utente nel server KMS

I comandi indicati di seguito devono essere eseguiti come **root.**

Se non si è già utente di root eseguire

```bash
sudo su - 

```

Lanciare i comandi per creare l’utente con cui eseguire le operazioni


    mkdir /data_tmkms


    useradd -m -d /data_tmkms/tmkms -G sudo tmkms -s /bin/bash


    echo 'SUBSYSTEMS=="usb", ATTRS{product}=="YubiHSM", GROUP=="tmkms"' >> /etc/udev/rules.d/10-yubihsm.rules


    reboot

**NB**: potrebbe essere necessario riavviare più volte il server per applicare 


### Installazione componenti

Predisposizione TmKms

Da questo momento in poi agiremo come utente **tmkms**. Tutti i comandi che necessitano di privilegi di root dovranno essere lanciati con **sudo**

Installazione compilatore c and git tools


    sudo apt install gcc git -y

Installazione libusb: sono necessarie per il funzionamento dell’**HSM**


    sudo apt install libusb-1.0-0-dev -y

Installazione rust: linguaggio per la compilazione del **TmKms**


    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh


    # Opzione 1


    source $HOME/.cargo/env

Installazione pkg-config


    sudo apt install pkg-config -y

Installazione **TmKms**


    cd $HOME


    git clone [https://github.com/tendermint/kms.git](https://github.com/tendermint/kms.git)


    cd $HOME/kms


    cargo install tmkms --features=yubihsm --locked --force

Controllo funzionamento


    tmkms version


### Installazione HSM

Inserire yubiHSM 2 nello slot usb preposto. Se il dispositivo è stato utilizzato precedentemente eseguire un reset tenendo premuto più di 3 secondi la ghiera metallica quando il dispositivo viene inserito. 


#### Configurazione TmKms [Nodo singolo]

Deve essere creato un file di configurazione tmkms.toml contenente le informazioni del nodo validatore a cui il Kms deve connettersi.

Potete trovare di seguito un file di esempio 

Creare la cartella per la configurazione

mkdir $HOME/kms/commercio

Usando l’utente tmkms la variabile $HOME corrisponde alla directory /data_tmkms/tmkms. Eventualmente usare direttamente il path completo /data_tmkms/tmkms.

Creare il file **$HOME/kms/commercio/tmkms.toml**.

** touch $HOME/kms/commercio/tmkms.toml**

Per la creazione del file bisogna avere i seguenti dati



*   **Chain-id**: è l’identificativo della chain per cui si sta configurando il nodo. Nel caso di testnet sarà **commercio-testnet6002**, nel caso di mainnet **commercio-mainnet**
*   Prefisso degli indirizzi pubblici della chain: nel caso di commercio sarà **did:com:**
*   Prefisso degli indirizzi pubblici dei nodi: nel caso di commercio sarà **did:com:valconspub**
*   Indirizzo all’interno della vpn del nodo validatore: per semplicità abbiamo supposto di avere l’indirizzo **10.1.1.254**.
*   La password del nostro dispositivo HSM: inizialmente la password è “password”
*   L’id della chiave da utilizzare del HSM: per la configurazione singola è 1
*   Il serial Number del nostro dispositivo: generalmente è quanto indicato nell’etichetta dello YubiHSM2. Devono essere 10 cifre. Per le cifre mancanti aggiungere degli zeri davanti al seriale.
*   Path delle configurazioni: configurare il path **/data_tmkms/tmkms/kms/commercio.**

[[chain]]

id = "**commercio-testnet6002**"

key_format = { type = "bech32", account_key_prefix = "**did:com:**", consensus_key_prefix = "**did:com:valconspub**" }

state_file = "**/data_tmkms/tmkms/kms/commercio/**commercio_priv_validator_state.json"

[[validator]]

addr = "tcp://**10.1.1.254**:26658" #ip del Validator Node

chain_id = "**commercio-testnet6002**"

reconnect = true # true is the default

secret_key = "**/data_tmkms/tmkms/kms/commercio/**secret_connection.key"

[[providers.yubihsm]]

adapter = { type = "usb" }

auth = { key = 1, password_file = "**/data_tmkms/tmkms/kms/**password" } # è possibile immettere la password direttamente utilizzando il parametro password al posto di password_file

keys = [{ chain_ids = ["**commercio-testnet6002**"], key = 1 }]

serial_number = "**9876543210**" # identify serial number of a specific YubiHSM to connect to


#### Configurazione HSM

Per una maggiore sicurezza deve essere fatto un reset dell’HSM.

NB: i passaggi a seguire dovrebbero essere realizzati off-line in ambiente riservato. Le informazioni in output dovrebbero essere trascritte e salvate su supporti da mantenere in luoghi sicuri

Creare il file /data_tmkms/tmkms/kms/password e inserire la password “password” al suo interno


    printf "password" > /data_tmkms/tmkms/kms/password


##### Reset dell’HSM

**Attenzione**: questa procedura farà un reset completo del device. Non deve essere fatta per un’eventuale seconda installazione di un altro nodo che fa usa dello stesso hsm


    tmkms yubihsm setup -c /data_tmkms/tmkms/kms/commercio/tmkms.toml

Un output di questo tipo dovrebbe apparire


    This process will *ERASE* the configured YubiHSM2 and reinitialize it:


    - YubiHSM serial: 9876543210


    Authentication keys with the following IDs and passwords will be created:


    - key 0x0001: admin:


        **<code>double section release consider diet pilot flip shell mother alone what fantasy</code></strong>


```
        much answer lottery crew nut reopen stereo square popular addict just animal
```



    - authkey 0x0002 [operator]:  kms-operator-password-1k02vtxh4ggxct5tngncc33rk9yy5yjhk


    - authkey 0x0003 [auditor]:   kms-auditor-password-1s0ynq69ezavnqgq84p0rkhxvkqm54ks9


    - authkey 0x0004 [validator]: kms-validator-password-1x4anf3n8vqkzm0klrwljhcx72sankcw0


    - wrapkey 0x0001 [primary]:   21a6ca8cfd5dbe9c26320b5c4935ff1e63b9ab54e2dfe24f66677aba8852be13


```
    *** Are you SURE you want erase and reinitialize this HSM? (y/N): y
```



    21:08:09 [WARN] factory resetting HSM device! all data will be lost!


    …….


    21:08:11 [WARN] deleting temporary setup authentication key from slot 65534


         Success reinitialized YubiHSM (serial: 9876543210)

Confermare quando viene richiesto di reinizializzare il dispositivo (in grassetto nell’output). Prendere nota dell’output, in special modo delle 24 parole fornite come nuova password (sempre in grassetto nell’output sopra riportato).

Salvare la nuova password del file 


    printf "**<code>double section release consider diet pilot flip shell mother alone what fantasy much answer lottery crew nut reopen stereo square popular addict just animal</code></strong>" >/data_tmkms/tmkms/kms/password

**NB**: La password viene fornita su due righe separate ma deve essere impostata nel file su una sola riga


#### Produzione chiave 

Lanciare il comando per produrre la nuova chiave. L’opzione -b permette di salvare la chiave


    tmkms yubihsm keys generate 1 -b steakz4u-validator-key.enc -c /data_tmkms/tmkms/kms/commercio/tmkms.toml

**Attenzione**: il file di backup steakz4u-validator-key.enc va subito trasferito su un supporto off-line e messo al sicuro. Se viene perso non potrà più essere replicata la chiave generata in questo momento.

Nel caso invece si voglia recuperare le chiavi utilizzare inizialmente su un nodo mediante file in chiaro si può utilizzare questo comando


    tmkms yubihsm keys import -t json -i 1 priv_validator.json -c /data_tmkms/tmkms/kms/commercio/tmkms.toml


#### Conferma presenza chiavi

Per confermare che le chiavi sono presenti e configurate nel HSM usare il comando


    tmkms yubihsm keys list  -c /data_tmkms/tmkms/kms/commercio/tmkms.toml

Dovrebbe essere presentato un output come il seguente


    Listing keys in YubiHSM #9876543210:


    - 0x0001: did:com:valconspub1zcjduepq592mn6xucyqvfrvjegruhnx55cruffkrfq0rryu809fzkgwg684qmetxxs

**did:com:valconspub1zcjduepq592mn6xucyqvfrvjegruhnx55cruffkrfq0rryu809fzkgwg684qmetxxs** sarà la chiave pubblica del nodo validatore. <span style="text-decoration:underline;">Questa chiave sarà necessaria per eseguire la transazione di creazione del nodo validatore</span>

**A QUESTO PUNTO IL KMS PUO’ ESSERE CONNESSO ALLA VPN**


### Avvio servizio KMS


#### Test avvio servizio

Deve essere testato il funzionamento del KMS


    tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms.toml

Un output simile a questo dovrebbe apparire.


    Mar 05 12:20:26.781  INFO tmkms::commands::start: tmkms 0.7.2 starting up…


    Mar 05 12:20:27.280  INFO tmkms::keyring: [keyring:yubihsm] added consensus key did:com:valconspub1zcjduepq592mn6xucyqvfrvjegruhnx55cruffkrfq0rryu809fzkgwg684qmetxxs


    Mar 05 12:20:27.280  INFO tmkms::connection::tcp: KMS node ID: 4248B5C7755600D694C47ECEA710A2DAB743AA38


```
    Mar 05 12:20:58.682 ERROR tmkms::client: [commercio-testnet6002@tcp://10.1.1.254:26658] I/O error: Connection timed out (os error 110)
```



    Mar 05 12:20:59.683  INFO tmkms::connection::tcp: KMS node ID: 4248B5C7755600D694C47ECEA710A2DAB743AA38


    ….

<span style="text-decoration:underline;">Se l’output riporta errori diversi dal semplice fallimento della connessione allora deve essere controllata l’installazione.</span>

**NB**: Il tentativo di connessione fallisce perché non abbiamo ancora configurato il nodo a cui il kms dovrebbe connettersi.

**crtl+c **per interrompere il processo.


#### Configurare il service

Configurare il service del Kms per farlo partire in automatico


    sudo tee /etc/systemd/system/tmkms.service > /dev/null &lt;<EOF 


```
    [Unit]
    Description=Commercio tmkms
    After=network.target

    [Service]
    User=tmkms
    WorkingDirectory=/data_tmkms/tmkms/.cargo/bin
    ExecStart=/data_tmkms/tmkms/.cargo/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms.toml
    Restart=always
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=tmkms
    RestartSec=3
    LimitNOFILE=4096

    [Install]
    WantedBy=multi-user.target
```



    EOF


    sudo systemctl enable tmkms


    sudo systemctl start tmkms


#### Configurazione TmKms [Nodo multiplo]

Devono anche essere installati degli strumenti aggiuntivi propri dello yubihsm per poter gestire il collegamento come servizio e non direttamente su usb.

Installare le utility di yubico (usare utente root)


    wget https://developers.yubico.com/YubiHSM2/Releases/yubihsm2-sdk-2019-12-ubuntu1804-amd64.tar.gz


    tar zxf yubihsm2-sdk-2019-12-ubuntu1804-amd64.tar.gz 


    sudo apt install ./yubihsm2-sdk/*.deb

Attivare il service


    sudo tee /etc/systemd/system/yubihsm-connector.service > /dev/null &lt;<EOF 


    [Unit]


    Description=YubiHSM connector


    Documentation=https://developers.yubico.com/YubiHSM2/Component_Reference/yubihsm-connector/


    After=network-online.target


    Wants=network-online.target systemd-networkd-wait-online.service


    [Service]


    Restart=on-abnormal


    User=tmkms


    Group=tmkms


    ExecStart=/usr/bin/yubihsm-connector -c /etc/yubihsm-connector.yaml


    PrivateTmp=true


    ProtectHome=true


    ProtectSystem=full


    [Install]


    WantedBy=multi-user.target


    EOF


    systemctl enable yubihsm-connector.service


    systemctl start yubihsm-connector.service

Subito dopo devono essere creati una serie di file con tante chiavi quante sono il numero di nodi da supportare. 

Ad esempio creare il file /data_tmkms/tmkms/kms/commercio/tmkms1.toml per il primo nodo **10.1.1.1**

[[chain]]

id = "**commercio-testnet6002**"

key_format = { type = "bech32", account_key_prefix = "**did:com:**", consensus_key_prefix = "**did:com:valconspub**" }

state_file = "**/data_tmkms/tmkms/kms/commercio/**commercio_priv_validator_state**1**.json"

[[validator]]

addr = "tcp://**10.1.1.1**:26658" #ip del Validator Node

chain_id = "**commercio-testnet6002**"

reconnect = true # true is the default

secret_key = "**/data_tmkms/tmkms/kms/commercio/**secret_connection**1**.key"

[[providers.yubihsm]]

#adapter = { type = "usb" }

**adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }**

auth = { key = 1, password_file = "**/data_tmkms/tmkms/kms/**password" } # è possibile immettere la password direttamente utilizzando il parametro password al posto di password_file

keys = [{ chain_ids = ["**commercio-testnet6002**"], key = **1** }]

serial_number = "**9876543210**" # identify serial number of a specific YubiHSM to connect to

Creare il file /data_tmkms/tmkms/kms/commercio/tmkms2.toml per il secondo nodo **10.1.1.2**

[[chain]]

id = "**commercio-testnet6002**"

key_format = { type = "bech32", account_key_prefix = "**did:com:**", consensus_key_prefix = "**did:com:valconspub**" }

state_file = "**/data_tmkms/tmkms/kms/commercio/**commercio_priv_validator_state**2**.json"

[[validator]]

addr = "tcp://**10.1.1.2**:26658" #ip del Validator Node

chain_id = "**commercio-testnet6002**"

reconnect = true # true is the default

secret_key = "**/data_tmkms/tmkms/kms/commercio/**secret_connection**2**.key"

[[providers.yubihsm]]

#adapter = { type = "usb" }

**adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }**

auth = { key = 1, password_file = "**/data_tmkms/tmkms/kms/**password" } # è possibile immettere la password direttamente utilizzando il parametro password al posto di password_file

keys = [{ chain_ids = ["**commercio-testnet6002**"], key = **2** }]

serial_number = "**9876543210**" # identify serial number of a specific YubiHSM to connect to

Devono essere cambiati i seguenti parametri per ogni file 


    **state_file: ** non deve essere lo stesso altrimenti si incorrerebbe nella doppia segnature


    **addr**: deve essere quello del nodo validatore interessato dalla segnatura


    **secret_key**: meglio separare ogni secret key della connessione al nodo validatore


    **keys->key**: la chiave deve essere quella che si vuole utilizzare

Nei file deve essere impostato l’adapter 


    **adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }**

Commentare o togliere 


    **adapter = { type = "usb" }**

Generare le chiavi (con backup)


    tmkms yubihsm keys generate 1 -b tmkms1.enc -c /data_tmkms/tmkms/kms/commercio/tmkms1.toml


    tmkms yubihsm keys generate 2 -b tmkms2.enc -c /data_tmkms/tmkms/kms/commercio/tmkms2.toml

Testare i servizi

tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms1.toml

tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms2.toml

Per verificare le chiavi usare

tmkms yubihsm keys list  -c /data_tmkms/tmkms/kms/commercio/tmkms1.toml

tmkms yubihsm keys list  -c /data_tmkms/tmkms/kms/commercio/tmkms2.toml

Creare i service per i nuovi client kms


    sudo tee /etc/systemd/system/tmkms1.service > /dev/null &lt;<EOF 


```
    [Unit]
    Description=Commercio tmkms 1
    After=network.target

    [Service]
    User=tmkms
    WorkingDirectory=/data_tmkms/tmkms/.cargo/bin
    ExecStart=/data_tmkms/tmkms/.cargo/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms1.toml
    Restart=always
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=tmkms1
    RestartSec=3
    LimitNOFILE=4096

    [Install]
    WantedBy=multi-user.target
```



    EOF


    sudo systemctl enable tmkms1


    sudo systemctl start tmkms1


    journalctl -u tmkms1.service -f


    sudo tee /etc/systemd/system/tmkms2.service > /dev/null &lt;<EOF 


```
    [Unit]
    Description=Commercio tmkms 2
    After=network.target

    [Service]
    User=tmkms
    WorkingDirectory=/data_tmkms/tmkms/.cargo/bin
    ExecStart=/data_tmkms/tmkms/.cargo/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms2.toml
    Restart=always
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=tmkms2
    RestartSec=3
    LimitNOFILE=4096

    [Install]
    WantedBy=multi-user.target
```



    EOF


    sudo systemctl enable tmkms2


    sudo systemctl start tmkms2


    journalctl -u tmkms2.service -f


## Configurazione Full/Sentry Node


### Premessa

Tutte le azioni illustrate in questo parte e nella successiva guida per il validator node possono essere svolte utilizzando dei tools di automazione tipo ansible, puppet, chef ecc. ecc.

Tutte le automazioni però hanno una certa dipendenza da come verrà strutturata la rete dei nodi e quindi potrebbero variare a secondo di chi deve svolgere l’installazione e gestirla. Di seguito sono date delle istruzioni standard con qualche comando di automazione in semplice script shell.

Anche per l’eventuale installazione di macchine virtuali in cloud è preferibile usare sistemi tipo terraform o simili.

Da valutare poi l’installazione attraverso docker.


### Creazione utente

Creazione utente non privilegiato e privo di shell per installare il full node


    mkdir /opt/cnd


    sudo useradd -m -d /opt/cnd --system --shell /usr/sbin/nologin cnd


    sudo -u cnd mkdir -p /opt/cnd/config


### Scaricamento dati della chain


    CHAIN_VERSION=&lt;chain-version>


    cd


    rm -rf commercio-chains


    git clone https://github.com/commercionetwork/chains.git commercio-chains


    CHAIN_DATA_FOLDER=”$HOME/commercio-chains/commercio-$CHAIN_VERSION”


    CHAIN_DATA_FILE=”$CHAIN_DATA_FOLDER/.data”


    CHAIN_VERSION=commercio-$(cat $CHAIN_DATA_FILE | grep -oP 'Name\s+\K\S+')


    CHAIN_BIN_RELEASE=commercio-$(cat $CHAIN_DATA_FILE | grep -oP Release\s+\K\S+')


    CHAIN_PER_PEERS=commercio-$(cat $CHAIN_DATA_FILE | grep -oP Persistent peers\s+\K\S+')


    CHAIN_SEEDS=commercio-$(cat $CHAIN_DATA_FILE | grep -oP Seeds\s+\K\S+')


    CHAIN_GEN_CHECKSUM=commercio-$(cat $CHAIN_DATA_FILE | grep -oP Genesis Checksum\s+\K\S+')


### Installazione binari


    wget "[https://github.com/commercionetwork/commercionetwork/releases/download/$CHAIN_BIN_RELEASE/Linux-AMD64.zip](https://github.com/commercionetwork/commercionetwork/releases/download/$CHAIN_BIN_RELEASE/Linux-AMD64.zip)"


    unzip -o Linux-AMD64.zip 


    sudo cp cn* /bin/


### Installazione configurazioni

Eseguire un reset della chain (questo inizializza anche la struttura delle cartelle) e installare le configurazioni della chain che si sta installando.


    sudo -u cnd /bin/cnd unsafe-reset-all --home=/opt/cnd


    sudo cp $CHAIN_DATA_FOLDER/genesis.json /opt/cnd/config/.


    sudo sed -e "s|persistent_peers = \".*\"|persistent_peers = \"$CHAIN_PER_PEERS\"|g" /opt/cnd/config/config.toml | \


      sed -e "s|addr_book_strict = \".*\"|addr_book_strict = \"false\"|g" | \ 


      sed -e "s|seeds = \".*\"|seeds = \"$CHAIN_SEEDS\"|g" \ >


      /opt/cnd/config/config.toml.tmp


    sudo mv /opt/cnd/config/config.toml.tmp /opt/cnd/config/config.toml

Cambiare i permessi della home dell’utente cnd

	sudo chown -R cnd /opt/cnd


### Creazione e avvio del service


    sudo tee /etc/systemd/system/cnd.service > /dev/null &lt;<EOF


```
    [Unit]
    Description=Commercio Node
    After=network-online.target

    [Service]
    User=gaiad
    ExecStart=/bin/cnd start --home=/opt/cnd/
    Restart=always
    RestartSec=3
    LimitNOFILE=4096

    [Install]
    WantedBy=multi-user.target
```



    EOF


    sudo systemctl enable cnd


    sudo systemctl start cnd


## Configurazione Validator Node

Per creare il nodo validatore possiamo partire dallo stesso tipo di installazione del sentry node.


### Configurazione nodo con KMS

Configurare il nome che si vuole attribuire al nodo (i sentry node di default prendono il nome host).


    NODENAME=”**<code>nome_nodo</code></strong>”

Accedere ai sentry node e ottenere gli id. Per ogni sentry node usare il comando


    sudo printf $(/bin/cnd tendermint show-node-id --home /opt/cnd)@$(ifconfig | fgrep "inet " | fgrep -v "127.0.0.1" | **<code>fgrep "10.1."</code></strong> | <strong><code>fgrep -v "10.1.1" </code></strong>| awk '{print $2}'):26656 > node_id.$(/bin/cnd tendermint show-node-id --home /opt/cnd).txt

	

**Attenzione**: in questo comando si è supposto che il sentry node sia su una rete separata rispetto alla vpn del validator node e del kms. Le istruzioni in grassetto hanno questa implicazione. Questa estrazione delle informazioni è strettamente legato alla struttura delle rete che si sta implementando e che generalmente non può essere omogenea in generale sulle varie installazione di nodi.

E’ necessario modificare la configurazione del nodo validatore  in modo che il KMS possa connettersi e che possa connettersi ai sentry node.

Ottenere le informazioni del validator node


    sudo printf $(/bin/cnd tendermint show-node-id --home /opt/cnd)@$(ifconfig | fgrep "inet " | fgrep -v "127.0.0.1" | **<code>fgrep "10.1.1"</code></strong> | awk '{print $2}'):26656 > node_id.val.txt

Ottenere le configurazioni dai sentry node


    for S_NODE in $LIST_S_NODES; do


    scp $S_NODE:node_id* .


    done

Costruire la stringa di configurazione per il config.toml


    for S_NODE_INFO  in node_id*; do


    S_NODES_IDS=$S_NODES_IDS”,”$S_NODE_INFO


    done

Immettere le configurazioni nel config.toml del nodo validatore


    sudo sed -e "s|priv_validator_key_file = \"config/priv_validator_key.json\"|#priv_validator_key_file = \"config/priv_validator_key.json\"|g" /opt/cnd/config/config.toml | \


      sed -e "s|#priv_validator_laddr = \"tcp://.*:26658\"|priv_validator_laddr = \"tcp://**<code>10.1.1.254</code></strong>:26658\"|g" | \


      sed -e "s|moniker = \".*\"|moniker = \"$NODENAME\""|g" | \ 


      sed -e "s|persistent_peers = \"(.*)\"|persistent_peers = \"\1$S_NODES_IDS\"|g" | \


      sed -e "s|pex = \".*\"|pex = \"false\"|g" | \


      sed -e "s|addr_book_strict = \".*\"|addr_book_strict = \"false\"|g" > \


      /opt/cnd/config/config.toml.tmp


    sudo mv /opt/cnd/config/config.toml.tmp /opt/cnd/config/config.toml


    sudo chown -R cnd /opt/cnd

**Attenzione**: non deve essere fatto ripartire il validator node in questo momento, perché dobbiamo ancora trasferire le informazioni del nodo validatore ai nodi sentry, per non diffondere le proprie informazioni

Trasferire le informazioni del validator node ai senry node


    for S_NODE in $LIST_S_NODES; do


    scp node_id.val.txt $S_NODE:.


    done

Per ogni sentry node deve essere inserito nelle configurazioni le informazioni del validator node per non diffonderle nella rete p2p


    sed -e "s|private_peer_ids = \".*\"|private_peer_ids = \"$(cat node_id.val.txt)\"|g" /opt/cnd/config/config.toml > /opt/cnd/config/config.toml.tmp


    sudo mv /opt/cnd/config/config.toml.tmp /opt/cnd/config/config.toml


    sudo chown -R cnd /opt/cnd


    sudo systemctl stop cnd; sleep 7; sudo systemctl start cnd

Avviare il nodo validatore


    sudo systemctl start cnd

Controllare l’output dei logs del kms dovrebbero variare in questa maniera


    Jan 11 09:23:14.389  INFO tmkms::session: [commercio-testnet6002@tcp://10.1.1.254:26658] **connected to validator successfully**


    Jan 11 09:23:14.389  WARN tmkms::session: [commercio-testnet6002] tcp:/10.1.1.254:26658: unverified validator peer ID! (A312D8F64C9FC71A1A947C377F64B7302C951361)

Controllare l’output dei logs del validator node. Dovrebbero riportare il funzionamento normale. Se qualcosa non funziona i blocchi in teoria non dovrebbero poter essere rilasciati


## Creazione sulla chain nodo Validator Node

Se tutti i passaggi sono corretti e il nodo validatore funziona correttamente si può eseguire la transazione di creazione del nodo validatore.

Da qualsiasi postazione dotata del client cncli, il wallet, e un accesso a un full node possiamo lanciare il comando di creazione del nodo


    cncli tx staking create-validator \


     --amount=50000000000ucommercio \


    --pubkey=**<code>did:com:valconspub1zcjduepq592mn6xucyqvfrvjegruhnx55cruffkrfq0rryu809fzkgwg684qmetxxs</code></strong> \


      --moniker="**<code>nome_nodo</code></strong>" \


      --chain-id="**<code>commercio-testnet6002</code></strong>" \ 


      --details="nodo validatore di Commercio" \


      --commission-rate="0.10" --commission-max-rate="0.20" \


      --commission-max-change-rate="0.01" --min-self-delegation="1" \


      --from=**<code>did:com:1zcjduep…</code></strong> \


      --node=**<code>tcp://10.1.2.1:26657</code></strong> \


      -y

Dove



*   **--pubkey**: la chiave pubblica del validatore fornita dal kms
*   **--moniker**: Nome del nodo
*   **--chain-id**: Id della chain per cui si sta creando il nodo (parametro non necessario se nelle configurazioni del client è già stato inserito)
*   **--from**: wallet contenente i token da delegare al validatore
*   **--node**: un full node a cui si ha accesso con la porta 26657 in ascolto

Se la transazione di creazione del nodo è andata a buon fine i logs del kms dovrebbe cominciare a mostrare le operazioni di PreVote e PreCommit.


## Considerazioni


# Installazione Kms -> Validator Node in datacenter



