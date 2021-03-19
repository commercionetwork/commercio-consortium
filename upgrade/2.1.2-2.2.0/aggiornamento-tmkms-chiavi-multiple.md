# KMS

In questa sezione viene indicato come aggiornare i kms basati su yubihsm e tmkms con chavi multiple.   
**Si precisa che si tratta di linee guida, ed è essenziale capire il processo che qui viene sintetizzato**

**WIP**  Degli scripts guida sono stati prodotti in questa sezione [scripts](scripts)  **WIP**

1. Deve essere aggiornato il software `tmkms`
2. Devono essere modificate le configurazioni dei servizi di `tmkms` per poter operare con il nuovo core della chain
3. Tutto può essere preparato in precedenza: predisporre già i file con le configurazioni aggiornate in modo che al momento dell'upgrade della chain l'unica cosa da fare sia fermare i servizi e sostituire le configurazioni. Le precedenti configurazioni poi possono essere salvata in maniera da poterle recuperare velocemente nel caso di problemi.


## Aggiornamento software `tmkms` e configurazioni

**I kms possono essere aggiornati anche prima della procedura di upgrade della chain.**     
Il software può essere compilato separatamente da quello in funzione e quindi predisposto per avviarsi in nuovi servizi approntati per l'aggiornamento.   
**In questa sezione viene spiegata la predisposizione da eseguire anche prima dell'aggiornamento della chain.**

1. Aggiornare il compilatore
   Accedere al server kms come utente `tmkms`
   Il compilatore rust può essere aggiornato senza problemi. Il suo aggiornamento non modifica i binari
   ```bash
   rustup update
   cargo version
   ```
   la versione dovrebbe essere `1.50+`
2. Compilare il nuovo software
   ```bash
   cargo install tmkms --features=yubihsm --locked \
     --force --version=0.10.0 \
     --target-dir /data_tmkms/tmkms/V010 \
     --root /data_tmkms/tmkms/V010

   /data_tmkms/tmkms/V010/bin/tmkms version
   ```
   la versione dovrebbe essere `0.10.0`

   **NB**: Sono stati specificati i flags `--target-dir` e `--root` che fanno in modo che le librerie e i compilati vadano a posizionarsi in path differenti rispetto alla compilazione standard che invece installerebbe il software nei path standard `~/.cargo/bin`

3. Creare nuove configurazioni.
   Devono essere create le nuove configurazioni per la compatibilità con la nuova versione del software.
   In questa fase si può decidere di creare delle configurazioni compatibili con la versione del core `v2.1.2` della chain commercio o direttamente predisposte per la versione `v2.2.0`.    
   **Su questa guida predisporremo direttamente le configurazioni per la versione `v2.2.0` a cui attingeranno i servizi predisposti sempre per la versione `v2.2.0`.**

   Nella configurazione multi chiave si avranno una serie di configurazioni. Posto che le configurazioni sono contenute nella cartella `/data_tmkms/tmkms/kms/commercio` (ogni gestore avrà un proprio path), all'intenro di tale cartella avrò una serie di configurazione tipo 
   ```
   /data_tmkms/tmkms/kms/commercio/tmkms.01.toml
   /data_tmkms/tmkms/kms/commercio/tmkms.02.toml
   /data_tmkms/tmkms/kms/commercio/tmkms.03.toml
   ...
   ```

   La configurazione `/data_tmkms/tmkms/kms/commercio/tmkms.01.toml` tipo per la chain dovrebbe essere di questo tipo

   ```toml
   [[chain]]
   id = "commercio-2_1"
   key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
   state_file = "/data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state01.json"

   [[validator]]
   addr = "tcp://10.1.1.1:26658"
   chain_id = "commercio-2_1"
   reconnect = true
   secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection01.key"

   [[providers.yubihsm]]
   adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }
   auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" }
   keys = [{ chain_ids = ["commercio-2_1"], key = 1 }] 
   serial_number = "9876543210"
   ```
   
   Notare i seguenti parametri specifici della configurazione da considerare per l'upgrade

   * `[[chain]]` `state_file`: è il file di stato specifico del valiatore e dovrà essere cambiato. **Mantenere il file precedente**
   * `[[chain]]` `id`: chain id. Passerà da `commercio-2_1` a `commercio-2_2`
   * `[[validator]]` `chain_id`: chain id. Passerà da `commercio-2_1` a `commercio-2_2`
   * `[[providers.yubihsm]]` `keys` `chain_ids`: chain id. Passerà da `commercio-2_1` a `commercio-2_2`
   In aggiunta
   * `[[validator]]` `protocol_version`: dovrà essere configurato con il valore `v0.33`
   Nota
   * `[[providers.yubihsm]]` `keys` `key`: è l'indice della chiave del validatore. Come altri parametri nella configurazione cambia in base al validatore a cui è collegato il servizio.


   Creare la cartella dedicata alle nuove configurazioni

   ```bash
   mkdir /data_tmkms/tmkms/kms/commercio/2.2.0
   ```
   Creare la configurazione per la nuova chain `/data_tmkms/tmkms/kms/commercio/2.2.0/tmkms.01.toml`

   ```toml
   [[chain]]
   id = "commercio-2_2"
   key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
   state_file = "/data_tmkms/tmkms/kms/commercio/2.2.0/commercio_priv_validator_state01.json"

   [[validator]]
   addr = "tcp://10.1.1.1:26658"
   chain_id = "commercio-2_2"
   reconnect = true
   secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection01.key"
   protocol_version = "v0.33" 

   [[providers.yubihsm]]
   adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }
   auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" }
   keys = [{ chain_ids = ["commercio-2_2"], key = 1 }] 
   serial_number = "9876543210"
   ```

   Eseguire la procedura per le `<N>` configuraioni. Alla fine si avranno le nuove configurazioni

   ```
   /data_tmkms/tmkms/kms/commercio/2.2.0/tmkms.01.toml
   /data_tmkms/tmkms/kms/commercio/2.2.0/tmkms.02.toml
   /data_tmkms/tmkms/kms/commercio/2.2.0/tmkms.03.toml
   ...
   ```
4. Creare i nuovi servizi.
   Supponendo di avere una serie di servizi di questo tipo
   ```
   /etc/systemctl/system/tmkms-01.service
   /etc/systemctl/system/tmkms-02.service
   /etc/systemctl/system/tmkms-03.service
   ...
   ```
   Il servizio `/etc/systemctl/system/tmkms-01.service` sarà di questo tipo

   ```ini
   [Unit]
   Description=Commercio tmkms slot 01
   After=network.target

   [Service]
   User=tmkms
   WorkingDirectory=/data_tmkms/tmkms/.cargo/bin
   ExecStart=/data_tmkms/tmkms/.cargo/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms.01.toml
   Restart=always
   SyslogIdentifier=tmkms.01
   RestartSec=3
   LimitNOFILE=4096

   [Install]
   WantedBy=multi-user.target
   ```

   Notare i seguenti parametri specifici della configurazione da considerare per l'upgrade
   * WorkingDirectory: dovrà cambiare in `/data_tmkms/tmkms/V010/bin`
   * ExecStart: dovrà cambiare in `/data_tmkms/tmkms/V010/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/2.2.0/tmkms.01.toml`

   Creare il nuovo servizio `/etc/systemctl/system/tmkms220-01.service`

   ```ini
   [Unit]
   Description=Commercio tmkms slot 01
   After=network.target

   [Service]
   User=tmkms
   WorkingDirectory=/data_tmkms/tmkms/V010/bin
   ExecStart=/data_tmkms/tmkms/V010/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/2.2.0/tmkms.01.toml
   Restart=always
   SyslogIdentifier=tmkms.01
   RestartSec=3
   LimitNOFILE=4096

   [Install]
   WantedBy=multi-user.target
   ```

   La procedura dovrà essere ripetuta per tutti i servizi ottenendo la lista dei nuovi servizi
   ```
   /etc/systemctl/system/tmkms220-01.service
   /etc/systemctl/system/tmkms220-02.service
   /etc/systemctl/system/tmkms220-03.service
   ...
   ``` 

## Aggiornamento chain
In questa sezione viene trattato la procedura da seguire nel momento in cui viene aggiornato il core della chain sui nodi validatori.

1. Assicurarsi che i nodi validatori siano spenti
   I nodi validatori collegati al kms devono essere fermi. Eventualmente eseguire il comando sui nodi validatori
   ```bash
   sudo systemctl stop cnd
   ```
1. Fermare tutti i servizi tmkms
   Fermare e disabilitare tutti i service nel kms
   ```
   sudo systemctl stop tmkms-01.service
   sudo systemctl disable tmkms-01.service
   sudo systemctl stop tmkms-02.service
   sudo systemctl disable tmkms-02.service
   sudo systemctl stop tmkms-03.service
   sudo systemctl disable tmkms-03.service
   ...
   ```
2. Avviare in nuovi servizi
   Questa fase può essere lanciata a prescindere dall'attività del nodo validatore.    
   Nel momento in cui i nodi validatori tornerneranno a funzionare il kms comincerà a fornire da subito il servizio di sign.   
   ```
   sudo systemctl enable tmkms220-01.service
   sudo systemctl start tmkms220-01.service
   sudo systemctl enable tmkms220-02.service
   sudo systemctl start tmkms220-02.service
   sudo systemctl enable tmkms220-03.service
   sudo systemctl start tmkms220-03.service
   ...
   ```
   Analizzando il logs con il comando `journalctl` dovrebbe essere possibile vedere che il tmkms non riesce a raggiungere il nodo validatore perché spento. 
   ```bash
   journalctl -u tmkms220-01 -f
   ```
   Nel momento in cui il nodo verrà riattivato il sign dovrebbe ricominciare regolarmente


## Ripristino in caso di problemi nell'aggiornento
Nel caso l'aggiornamento della chain non andasse a buon fine seguire questa procedura
1. Fermare tutti i servizi tmkms
   Fermare e disabilitare tutti i service nel kms
   ```
   sudo systemctl stop tmkms220-01.service
   sudo systemctl disable tmkms220-01.service
   sudo systemctl stop tmkms220-02.service
   sudo systemctl disable tmkms220-02.service
   sudo systemctl stop tmkms220-03.service
   sudo systemctl disable tmkms220-03.service
   ...
   ```
2. Avviare in nuovi servizi
   Nel momento in cui i nodi validatori tornerneranno a funzionare il kms comincerà a fornire da subito il servizio di sign.   
   ```
   sudo systemctl enable tmkms-01.service
   sudo systemctl start tmkms-01.service
   sudo systemctl enable tmkms-02.service
   sudo systemctl start tmkms-02.service
   sudo systemctl enable tmkms-03.service
   sudo systemctl start tmkms-03.service
   ...
   ```
**NB**: volendo si può usare comunque il nuovo software del `tmkms` implementando le configurazioni adegaute 


## Note

### Spiegazioni guida
Possono essere scelti altre strategie di aggiornamento, ma in questa guida è stato scelta una strada specifica. Chiunque può adottore questa guida o una sua personale procedura.    
Inoltre tutta la procedura è stata sviluppata sulla base di un'installazione standard, con path ben definiti.  
Si ritiene che i gestori del kms siano in grado di utilizzare gli strumenti più adatti per svolgere l'attività di aggiornamento.


### Errori o dubbi comuni

1. Il servizio mi ritorna un errore di permessi     
   Il servizio viene configurato con l'utente `tmkms`, quindi qualsiasi cartella a cui il servizio abbia bisogno di accedere il lettura, ma soprattutto in scrittura, deve essere configurato in maniera adeguata.    
   Se ad esempio agite sul server kms come root per tutto il tempo, prima di avviare i servizi dovete lanciare i comandi
   ```bash
   sudo chown -R tmkms:tmks /data_tmkms/tmkms
   ```
   Essenzialmente questo comando dovrebbe risolvere qualsiasi problema di accesso ai file.
1. Il `tmkms` mi dice che non riesce a raggiungere il validatore     
   Verificare che non ci siano problemi di rete tra il kms e il validatore, es. Vpn spenta. Un semplice `ping` dovrebbe essere sufficiente per verificare la raggiungibilità.   
   Verificare inoltre se la configurazione nel file `config.toml` del validatore è cambiata togliendo il valore di `priv_validator_laddr`
1. E' necessario cambiare il servizio `yubihsm-connector`?    
   Non è necessario aggiornare il servizio dello yubi. Esistono degli aggiornamenti del software sul sito della yubi

   https://developers.yubico.com/YubiHSM2/Releases/

   ma non introducono nessuna modifica per le chiavi utilizzate dai validatori. Non è stato testato l'aggiornaemento, quindi è a discrezione dei singoli gestori provare le nuove releases.

