# Istruzioni aggiornamento da 2.1.2 a 2.2.0 Chain Commercio Network

Il seguente documento descrive i passaggi necessari per eseguire l'aggiornamento dei nodi validatori della chain di Commercio Network da `commercio-2_1` (basata sulla versione 2.1.2 del core) a `commercio-2_2` (basata sulla versione 2.2.0 del core).    
Alla fine delle operazioni di aggiornamento verrà prodotto un file di genesis che verrà pubblicato su https://github.com/commercionetwork/chains, ma si invita tutti i validatori a partecipare attivamente alla procedura.

La data di aggiornamento è stata fissata per `22 Marzo 2021 alle 15.00 UTC` =


  - [Sommario](#Sommario)
  - [Migrazione](#Migrazioni)
  - [Operazioni preliminari](#operazioni-preliminari)
  - [Rischi](#rischi)
  - [Recupero](#recupero)
  - [Procedura di aggiornamento](#procedure-di-aggiornamento)
  - [Procedure aggiornamento full-node](#procedure-aggiornamento-full-node)
  - [Aggiornamento tmkms](#aggiornamento-tmkms)
  - [Notes for Service Providers](#notes-for-service-providers)
 
# Sommario

L'aggiornamento della chain è schedulata per il 22 Marzo 2021 alle 15.00 UTC (16.00 orario italiano).

Questi sono in breve i passi da compiere nell'aggiornamento

1. Fermare il nodo di Commercio Network con core v2.1.2
2. Eseguire un export dello stato della chain
3. Eseguire un backup delle configurazioni e dei dati della chain
4. Eseguire una migrazione dello stato della chain con il nuovo core di Commercio Network producendo il nuovo genesis 
5. Installare il nuovo core di Commercio Network e il nuovo genesis e eseguire un reset della chain
6. Avviare il demone del nuovo core e attendere il raggiungimento del consenso

I dettagli dell'aggiornamento sono nella sezione [Procedura di aggiornamento](#procedure-di-aggiornamento).     

Per i full-node (sentry) sono state create delle specifiche istruzioni su [Procedure aggiornamento full-node](#procedure-aggiornamento-full-node).

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


Maggiorni dettagli sono riportati in [docs.commercio.network](https://docs.commercio.network)


## Operazioni preliminari

Prima di eseguire l'aggiornamento ci sono alcuni aspetti da considerare
1. Verificare di avere abbastanza spazio su disco: attualmente il database pruned della chain occupa 50Gb, quindi il disco dei server deve avere abbastanza spazio da contenere il backup più almeno altri 10Gb per le operazioni di export e migration e per l'avvio della nuova chain 
2. Ram
3. E' consigliabile, non appena verrà pubblicato la release finale, la compilazione o lo scaricamento dei nuovi binari: compilare i binari durante l'aggiornamento potrebbe rallentare le operazioni
4. Preparare le configurazioni dei file `config.toml` e `app.toml` prima in modo da averli pronti nel momento dell'aggiornamento
5. Sospendere le transazioni almeno un'ora prima della migrazione.
6. Per chi fa uso di `tmkms` aggiornare da subito il tmkms almeno alla versione 0.9.0 (meglio 0.10.0) e seguire le procedure in [Aggiornamento tmkms](#aggiornamento-tmkms)

## Rischi

Uno dei maggiori rischi per i validatori è di incorrere nella doppia firma. E' imperativo controllare la versione del vostro software e il genesis. Inoltre è necessario spostare il file di stato, sia sul validatore, se si sta facendo uso di chiavi su file, che sul tmkms se si fa uso di quest'ultimo. **Non cancellare il file di stato**

Se durante l'aggiornamento viene fatto qualche errore, ad esempio utilizzando una versione errata del software o un genesis non corretto meglio aspettare che la chain riparta e unirsi successivamente.

## Ripristino

Prima dell'aggiornamento tutti i validatori sono tenuti a eseguire un backup dello stato della chain. Il backup deve essere eseguito sia su i nodi validatori sia sui sentry e in generale su qualsiasi full node della chain. E' sconsigliato avere un backup remoto, dato che il volume dell'archivio della chain non permetterebbe un ripristino veloce. E' essenziale salvare anche il file `.cnd/data/priv_validator_state.json`, o nel caso di utilizzo del `tmkms` del file di stato riportato nella configurazione `state_file`. Questo file, in special modo, dovrà essere ripristinato nel caso l'aggiornamento fallisca.    

Necessario è fare un backup anche delle configurazioni, sia sui nodi validatori, sentry e tmkms, sempre per avere la possibilità di compiere un ripristino pulito nel caso di problemi.     
      


## Procedura di aggiornamento

__Note__: Viene dato per scontato che il nodo su cui si va ad operare ha la versione v2.1.2 del core della chain.     
__Note 2__: Le istruzioni devono essere adattate al proprio ambiente, quindi variabili e path devono essere cambiate a seconda delle installazioni.

La versione/hash commit di commercio network è  v2.1.2: `8d5916146ab76bb6a4059ab83c55d861d8c97130`

1. Verificare la versione corrente (v2.1.2) di _cnd_:

   ```bash
    $ cnd version --long
    name: commercionetwork
    server_name: cnd
    client_name: cndcli
    version: 2.1.2
    commit: 8d5916146ab76bb6a4059ab83c55d861d8c97130
    build_tags: netgo,ledger
    go: go version go1.15.8 linux/amd64
   ```

2. Verificare che sia impostato il blocco di stop esatto: `xxxx`


    ```bash
    sed 's/^halt-block =.*/halt-block = xxxxx/g' ~/.cnd/config/app.toml > ~/.cnd/config/app.toml.tmp
    mv ~/.cnd/config/app.toml.tmp  ~/.cnd/config/app.toml
    ```

1. Dopo lo stop della chain eseguire l'export dello stato:
   ```bash
    cnd export --for-zero-height  > commercio-2_1_genesis_export.json
   ```
   **NB**: questa operazione è necessaria solo sul nodo validatore. Il genesis prodotto poi potrà essere installato sui nodi sentry.     
   Il processo potrebbe richiedere un po' di tempo e dipende dalle risorse disponibili sul nodo.

2. Salvataggio delle vostra cartella `.cnd` directory

    ```bash
    mv ~/.cnd ./cnd_backup
    ```

    **NB**: Il backup è fondamentale nel caso la procedura non riuscisse e tutti i nodi sono invitati a eseguirla. Il backup verrà utilizzato nell'eventualità come indicato nella sezione See [Ripristino](#ripristino).



3. Verifca del checsum del file gensis esportato:

    Attraverso la comunicazione in chat tutti i nodi validatori dovranno postare il risultato del checksum dell'export

   ```bash
   $ jq -S -c -M '' commercio-2_1_genesis_export.json | shasum -a 256
   ```

   Il risultato dovrebbe essere nella formula
   ```
   [SHA256_VALUE]  commercio-2_1_genesis_export.json
   ```
   Copiare e incollare sul gurppo di Telegram il valore `[SHA256_VALUE]` e compararlo con tutti gli altri validatori


4. A questo punto deve essere eseguira la migrazione del file di genesis per rendere conforme il nuovo stato per il nuovo core.
Scaricare e installare i binari.

   ```bash
   $ git clone https://github.com/commercio/commercionetwork && cd commercionetwork && git checkout v2.2.0; make install
   ```

   Se sono già stati compilati i binari potete direttamente copiare i binari nei path dei precedenti binari.

1. Verificare che gli applicativi siano la versione giusta:

   ```bash
    cnd version
    name: cnd
    server_name: cnd
    version: v2.2.0
    commit: 6d46572f3273423ad9562cf249a86ecc8206e207
    build_tags: netgo,ledger
    ...
   ```
    The version/commit hash of Gaia v2.2.0: `-----`

2. Migrazione alla nuova versione:

   ```bash
   cnd migrate \
    commercio-2_1_genesis_export.json \
    --chain-id=commercio-2_2 \
    --genesis-time="" > genesis.json
   ```


3. Verificare il checksum del genesis prodotto:

   ```bash
   $ jq -S -c -M '' genesis.json | shasum -a 256
   ```

   Il risultato dovrebbe essere nella formula
   ```
   [SHA256_VALUE]  genesis.json
   ```
   Copiare e incollare sul gurppo di Telegram il valore `[SHA256_VALUE]` e compararlo con tutti gli altri validatori

4. Reset dello stato della chain:

   **NOTE**: questo è un punto molto delicato e assicuratevi per l'ennesima volta di avere un backup del database della chain. 

   ```bash
   cnd unsafe-reset-all
   ```

5. Installare il nuovo geneis sulla nuova chain

    ```bash
    cp genesis.json ~/.cnd/config/
    ```

6. Avvio della nuova chain

    ```bash
    cnd start
    ```
    Naturalmente se è stato predisposto un servizio il comando da lanciare sarà
    ```bash
    systemctl start cnd
    ```

# Guida per i full node

1. 