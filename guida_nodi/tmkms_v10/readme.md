# Configurazione TMKMS con Validatore

## Concetti generali

In questa guida si spiegano alcuni concetti di gestione del nodo validatore con l'utilizzo di un sistema di gestione delle chiavi (Key Management System o KMS) con supporto di un modulo di sicurezza hardware (Hardware Secure Module o HSM).

### Motivazioni (perché farlo)

Una gestione con un sistema del genere comporta l'installazione di un sistema separato dal validatore che possa sopravvivere a un down completa della macchina che fisicamente è collegato alla chain per poterlo poi utilizzare su un nuovo sistema.

- Chiavi registrare su un HSM: le chiavi vivono e muoiono dentro a un sistema hardware resistente al limite a un furto di file dal sistema
- Possibilità di cambiare il puntamento del sistema KMS: avendo un unico sistema KMS che funziona nel momento in cui non punta più a un validatore e punta ad un altro non c'è il pericolo di doppia segnatura 

###  Motivazioni per non farlo (perché farlo)

- Costo più elevato: devono essere mantenuti due sistemi indipendenti
- HSM deve essere accessibile fisicamente: a meno di non utilizzare sistemi KMS cloud con costi estremamente elevati l'HSM dovrebbe essere sempre raggiungibile da personale umano, e quindi presente in un datacenter con accesso fisico

### Tools

Nelle guide successive verranno usati dei sistemi e dei tools di cui si fa una carrellata di seguito.
Le guide utilizzano dei sistemi e tools specifici, che comunque possono essere sostituiti da analoghi sistemi che svolgano la stessa funzione.

- Programma per VPN: sistema che crea una rete virtuale privata tra due o più server.
- Commercio Network Validator: un validatore della chain di Commercio.Network come spigato nella guida https://docs.commercio.network
- TMKMS: Tendermint Key Management System. E' un gestore di chiavi su HSM improntato all'eseguzione di sign su sistema Tendermint


## Installazione TMKMS

### Introduzione

In questa sezione viene trattato solo l'uso dell'HSM [`YubiHSM2`](https://www.yubico.com/it/product/yubihsm-2/) per il TMKMS. Per completezza riportiamo le altri possibili installazioni

1. SoftSign: è un sistema software che emula un HSM. Risulta meno sicuro dell'HSM fisico
2. Ledger Nano S o X: per buona parte simile a YubiHSM, trattandosi di sistema Hardware, ma supportato male, ed inoltre risente dell'uso intenso. Dopo un certo periodo di tempo potrebbe smettere di funzionare. E' più indicato per un uso personale
3. FortanixDSM: Sistema cloud di signing. I costi non sono ben definiti.

### Richieste hardware

L'infrastruttura attesa è l'installazione dello yubiHSM 2 su un server collegato in rete. Il sistema dovrebbe poter garantire le seguenti caratteristiche

1. Doppio alimentatore per i macchinari coinvolti, utile per la manutenzione elettrica.
2. Sistemi di continuità elettrica.
3. Sistemi in raid per resistere a eventuali rotture dei dischi
4. Macchina di backup su cui spostare il sistema di sign

Naturalmente alcuni di questi componenti sono già forniti di base dalle sale server professionali.     
**In alternativa può essere elaborata una buona strategia di disaster recovery**

L'ambiente testato per l'installazione del kms è ubuntu 18.04.

Per il funzionamento dell'hsm queste sono le caratteristiche minime per la macchina 
* Processore `x86_64`
* Ram minimo `2Gb` ma consigliato `4Gb`: sistema + software
* Interfaccia di rete minimo `100mbit`
* Spazio disco minimo `10Gb`.
* Presa `usb`. Preferibile eventualmente una scheda di usb interna ([questa scheda è già stata testata e funziona](https://www.amazon.it/gp/product/B07TDCZXRJ/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&psc=1)) per i seguenti motivi
  * Lo yubiHSM è più protetto
  * C'è spesso un problema nel riavvio del server che ospiterà lo yubiHSM: non viene più alimentato correttamente al boot e deve essere estratto e reinserito.


### Configurazione ambiente

L'installazione del sistema operativo e il suo aggiornamento sono fuori dallo scopo di questa guida e delle guide relative all'argomento possono essere trovate sul [sito stesso di Ubuntu](https://ubuntu.com/tutorials/install-ubuntu-server#1-overview).

I comandi indicati di seguito devono essere eseguiti come **root**.

Inserire lo yubiHSM2 nella presa usb preposta. Se il dispositivo è stato utilizzato precedentemente, **e il suo contenuto non serve**, eseguire un reset tenendo premuto più di 3 secondi la ghiera metallica quando il dispositivo viene inserito. 

Prendere nota del seriale dello yubiHSM

![yubiHSM 2 Serial](img/yubiSerial.png)


Se non si è già utente di root eseguire

```bash
sudo su - 
```

Lanciare i comandi per creare l’utente con cui eseguire le operazioni

```bash
mkdir /data_tmkms
useradd -m -d /data_tmkms/tmkms -G sudo tmkms -s /bin/bash
echo 'SUBSYSTEMS=="usb", ATTRS{product}=="YubiHSM", GROUP=="tmkms"' >> /etc/udev/rules.d/10-yubihsm.rules
reboot
```

**NB**: potrebbe essere necessario riavviare più volte il server per applicare. Togliere reinserire il dispositivo usb se non venisse visto dopo il reboot. 

**NB2**: chiunque abbia dimestichezza con i sistemi operativi e la gestione degli utenti può scegliere di eseguire l'installazione di un utente in maniera differente. Per il resto della guida si prenderà per acquisito che l'utente tmkms avrà la home installat in `/data_tmkms/tmkms`

### Procedura di installazione

Da questo momento in poi agiremo come utente **tmkms**. Tutti i comandi che necessitano di privilegi di root dovranno essere lanciati con **sudo**

Installazione compilatore **c**, **git tools** e di **libusb** necessari per il funzionamento dell’**HSM**

```bash
sudo apt install gcc git libusb-1.0-0-dev -y
```

Installazione rust: linguaggio per la compilazione del **TmKms**

```bash
export RUSTFLAGS=-Ctarget-feature=+aes,+ssse3
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# Scegliere "opzione 1"
source $HOME/.cargo/env
```

Installazione pkg-config

```bash
sudo apt install pkg-config -y
```

Installazione **TmKms**

```bash
cd $HOME
cargo install tmkms --features=yubihsm --locked --force
```

Controllo funzionamento

```bash
tmkms version
```

La versione al momento della stesura di questa guida è la `0.12.0`, ma è stata testata solo la versione `0.10.0`. Si consiglia di utilizzare quest'ultima


Devono essere installati degli strumenti aggiuntivi propri dello yubiHSM per poter gestire il collegamento come servizio e non direttamente su usb.

Installare le utility di `yubico`

```bash 
wget https://developers.yubico.com/YubiHSM2/Releases/yubihsm2-sdk-2021-03-ubuntu1804-amd64.tar.gz
tar zxf yubihsm2-sdk-2021-03-ubuntu1804-amd64.tar.gz
sudo apt install ./yubihsm2-sdk/*.deb
```

Al momento della stesura di questa guida sul sito della **Yubi** sono presenti driver e utility anche per [Ubuntu 20 e 22](https://developers.yubico.com/YubiHSM2/Releases/). Chiunque può verificiare il funzionamento anche con questi sistemi.

Attivare il service

```bash 
sudo tee /etc/systemd/system/yubihsm-connector.service > /dev/null <<EOF
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
```

Un servizio sull'ip locale e sulla porta `12345` dovrebbe attivarsi. Questo servizio servirà alle configurazioni del tmkms per poter funzionare.

Creeremo a questo punto una configurazione di base per inizializzare lo yubiHSM.

Creare le seguenti cartelle

```bash
cd /data_tmkms/tmkms
mkdir -p kms/base
mkdir -p kms/base/secrets
mkdir -p kms/base/states
```

Creare una cartella per i template

```bash
cd /data_tmkms/tmkms
mkdir -p kms/templates
```

Creare la configurazione di base `/data_tmkms/tmkms/kms/base/base.toml`. 
**NB**: questa configurazione serve unicamente per il reset dello yubiHSM e alcuni dati e anche alcuni file collegati non hanno alcuna funzionalità se non quella di correttezza formale di del file.

```toml
[[chain]]
id = "xxxx"
key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
state_file = "/data_tmkms/tmkms/kms/base/states/state.json"

[[validator]]
addr = "tcp://10.1.1.254:26658"
chain_id = "xxxx"
reconnect = true
secret_key = "/data_tmkms/tmkms/kms/base/secrets/secret_connection.key"
protocol_version = "v0.34" 

[[providers.yubihsm]]
adapter = { type = "usb" }
auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" }
keys = [{ chain_ids = ["xxxx"], key = 1, type = "consensus" }]
serial_number = "9876543210"
```

**<img src="img/attetion.png" width="30">Attenzione**: cambiare `serial_number = "9876543210"` con il valore della propria chiave yubiHSM. Il `serial_number` comunque può essere omesso.

Creare la password all'interno del file `/data_tmkms/tmkms/kms/password`

```bash
printf "password" > /data_tmkms/tmkms/kms/password
```

Creare un template per generare la chiave segreta di connessione

```bash
tmkms init /data_tmkms/tmkms/kms/templates/base
```

Copiare la chiave segreta
```bash
cd /data_tmkms/tmkms
cp kms/templates/base/secrets/kms-identity.key \
  kms/base/secrets/secret_connection.key
```

A questo punto siamo pronti per inizializzare lo yubiHSM

```bash
tmkms yubihsm setup -c /data_tmkms/tmkms/kms/base/base.toml
```

Un output di questo tipo dovrebbe apparire. Su due righe separate saranno presenti 24 parole che costituiranno la nuova password dello yubiHSM

```
This process will *ERASE* the configured YubiHSM2 and reinitialize it:
- YubiHSM serial: 9876543210
Authentication keys with the following IDs and passwords will be created:
- key 0x0001: admin:

double section release consider diet pilot flip shell mother alone what fantasy
much answer lottery crew nut reopen stereo square popular addict just animal

- authkey 0x0002 [operator]:  kms-operator-password-1k02vtxh4ggxct5tngncc33rk9yy5yjhk
- authkey 0x0003 [auditor]:   kms-auditor-password-1s0ynq69ezavnqgq84p0rkhxvkqm54ks9
- authkey 0x0004 [validator]: kms-validator-password-1x4anf3n8vqkzm0klrwljhcx72sankcw0
- wrapkey 0x0001 [primary]:   21a6ca8cfd5dbe9c26320b5c4935ff1e63b9ab54e2dfe24f66677aba8852be13

Are you SURE you want erase and reinitialize this HSM? (y/N):
```

Confermare quando viene richiesto di reinizializzare il dispositivo con `y` per procedere all'inizializzazione dello yubiHSM


```
21:08:09 [WARN] factory resetting HSM device! all data will be lost!
21:08:11 [WARN] deleting temporary setup authentication key from slot 65534

Success reinitialized YubiHSM (serial: 9876543210)
```

Salvare la nuova password del file 

```bash
printf "double section release consider diet pilot flip shell mother alone what fantasy much answer lottery crew nut reopen stereo square popular addict just animal" >/data_tmkms/tmkms/kms/password
```
**<img src="img/attetion.png" width="30">ATTENZIONE**: se la password non viene salvata in questo momento lo yubiHSM non potrà essere utilizzato e l'unico modo di fare un reset è quello di farlo manualmente.

Nel caso si volesse fare un `restore` di una precedente installazione è necessario eseguire un recover con le 24 parole. Questa procedura potrebbe essere necessaria nel caso si debba replicare le chiavi su un nuovo YubiHSM o nel caso si voglia resettare lo YubiHSM avendo comunque la possibilità di reimportare le chiave esportate crittate
```bash
tmkms yubihsm setup -c /data_tmkms/tmkms/kms/base/base.toml --restore
```

Verrà quindi richiesto di inserire il mnemonic con le 24 parole.     

### Creazione configurazioni nodo

Per ogni chiave, quindi in pratica per ogni validatore che si vuole collegare al kms, deve essere creata una configurazione.

Creeremo le configurazioni all'interno della cartella `/data_tmkms/tmkms/kms/commercio`.

```bash
cd /data_tmkms/tmkms
mkdir -p kms/commercio
mkdir -p kms/commercio/secrets
mkdir -p kms/commercio/states
```


Vogliamo creare la configurazione per il nodo validatore

**Nodo1**
* Ip del ndo validatore: `10.1.1.1`
* Chain: `commercio-3`
* Id chiave: `1`
* state_file: `/data_tmkms/tmkms/kms/commercio/states/node1.json`
* secret_key: `/data_tmkms/tmkms/kms/commercio/secrets/node1.key`


Creeare il template, solo per ottenere le secret key di collegamento

```bash
tmkms init /data_tmkms/tmkms/kms/templates/node1
```

Creare le configurazioni per il nodi

**Node1**

Creare il file `/data_tmkms/tmkms/kms/commercio/node1.toml` con i seguenti dati

```toml
[[chain]]
id = "commercio-3"
key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
state_file = "/data_tmkms/tmkms/kms/commercio/states/node1.json"

[[validator]]
addr = "tcp://10.1.1.1:26658"
chain_id = "commercio-3"
reconnect = true
secret_key = "/data_tmkms/tmkms/kms/commercio/secrets/node1.key"
protocol_version = "v0.34" 

[[providers.yubihsm]]
adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }
auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" }
keys = [{ chain_ids = ["commercio-3"], key = 1, type = "consensus" }]
serial_number = "9876543210"
```

**Da notare**

1. Nella sezione `[[providers.yubihsm]]` abbiamo indicato nel parametro `keys` la `key` con indice `1`.
2. Nella sezione `[[validator]]` abbiamo indicato il parametro `addr` l'address del validatore.

Copiare le chiavi create precedentemente nel template nelle posizioni corrette

```bash
cd /data_tmkms/tmkms
cp kms/templates/node1/secrets/kms-identity.key \
  kms/commercio/secrets/node1.key
```

### Produzione chiavi


Le chiavi ellittiche sono il materiali di base su cui si basa il consenso del nodo validatore. Le chiavi ellittiche devono essere create all'interno dell'HSM. 

Per farlo ci sono due metodi
1. Creare la chiave all'interno dell'HSM e salvare un file crittato con la chiave master dell'HSM stesso, che permetterà eventualmente l'importazione all'interno di un altro HSM che ha la stessa chiave master (24 parole) e posizionata allo stesso indice di chiave
2. Creare la chiave privata esternamente e importare la chiave all'interno dell'HSM. Questo metodo permette di inserire la chiave su qualsiasi indice. L'inconveniente è che la chiave privata viene veicolata in chiaro.


**Primo metodo**

Lanciare il seguente comando. L’opzione -b permette di salvare la chiave

```bash
tmkms yubihsm keys generate \
  1 -b node1.enc \
  -c /data_tmkms/tmkms/kms/commercio/node1.toml
```

<img src="img/attetion.png"  width="30"> il file di backup `node1.enc` deve essere subito trasferito su un supporto off-line e copiato più volte. Se vengono perse non potranno più essere replicate la chiavi generata in questo momento.

**Secondo metodo**

Nel caso invece si voglia recuperare le chiavi utilizzate inizialmente su un nodo mediante file in chiaro si può utilizzare questo comando

```sh
tmkms yubihsm keys import \
   -t json -i 1 priv_validator_node1.json \
   -c /data_tmkms/tmkms/kms/commercio/node1.toml
```

Il file in questione si può generare utilizzando il programma `commercionetworkd` ([vedi guida nodi](https://docs.commercio.network)), con il comando 

```bash
commercionetworkd init --home node1
```


<img src="img/attetion.png"  width="30"> I file utilizzati in questa procedura devono essere tunuti sui server solo il tempo necessario all'importazione e poi cancellati e tenuti su supporti off-line sicuri.


### Conferma presenza chiavi

Per confermare che le chiavi sono presenti e configurate nel HSM usare il comando

```bash
tmkms yubihsm keys list \
   -c /data_tmkms/tmkms/kms/commercio/node1.toml
```

Dovrebbe essere presentato un output come il seguente

```
Listing keys in YubiHSM #9876543210:
- 0x0001: did:com:valconspub1zcjduepq592mn6xucyqvfrvjegruhnx55cruffkrfq0rryu809fzkgwg684qmetxxs
```

`did:com:valconspub1zcjduepq592mn6xucyqvfrvjegruhnx55cruffkrfq0rryu809fzkgwg684qmetxxs` sarà la chiave pubblica del nodo validatore node1. 

Questa chiave sarà necessaria per eseguire la transazione di creazione del nodo validatore `node1`

**NB**: solo la chiave indicata nel file di configurazione è mostrata nel formato corretto.


### Creazione servizi

E' necessario configurare il servizio da avviare per il funzionamento del kms.   
Dovremo configurare un servizio per la chiave presente, ovvero per il validatore che vogliamo configurare.   

**Node1**
```bash 
sudo tee /etc/systemd/system/tmkms-node1.service > /dev/null <<EOF
[Unit]
Description=Commercio tmkms node1
After=network.target

[Service]
User=tmkms
WorkingDirectory=/data_tmkms/tmkms/.cargo/bin
ExecStart=/data_tmkms/tmkms/.cargo/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/node1.toml
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=tmkms_node1
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable tmkms-node1
sudo systemctl start tmkms-node1
```

Per verificare che il servizio è completamente funzionante usare 

```bash
journalctl -u tmkms-node1.service -f
```

L'output dovrebbe essere come il seguente

```log
Un output simile a questo dovrebbe apparire.
Mar 05 12:20:26.781  INFO tmkms::commands::start: tmkms 0.10.0 starting up…
Mar 05 12:20:27.280  INFO tmkms::keyring: [keyring:yubihsm] added consensus key did:com:valconspub1zcjduepq592mn6xucyqvfrvjegruhnx55cruffkrfq0rryu809fzkgwg684qmetxxs
Mar 05 12:20:27.280  INFO tmkms::connection::tcp: KMS node ID: 4248B5C7755600D694C47ECEA710A2DAB743AA38
Mar 05 12:20:58.682 ERROR tmkms::client: [commercio-3@tcp://10.1.1.1:26658] I/O error: Connection timed out (os error 110)
Mar 05 12:20:59.683  INFO tmkms::connection::tcp: KMS node ID: 4248B5C7755600D694C47ECEA710A2DAB743AA38
```

L'errore riportato è normale dato che il nodo validatore non è ancora attivo. Usare la sequenza di tasti `ctrl + c` per interrompere il flusso.   
Nel momento in cui il nodo validatore sarà attivo il log dovrebbero diventare qualcosa tipo quanto segue

```log 
Jan 11 09:23:14.389  INFO tmkms::session: [commercio-testnet6002@tcp://10.1.1.254:26658] connected to validator successfully
Jan 11 09:23:14.389  WARN tmkms::session: [commercio-testnet6002] tcp:/10.1.1.254:26658: unverified validator peer ID! (A312D8F64C9FC71A1A947C377F64B7302C951361)
```

Per la configurazione del nodo seguire la guida relativa.






## Architettura KMS - VPN - VALIDATOR

<img src="img/topologie_nodi-Page-6.png">

### Introduzione

Questa architettura presuppone che la macchina dove risied il Tmkms e il validator siano collegati attraverso una VPN.    
L'idea di base è che il servizio di TmKms si colleghi al validatore attraverso tale collegamento, fornendo così il servizio di sign al validatore stesso.

### Requisiti

- Un TmKms configurato **con la chiave privata del validatore**
- Un Validatore
- Un collegamento vpn tra i due server

### Dati di esempio

- TmKms
  - Ip Vpn: 10.1.1.2


- Validatore
  - Ip Vpn: 10.1.1.1
  - Se presente firewall deve essere aperto sulla porta 26658 verso l'ip 10.1.1.2 


### Configurazione


**VALIDATORE**

Modificare la configurazione del nodo validatore `config.toml`

```toml
priv_validator_laddr = "tcp://10.1.1.1:26658"
```

**TMKMS**

La configurazione del servizio tmkms deve essere la seguente

```toml
[[chain]]
id = "commercio-3"
key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
state_file = "/data_tmkms/tmkms/kms/commercio/states/node1.json"

[[validator]]
addr = "tcp://10.1.1.1:26658"
chain_id = "commercio-3"
reconnect = true
secret_key = "/data_tmkms/tmkms/kms/commercio/secrets/node1.key"
protocol_version = "v0.34" 

[[providers.yubihsm]]
adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }
auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" }
keys = [{ chain_ids = ["commercio-3"], key = 1, type = "consensus" }]
serial_number = "9876543210"
```

Da notare sempre

- `serial_number`: quello del vostro YubiHSM2
- `state_file`: secondo i path del vostro ambiente
- `secret_key`: secondo i path del vostro ambiente
- `password_file`: secondo i path del vostro ambiente

**Attivazione**

Eseguire il servizio TmKms con il comando

```bash
sudo systemctl start tmkms-node1
```

All'inizio il servizio dovrebbe dare degli errori.      
Riavviare il servizio del validatore con la configurazione cambiata.     

```bash
sudo systemctl restart commercionetworkd
```

