# Guida configurazione nodo validatore con ledger Nano S

### **Attenzione**

* Questa guida è solo un draft e deve essere ultimata. Controllare le varie operazione.
* Quanto scritto in questa guida considera di avere kms e nodo validatore sulla stessa macchina


## Inizializzazione ledger

Connettere il dispositivo a un computer.    
Se il dispositivo è nuovo verrà richiesto in automatico l’inserimento di un pin e delle 24 parole.    
Nel caso il dispositivo sia già stato configurato possiamo resettarlo semplicemente sbagliando tre volte il pin di accesso.     
Una volta inserito il pin il ledger nano visualizza le 24 parole le quali dovranno essere subito trascritte.    
Un video esplicativo della procedura può essere trovato a [questo indirizzo](https://support.ledger.com/hc/en-us/articles/360000613793).   
   

## Aggiornamento e installazione app

Per poter utilizzare in maniera corretta il ledger è necessario aggiornarlo all’ultima versione del firmware e installare il software tendermint     

Installare su un computer l’applicazione Ledger Live desktop.     
Una volta installato connettere il ledger Nano S al computer. L’app chiederà di sbloccare il ledger con il pin.   
     
Una volta entrati verificare se esiste un aggiornamento per il firmware del Ledger Nano S e installarlo.    
      
Completato l’aggiornamento abilitare il developer mode nelle configurazioni sotto la voce “experimental features” del ledger live desktop.    
    
Cercare tra le applicazioni “Tendermint” e installarla sul Ledger.    
   
**Configurare il ledger per non andare mai in blocco dello schermo.**


## Installazione software

Collegare il ledger al server dove si vuol far funzionare il nodo validatore e attivare l’applicazione tendermint.
Installare il software necessario al funzionamento.       

## Installazione software

Per poter installare sul server il software dobbiamo avere i seguenti componenti    
* Rust (stable; 1.39+)
* C compiler
* pkg-config
* libusb (1.0+)

Riferimento: [https://github.com/tendermint/kms/blob/master/README.md#installation](https://github.com/tendermint/kms/blob/master/README.md#installation)       


```sh
sudo apt install gcc git libusb-1.0-0-dev -y
```


      
Una volta installati i componenti necessari possiamo compilare e installer il software tmkms

```sh
cargo install tmkms --features=ledgertm
```

A questo punto dovrebbe essere presente un binario `tmkms`. Controllare usando

```sh
tmkms version
```

## Configurazione software

Per utilizzare il tmkms con l’applicazione di commercio dobbiamo creare la configurazione ~/.tmkms/tmkms.toml

```toml
[[chain]]
id = "commercio-testXXXX"
key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }

[[validator]]
addr = "tcp://localhost:26658" # Questo dovrebbe essere l’ip del nodo validatore
chain_id = "commercio-testXXXX"
reconnect = true # true is the default
secret_key = "~/.tmkms/secret_connection.key"

[[providers.ledgertm]]
chain_ids = ["commercio-testXXXX"]
```

**Parametri da verificare**
* Nella sezione `chain` l'`id` deve essere il chain_id della chain a cui si sta accedendo
* `account_key_prefix` deve essere **did:com:**
* `consensus_key_prefix` deve essere **ddid:com:valconspub**

* Nella sezione `validator` `chain_id` deve essere il chain_id della chain a cui si sta accedendo
* Nella sezione `providers.ledgertm` `chain_ids` deve essere il chain_id della chain a cui si sta accedendo

A questo punto dobbiamo eseguire i passaggi finali per la creazione delle chiavi
Avvio del servizio tmkms
```sh
tmkms start -c ~/.tmkms/tmkms.toml
```
Dall’ouput dovrò annotare la chiave da utilizzare poi nella mia transazione di creazione del nodo validatore. L'output dovrebbe essere una chiave di questo tipo

```
did:com:valconspub1zcjduepqy53m3…….
```


## Configurazione nodo validatore


Il servizio tmksm, se il nodo non è avviato, non troverà nessuno in ascolto sulla porta e l’ouput del comando riporterà degli errori del tipo `I/O error: Connection timed out (os error 110)`

Configuriamo il nodo validatore per modificando il parametro all’interno del file config.toml per il provider delle chiavi
Commentiamo la lettura delle chiavi da file.

```toml
#priv_validator_key_file = "config/priv_validator_key.json" 
```
Abilitiamo il servizio cnd perché accetti le connsioni da il kms di tendermint
```toml
priv_validator_laddr = "tcp://127.0.0.1:26658" 
```
A questo punto punto possiamo avviare il nostro nodo. Sull’output del tmkms dovrebbe apparire una riga come questa
`tmkms::connection::tcp: KMS node ID: DD69340BEBEBFA312E4C064CE4A1A4DE4B685D2A`

## Avvio e verifica del nodo


Eseguiamo la nostra transazione per creare il validatore utilizzando l’indirizzo della chiave fornita dal tmkms
```sh
cncli tx staking create-validator \
--amount=50000000000ucommercio \
--pubkey=did:com:valconspub1zcjduepqn….. \
--moniker="RedWineIsFine" \
--chain-id="commercio-mainnet" \
...
```
L’output del tmkms comincerà visualizzare la segnatura dei blocchi e quindi righe di questo tipo: `signed PreCommit:498FBC587C at h/r/s 25585/0/2 (126 ms)`