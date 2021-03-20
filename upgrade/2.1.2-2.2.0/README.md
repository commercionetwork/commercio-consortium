# Istruzioni aggiornamento da 2.1.2 a 2.2.0 Chain Commercio Network
# ATTENZIONE LE ISTRUZIONI SONO ANCORA IN FASE DI REDAZIONE: I PARAMETRI NON SONO ANCORA QUELLI UFFICIALI


Il seguente documento descrive i passaggi necessari per eseguire l'aggiornamento dei nodi validatori della chain di Commercio Network da `commercio-2_1` (basata sulla versione 2.1.2 del core) a `commercio-2_2` (basata sulla versione 2.2.0 del core).    
Alla fine delle operazioni di aggiornamento verrà prodotto un file di genesis che verrà pubblicato su https://github.com/commercionetwork/chains, ma si invita tutti i validatori a partecipare attivamente alla procedura.

La data di aggiornamento è stata fissata per `22 Marzo 2021 alle 15.00 UTC` = `16.00 CET`. L'altezza pubblicata dovrebbe fermare la chain poco dopo le 15.00 UTC = 16.00 CET. Lo scostamento potrebbe essere di qualche minuto. 


  - [Sommario](#Sommario)
  - [Migrazione](#Migrazioni)
  - [Operazioni preliminari](#operazioni-preliminari)
  - [Rischi](#rischi)
  - [Procedura di aggiornamento validatore](#procedura-di-aggiornamento)
  - [Procedure aggiornamento full-node](#guida-per-i-full-node-sentry)
  - [Ripristino](#ripristino)
  - [Note](#note)
 
# Sommario

L'aggiornamento della chain è schedulata per il 22 Marzo 2021 alle 15.00 UTC (16.00 orario europa centrale).

Questi sono in breve i passi da compiere nell'aggiornamento

1. Fermare il nodo di Commercio Network con core v2.1.2
2. Eseguire un export dello stato della chain
3. Eseguire un backup delle configurazioni e dei dati della chain
4. Eseguire una migrazione dello stato della chain con il nuovo core di Commercio Network producendo il nuovo genesis 
5. Installare il nuovo core di Commercio Network e il nuovo genesis e eseguire un reset della chain
6. Avviare il demone del nuovo core e attendere il raggiungimento del consenso

I dettagli dell'aggiornamento sono nella sezione [Procedura di aggiornamento](#procedura-di-aggiornamento).     

Per i full-node (sentry) sono state create delle specifiche istruzioni su [Procedure aggiornamento full-node](#guida-per-i-full-node-sentry).

**UNA PROCEDURA PIU' TECNICA PUO' ESSERE TROVATA A [QUESTA PAGINA](./upgrade_tech.md).** E' sostanzialmente una procedura che ricalca l'esercitazione eseguita il 12/03/2021. 


Il coordinamento dei nodi verrà gestito all'interno del canale Telegram per i nodi validatori.

**Importante** l'aggiornamento potrebbe avere i seguenti risultati:
1. `Aggiornamento riuscito`: i validatori riescono nella migrazione e nell'aggiornamento e la nuova chain verrà avviata. Il periodo per l'emissione del primo blocco e il raggiungimento del consenso potrebbe richiedere parecchio tempo.
2. `Avvio nuova chain fallito`: se vengono riscontrati dei problemi durante l'avvio della nuova chain e non è possibile raggiungere il consenso. In questo caso verranno fermati i nodi e verrà recuperato il backup e la chain ripartirà con la precedente versione. L'aggiornamento verrà rischedulato verificando i problemi riscontrati e eseguendo i fix relativi.  
3. `Procedura non completabile`: nel caso già a livello di export o migrazione venissero riscontrati problemi che non consentono di procedere l'aggiornamento (es. il checksum del nuovo genesis non corrisponde tra i nodi validatori) verrà abortito e si procederà a recuperare il backup della chain e facendo ripartire la precedente versione.

# Migrazione

La migrazione coinvolge sostanziali cambiamenti in alcuni moduli e altri cambiamenti minori su altri. 
Di seguito vengono elencati i cambiamenti più rilevanti

1. `Id` 
2. `Documents`
2. `Accreditations` -> `CommercioKyc`
2. `CommercioMint`


Maggiori dettagli sono riportati in [docs.commercio.network](https://docs.commercio.network). In tale documentazione sono evidenziati in alto a destra la documentazione della versione `2.2.0` e quella della versione `2.1.2`


## Operazioni preliminari

Prima di eseguire l'aggiornamento ci sono alcuni aspetti da considerare
1. Verificare di avere abbastanza spazio su disco: attualmente il database pruned della chain occupa 50/60Gb, quindi il disco dei server deve avere abbastanza spazio da contenere il backup più almeno altri 10Gb per le operazioni di export e migration e per l'avvio della nuova chain 
2. **Ram**: è consigliabile avere almeno 8Gb di ram. Probabilmente l'aggiornamento riuscirà anche con 2Gb ma le operazioni potrebbero rivelarsi molto rallentate.
3. E' consigliabile, non appena verrà pubblicato la release finale, la compilazione o lo scaricamento dei nuovi binari: compilare i binari durante l'aggiornamento potrebbe rallentare le operazioni. **La versione finale sarà con il tag `v2.2.0`**
4. Preparare le configurazioni dei file `config.toml` e `app.toml` prima in modo da averli pronti nel momento dell'aggiornamento
5. Sospendere le transazioni dove possibile: le transazioni nel momento in cui la chain verrà fermata verranno rifiutate e quindi il loro invio dipenderà da come il client che invia gestisce tali errori.
6. Per chi fa uso di `tmkms` aggiornare da subito il tmkms almeno alla versione 0.9.0 (meglio 0.10.0). Per chi usa lo yubiHSM con una sola chiave leggere la procedura in [Aggiornamento tmkms](./aggiornamento-tmkms.md). Chi invece usa lo yubiHSM con chiavi multiple leggere la guida [Aggiornamento tmkms con chiavi multiple](./aggiornamento-tmkms-chiavi-multiple.md)

## Rischi

Uno dei maggiori rischi per i validatori è di incorrere nella doppia firma. E' assolutamente necessario controllare la versione del vostro software e il genesis. Inoltre è necessario spostare il file di stato, sia sul validatore, se si sta facendo uso di chiavi su file, che sul tmkms se si fa uso di quest'ultimo. **Non cancellare il file di stato**

Se durante l'aggiornamento viene fatto qualche errore, ad esempio utilizzando una versione errata del software o un genesis non corretto meglio aspettare che la chain riparta e unirsi successivamente.

**LEGGERE ATTENTAMENTE LA SEZIONE [RIPRISTIONO](#ripristino)**

## Procedura di aggiornamento

__Note__: Viene dato per scontato che il nodo su cui si va ad operare ha la versione v2.1.2 del core della chain.     
__Note 2__: Le istruzioni devono essere adattate al proprio ambiente, quindi variabili e path devono essere cambiate a seconda delle installazioni.



**!!!SCRIPTS**  Lo sviluppo di scripts o programmi automatici è stato sospeso perché durante l'ultimo meeting la maggior parte dei partecipanti li hanno ritenuti inutili. Ogni partecipante ha già predisposte le proprie procedure  **SCRIPTS!!**

La versione/hash commit di commercio network è  v2.1.2: `8d5916146ab76bb6a4059ab83c55d861d8c97130`

1. Verificare la versione corrente (v2.1.2) di _cnd_:

   ```bash
    cnd version --long
   ```  
   Dovrebbe riportare il seguente risultato
   ``` 
    name: commercionetwork
    server_name: cnd
    client_name: cndcli
    version: 2.1.2
    commit: 8d5916146ab76bb6a4059ab83c55d861d8c97130
    build_tags: netgo,ledger
    go: go version go1.15.8 linux/amd64
    ...
   ```

   Installare il tool adeguati

   ```bash
   apt install jq -y
   ```

   Controllare la versione di `go` che sia almeno `1.15+`


2. Verificare che sia impostato il blocco di stop esatto: `<DA COMUNICARE>`

   
   ```bash
   sed 's/^halt-block =.*/halt-block = <DA COMUNICARE>`/g' ~/.cnd/config/app.toml > ~/.cnd/config/app.toml.tmp
   mv ~/.cnd/config/app.toml.tmp  ~/.cnd/config/app.toml
   ```
   E applicare la configurazione usando il comando 
   ```bash
   systemctl restart cnd
   ```
   Il nodo si dovrebe fermare all'altezza `<DA COMUNICARE>`. Controllare con

   ```bash
   journalctl -u cnd -f
   ```

1. Dopo lo stop della chain fermare il nodo e eseguire l'export dello stato:
   ```bash
   systemctl stop cnd
   systemctl stop cncli
   pkill cnd
   pkill cncli
   ```
   **Attenzione**: il comando `systemctl stop cncli` potrebbe dare un errore, dato che il servizio `cncli` serve solo per le rest api e non è predisposto ovunque.

   Eseguire l'export della chain
   ```bash
   cnd export --for-zero-height  > ~/commercio-2_1_genesis_export.json
   ```
   **NB**: questa operazione è necessaria solo sui nodi validatori. Il genesis prodotto poi potrà essere installato sui nodi sentry.     
   Il processo potrebbe richiedere un po' di tempo e dipende dalle risorse disponibili sul nodo.

2. Salvataggio delle vostra cartella `.cnd` directory

   ```bash
    mkdir -p ~/cnd_backup/bin
    mv ~/.cnd/data ~/cnd_backup/.
    cp -r ~/.cnd/config ~/cnd_backup/.
    cp ~go/bin/cn* ~/cnd_backup/bin/.
   ```

    **NB**: Il backup è fondamentale nel caso la procedura non riuscisse e tutti i nodi sono invitati a eseguirla. Il backup verrà utilizzato nell'eventualità come indicato nella sezione See [Ripristino](#ripristino).



3. Verifca del checsum del file gensis esportato:

   Attraverso la comunicazione in chat tutti i nodi validatori dovranno postare il risultato del checksum dell'export

   ```bash
   $ jq -S -c -M '' ~/commercio-2_1_genesis_export.json | shasum -a 256
   ```

   <img src="img/attetion.png" width="30">Il risultato dovrebbe essere nella formula
   ```
   [SHA256_VALUE]  commercio-2_1_genesis_export.json
   ```
   Copiare e incollare sul gruppo di Telegram il valore `[SHA256_VALUE]` e compararlo con tutti gli altri validatori


4. Compilare i nuovi binari

   ```bash
    git clone https://github.com/commercio/commercionetwork && cd commercionetwork
    git checkout v2.2.0
    make GENERATE=0 install
   ```

   Se sono già stati compilati i binari potete direttamente copiare i binari nei path dei precedenti binari.

1. Verificare che gli applicativi siano la versione giusta:

   ```bash
    cnd version
    ```
    I valori dovrebbe essere 
    ```
    name: cnd
    server_name: cnd
    version: v2.2.0
    commit: <DA COMUNICARE>
    build_tags: netgo,ledger
    ...
   ```
    La versione hash del nuovo software dovrebbe essere v2.2.0: `<DA COMUNICARE>`

2. A questo punto deve essere eseguita la migrazione del file di genesis per rendere conforme il nuovo stato per il nuovo core.
Scaricare e installare i binari

   ```bash
   cnd migrate v2.2.0 \
    ~/commercio-2_1_genesis_export.json \
    --chain-id=commercio-2_2 \
    --genesis-time="" > ~/genesis.json
   ```


1. Verificare il checksum del genesis prodotto:

   ```bash
   $ jq -S -c -M '' ~/genesis.json | shasum -a 256
   ```

   Il risultato dovrebbe essere nella formula
   ```
   [SHA256_VALUE]  genesis.json
   ```
   <img src="img/attetion.png" width="30">Copiare e incollare sul gruppo di Telegram il valore `[SHA256_VALUE]` e compararlo con tutti gli altri validatori

2. Reset dello stato della chain:

   <img src="img/attetion.png" width="30">**NOTE**: questo è un punto molto delicato e assicuratevi per l'ennesima volta di avere un backup del database della chain e delle configurazioni. 

   ```bash
   cnd unsafe-reset-all
   ```

3. Installare il nuovo geneis della nuova chain

    ```bash
    cp genesis.json ~/.cnd/config/
    ```

   <img src="img/attetion.png" width="30"> **ATTENZIONE** in questa fase devono essere aggiornati prima i sentry. Verificare la [procedura di aggiornamento full node](#guida-per-i-full-node-sentry)
1. Installare il nuovo template del file `app.toml`
   ```bash
   cnd init templ --home ~/cnd_template
   cp ~/cnd_template/config/app.toml ~/.cnd/config/.
   ```

2. Avvio della nuova chain

   ```bash
   systemctl start cnd
   ```
1. Controllare lo stato del nodo
   ```bash
   journalctl -u cnd -f
   ```
   I nodi potrebbero impiegare del tempo per arrivare al consenso.


# Guida per i full node (Sentry)

1. Verificare che sia impostato il blocco di stop esatto: `<DA COMUNICARE>`

   
   ```bash
   sed 's/^halt-block =.*/halt-block = <DA COMUNICARE>`/g' ~/.cnd/config/app.toml > ~/.cnd/config/app.toml.tmp
   mv ~/.cnd/config/app.toml.tmp  ~/.cnd/config/app.toml
   ```
   E applicare la configurazione usando il comando 
   ```bash
   systemctl restart cnd
   ```
   Il nodo si dovrebe fermare all'altezza `<DA COMUNICARE>`. Controllare con

   ```bash
   journalctl -u cnd -f
   ```
   **NB** I nodi sentry in ogni caso si dovrebbero fermare dato che i nodi validatori si fermeranno
2. Dopo lo stop della chain fermare il nodo e eseguire l'export dello stato:
   ```bash
   systemctl stop cnd
   systemctl stop cncli
   pkill cnd
   pkill cncli
   ```
   **Attenzione**: il comando `systemctl stop cncli` potrebbe dare un errore, dato che il servizio `cncli` serve solo per le rest api e non è predisposto ovunque.

3. Salvataggio delle vostra cartella `.cnd` directory

   ```bash
    mkdir ~/cnd_backup
    mv ~/.cnd/data ~/cnd_backup/.
    cp -r ~/.cnd/config ~/cnd_backup/.
   ```

    **NB**: Il backup è fondamentale nel caso la procedura non riuscisse e tutti i nodi sono invitati a eseguirla. Il backup verrà utilizzato nell'eventualità come indicato nella sezione See [Ripristino](#ripristino).

4. Compilare i nuovi binari

   ```bash
   git clone https://github.com/commercio/commercionetwork && cd commercionetwork && git checkout v2.2.0; make install
   ```

   Se sono già stati compilati i binari potete direttamente copiare i binari nei path dei precedenti binari.   
   I binari possono essere anche copiati da un'altra macchina (validatore ad esempio) con la stessa architettura della macchina del full node.

1. Verificare che gli applicativi siano la versione giusta:

   ```bash
    cnd version
    ```
    I valori dovrebbe essere 
    ```
    name: cnd
    server_name: cnd
    version: v2.2.0
    commit: <DA COMUNICARE>
    build_tags: netgo,ledger
    ...
   ```
    La versione hash del nuovo software dovrebbe essere v2.2.0: `<DA COMUNICARE>`

2. Reset dello stato della chain:

   <img src="img/attetion.png" width="30">**NOTE**: questo è un punto molto delicato e assicuratevi per l'ennesima volta di avere un backup del database della chain e delle configurazioni. 

   ```bash
   cnd unsafe-reset-all
   ```
3. Installare il nuovo geneis della nuova chain
   
   Da un nodo validatore o dal repo della chains (questo però sarà pronto solo dopo il completamento della procedura) copiare il genesis.
   **Dal vostro computer, quindi fuori dai server, supposto che stiate utilizzando ssh per l'accesso e che la procedura sul validatore sia al punto 11**
   ```bash
   scp <UTENTE VALIDATORE>@<IP VALIDATORE>:.cnd/config/genesis.json .
   scp genesis.json <UTENTE FULL NODE>@<IP FULL NODE>:.cnd/config/.
   ```
1. Installare il nuovo template del file `app.toml`
   ```bash
   cnd init templ --home ~/cnd_template
   cp ~/cnd_template/config/app.toml ~/.cnd/config/.
   ```

   lanciare il comando

   ```bash
   echo $($BIN_DIR/cnd tendermint show-node-id --home $HOME_CND)@$(wget -qO- icanhazip.com):26656
   ```

   Il risultato del comando sono quelli che faranno da peer persistenti per la nuova chain. Condividere il dato su

   `https://hackmd.io/<DA COMUNICARE>`

   Al file di configurazione `~/.cnd/config/config.toml` vanno aggiunti i vari `persistent_peers`, escludendo il proprio nodo naturalmente.   
   Questa procedura mette la chain in condizione di collegare i nodi tra loro più velocemente.   
   Se non presente aggiungere sempre nel file `~/.cnd/config/config.toml` anche il proprio ip pubblico nel parametro `external_address` in questa maniera
   ```toml
   external_address="tcp://<IP PUBBLICO>:26656"
   ```


2. Avvio della nuova chain

   ```bash
   systemctl start cnd
   ```

## Ripristino

Prima dell'aggiornamento tutti i validatori sono tenuti a eseguire un backup dello stato della chain. Il backup deve essere eseguito sia su i nodi validatori sia sui sentry e in generale su qualsiasi full node della chain.    
E' sconsigliato avere un backup remoto, dato che il volume dell'archivio della chain non permetterebbe un ripristino veloce.    
E' essenziale salvare anche il file `.cnd/data/priv_validator_state.json`, o nel caso di utilizzo del `tmkms` del file di stato riportato nella configurazione `state_file`. Questo file, in special modo, dovrà essere ripristinato nel caso l'aggiornamento fallisca.    

Necessario è fare un backup anche delle configurazioni, sia sui nodi validatori, sentry e tmkms, sempre per avere la possibilità di compiere un ripristino pulito nel caso di problemi.     

Se **NON** si è arrivati al punto 4. della [procedura di aggiornamento](#procedura-di-aggiornamento) questi sono i passaggi per la procedura di ripristino 

1. Fermare qualsiasi servizio
   ```bash
   systemctl stop cnd
   systemctl stop cncli
   pkill cnd
   pkill cncli
   ```
1. Ripristinare correttamente il file `app.toml`
   ```bash
   sed 's/^halt-block =.*/halt-block = 0/g' ~/.cnd/config/app.toml > ~/.cnd/config/app.toml.tmp
   mv ~/.cnd/config/app.toml.tmp  ~/.cnd/config/app.toml
   ```  
5. Avvio della precedente chain

   ```bash
   systemctl start cnd
   ```
6. Controllare lo stato del nodo
   ```bash
   journalctl -u cnd -f
   ```
   I nodi potrebbero impiegare del tempo per arrivare al consenso.
 

Se si è arrivati punto 4. o oltre della [procedura di aggiornamento](#procedura-di-aggiornamento) questi sono i passaggi per la procedura di ripristino è la seguente

1. Fermare qualsiasi servizio
   ```bash
   systemctl stop cnd
   systemctl stop cncli
   pkill cnd
   pkill cncli
   ```

2. Ripristinare i precedenti binari e le precedenti configurazioni

   ```bash
   cp ~/cnd_backup/bin/cn* ~go/bin/.
   cnd unsafe-reset-all
   rm -rf ~/.cnd/data 
   mv ~/cnd_backup/data ~/.cnd/.
   cp ~/cnd_backup/config/genesis.json ~/.cnd/config/.
   cp ~/cnd_backup/config/config.toml ~/.cnd/config/.
   ```

3. Verificare la versione corrente (v2.1.2) di _cnd_:

   ```bash
    cnd version --long
   ```  
   Dovrebbe riportare il seguente risultato
   ``` 
    name: commercionetwork
    server_name: cnd
    client_name: cndcli
    version: 2.1.2
    commit: 8d5916146ab76bb6a4059ab83c55d861d8c97130
    build_tags: netgo,ledger
    go: go version go1.15.8 linux/amd64
    ...
   ```

4. Ripristinare correttamente il file `app.toml`
   ```bash
   cp ~/cnd_backup/config/app.toml ~/.cnd/config/.
   sed 's/^halt-block =.*/halt-block = 0/g' ~/.cnd/config/app.toml > ~/.cnd/config/app.toml.tmp
   mv ~/.cnd/config/app.toml.tmp  ~/.cnd/config/app.toml
   ```  
5. Avvio della precedente chain

   ```bash
   systemctl start cnd
   ```
6. Controllare lo stato del nodo
   ```bash
   journalctl -u cnd -f
   ```
   I nodi potrebbero impiegare del tempo per arrivare al consenso.
 

# Note

## Spiegazioni guida
La guida cerca di dare un'impostazione generale di spiegazione di come agire durante l'aggiornamento. La difficoltà nel redigere questa guida è che ognuno ha un proprio ambiente, quindi difficilmente si può costruire un sistema completo.   
Il mantenimento di un qualche tipo di software che si adatti a tutti i sistemi e a tutti gli ambienti si rivelerebbe molto oneroso.   
Sostanzialmente tutta la procedura, limitatamente ai nodi, si riduce a
* fermare i servizi
* cambiare i programmi (binari) con la nuova versione
* cambiare un paio di file di configurazione
* pulire il database
* far ripartire i servizi
Compresa la procedura il processo sostanzialamente non è particolarmente complicato.
Ognuno può estrarre dalle indicazioni una propria procedura automatizzata.   
~~In ogni caso abbiamo tentato di implementare alcuni scripts di agevolazione.~~

### Errori o dubbi comuni

1. Il servizio mi ritorna un errore di permessi     
   Nella guida viene supposto di agire come `root` per tutto il processo. Se i servizi sono stati configurati con un altro utente, parametro `User=<UTENTE CHAIN>` in `/etc/systemctl/system/cnd.service`, allora le cartelle del `cnd` potrebbero non essere più accessibili con tale utente perché modificate da `root`.    
   Prima di avviare i servizi dovrebbe essere sufficiente lanciare il comando
   ```bash
   sudo chown -R <UTENTE CHAIN> ~/.cnd
   ```
   In generale, se la procedura verrà eseguita con un utente diverso da `root` sullo stop dei servizi e il loro riavvio utilizzate sempre `sudo`. Es. 

   ```
   sudo systemctl start cnd
   ```
   
2. Il nodo non ottiene il sign    
   Verificare che non ci siano problemi di rete tra il kms e il validatore, es. Vpn spenta. Un semplice `ping` dovrebbe essere sufficiente per verificare la raggiungibilità.   
   Se eventualmente avete fatto un riavvio del server e il servizio che gestisce la vpn parte successivamente all'avvio del servizio `cnd` allora il servizio potrebbe non riuscire a raggiungere il kms. Stoppate il servizio `cnd`, verificare la comunicazione tra kms e validatore, e avviate il servizio `cnd`
   Verificare inoltre se la configurazione nel file `config.toml` del validatore è cambiata perché ad esempio è stato tolto il valore di `priv_validator_laddr`

 
3. Se non mi presento cosa succede    
   Essenzialmente si hanno circa 17/18 ore di tempo per riattivare il validatore. La procedura, a parte le verifiche degli hash sono comunque valide. In questo caso si consiglia però di scaricare il genesis dal repo delle chains.

3. Ho dei hash di genesis diversi da tutti gli altri     
   In questo caso si applica la stessa procedura del punto precedente.
