# Istruzioni aggiornamento da 2.2.0 a 3.0.0 Chain Commercio Network (WIP)
# IL BLOCCO DI STOP VERRA' COMUNICATO A BREVE.

La data di aggiornamento è stata fissata per `23 Febbraio 2022 alle 14.30 UTC` = `15.30 CET`. L'altezza pubblicata dovrebbe fermare la chain poco dopo le 14.30 UTC = 15.30 CET. Lo scostamento potrebbe essere di qualche minuto. 


  - [Sommario](#Sommario)
  - [Migrazione](#Migrazioni)
  - [Operazioni preliminari](#operazioni-preliminari)
  - [Rischi](#rischi)
  - [Procedura di aggiornamento validatore](#procedura-di-aggiornamento)
  - [Procedure aggiornamento full-node](#guida-per-i-full-node-sentry)
  - [Ripristino](#ripristino)
  - [Note](#note)
 
# Sommario

L'aggiornamento della chain è schedulata per il 23 Febbraio 2022 alle 14.30 UTC (15.30 orario europa centrale).

Questi sono in breve i passi da compiere nell'aggiornamento

1. Fermare il nodo di Commercio Network con core v2.2.0
1. Eseguire un export dello stato della chain
1. Eseguire una migrazione dello stato della chain con il nuovo core di Commercio Network producendo il nuovo genesis 
1. Installare il nuovo core di Commercio Network e il nuovo genesis e eseguire un reset della chain
1. Avviare il demone del nuovo core e attendere il raggiungimento del consenso

I dettagli dell'aggiornamento sono nella sezione [Procedura di aggiornamento](#procedura-di-aggiornamento).     

Per i full-node (sentry) sono state create delle specifiche istruzioni su [Procedure aggiornamento full-node](#guida-per-i-full-node-sentry).

**UNA PROCEDURA PIU' TECNICA PUO' ESSERE TROVATA A [QUESTA PAGINA](./upgrade_tech.md).**


Il coordinamento dei nodi verrà gestito all'interno del canale Telegram per i nodi validatori.

**Importante** l'aggiornamento potrebbe avere i seguenti risultati:
1. `Aggiornamento riuscito`: i validatori riescono nella migrazione e nell'aggiornamento e la nuova chain verrà avviata. Il periodo per l'emissione del primo blocco e il raggiungimento del consenso potrebbe richiedere parecchio tempo.
2. `Avvio nuova chain fallito`: se vengono riscontrati dei problemi durante l'avvio della nuova chain e non è possibile raggiungere il consenso. In questo caso verranno fermati i nodi e verrà recuperato il backup e la chain ripartirà con la precedente versione. L'aggiornamento verrà rischedulato verificando i problemi riscontrati e eseguendo i fix relativi.  
3. `Procedura non completabile`: nel caso già a livello di export o migrazione venissero riscontrati problemi che non consentono di procedere l'aggiornamento (es. il checksum del nuovo genesis non corrisponde tra i nodi validatori) verrà abortito e si procederà a recuperare il backup della chain e facendo ripartire la precedente versione.

# Migrazione

La migrazione coinvolge sostanziali cambiamenti in alcuni moduli e altri cambiamenti minori su altri. 
Di seguito vengono elencati i cambiamenti più rilevanti

1. `Id` -> `Did`
1. `Documents`
2. `CommercioKyc`
3. `CommercioMint`
4. `VBR`
5. `Ante`
6. `Government`

Maggiori dettagli sono riportati in [docs.commercio.network](https://docs.commercio.network). In tale documentazione sono evidenziati in alto a destra la documentazione della versione `2.1.2`, `2.2.0` e quella della versione `3.0.0`


## Operazioni preliminari

Prima di eseguire l'aggiornamento ci sono alcuni aspetti da considerare
1. Verificare di avere abbastanza spazio su disco: attualmente il database pruned della chain occupa 80/90Gb, quindi il disco dei server deve avere abbastanza spazio da contenere il database della chain precedente che fungerà da backup più almeno altri 5Gb per le operazioni di export e migration e per l'avvio della nuova chain 
2. **Ram**: minima richiesta 8Gb. Consigliata 16Gb.
3. E' consigliabile, non appena verrà pubblicato la release finale, la **compilazione sul nodo**: compilare i binari durante l'aggiornamento potrebbe rallentare le operazioni. **La versione finale sarà con il tag `v3.0.0`**
4. Preparare le configurazioni dei file `config.toml` e `app.toml` prima in modo da averli pronti nel momento dell'aggiornamento
5. Sospendere le transazioni dove possibile: le transazioni nel momento in cui la chain verrà fermata verranno rifiutate e quindi il loro invio dipenderà da come il client che invia gestisce tali errori.
6. Per chi fa uso di `tmkms` aggiornare da subito il tmkms almeno alla versione 0.9.0 (meglio 0.10.0). Per chi usa lo yubiHSM con una sola chiave leggere la procedura in [Aggiornamento tmkms](./aggiornamento-tmkms.md). Chi invece usa lo yubiHSM con chiavi multiple leggere la guida [Aggiornamento tmkms con chiavi multiple](./aggiornamento-tmkms-chiavi-multiple.md)

## Rischi

Uno dei maggiori rischi per i validatori è di incorrere nella doppia firma. E' assolutamente necessario controllare la versione del vostro software e il genesis. Inoltre è necessario spostare il file di stato, sia sul validatore, se si sta facendo uso di chiavi su file, che sul tmkms se si fa uso di quest'ultimo. **Non cancellare il file di stato**

Se durante l'aggiornamento viene fatto qualche errore, ad esempio utilizzando una versione errata del software o un genesis non corretto meglio aspettare che la chain riparta e unirsi successivamente.

**LEGGERE ATTENTAMENTE LA SEZIONE [RIPRISTIONO](#ripristino)**

## Procedura di aggiornamento

__Note__: Viene dato per scontato che il nodo su cui si va ad operare ha la versione v2.2.0 del core della chain.     
__Note 2__: Le istruzioni devono essere adattate al proprio ambiente, quindi variabili e path devono essere cambiate a seconda delle installazioni.


La versione/hash commit di commercio network è v2.2.0: `3e02d5e761eab3729ccf6f874d3c929342e4230c`

1. Verificare la versione corrente (v2.2.0) di _cnd_:

   ```bash
    cnd version --long
   ```  
   Dovrebbe riportare il seguente risultato
   ``` 
   name: commercionetwork
   server_name: cnd
   client_name: cndcli
   version: 2.2.0
   commit: 3e02d5e761eab3729ccf6f874d3c929342e4230c
   build_tags: netgo,ledger
   go: go version go1.17.5 linux/amd64
   build_deps:
    ...
   ```

   Installare il tool adeguati se non presenti

   ```bash
   apt install jq -y
   ```

   Controllare la versione di `go` che sia almeno `1.16+`


2. Verificare che sia impostato il blocco di stop esatto: `2248540` (Verrà fatto un check comunque la mattina del 23/02/2022 per verificare il progresso dei blocchi)

   
   ```bash
   sed 's/^halt-height =.*/halt-height = 2248540/g' ~/.cnd/config/app.toml > ~/.cnd/config/app.toml.tmp
   mv ~/.cnd/config/app.toml.tmp  ~/.cnd/config/app.toml
   ```
   E applicare la configurazione usando il comando 
   ```bash
   systemctl restart cnd
   ```
   Il nodo si dovrebe fermare all'altezza `2248540`. Controllare con

   ```bash
   journalctl -u cnd -f
   ```

3. Dopo lo stop della chain fermare il nodo e eseguire l'export dello stato:
   ```bash
   systemctl stop cnd
   systemctl stop cncli
   pkill cnd
   pkill cncli
   ```
   **Attenzione**: il comando `systemctl stop cncli` potrebbe dare un errore, dato che il servizio `cncli` serve solo per le rest api e non è predisposto ovunque.

   Eseguire l'export della chain
   ```bash
   cnd export  > ~/commercio-2_2_genesis_export.json
   ```
   **NB**: questa operazione è necessaria solo sui nodi validatori. Il genesis prodotto poi potrà essere installato sui nodi sentry.     
   Il processo potrebbe richiedere un po' di tempo e dipende dalle risorse disponibili sul nodo.

4. Salvataggio delle vostra cartella `.cnd` directory

   ```bash
    mkdir -p ~/cnd_backup/bin
    mv ~/.cnd/data ~/cnd_backup/.
    cp -r ~/.cnd/config ~/cnd_backup/.
    cp ~go/bin/cn* ~/cnd_backup/bin/.
   ```

    **NB**: Il backup è fondamentale nel caso la procedura non riuscisse e tutti i nodi sono invitati a eseguirla. Il backup verrà utilizzato nell'eventualità come indicato nella sezione See [Ripristino](#ripristino).



5. Verifca del checsum del file gensis esportato:

   Attraverso la comunicazione in chat tutti i nodi validatori dovranno postare il risultato del checksum dell'export

   ```bash
   $ jq -S -c -M '' ~/commercio-2_2_genesis_export.json | shasum -a 256
   ```

   <img src="../img/attetion.png" width="30">Il risultato dovrebbe essere del tipo
   ```
   [SHA256_VALUE]  commercio-2_2_genesis_export.json
   ```
   Copiare e incollare sul gruppo di Telegram il valore `[SHA256_VALUE]` e compararlo con tutti gli altri validatori


6. Compilare i nuovi binari

   ```bash
    git clone https://github.com/commercionetwork/commercionetwork.git && cd commercionetwork
    git checkout v3.0.0
    make install
   ```


7. Verificare che gli applicativi siano la versione giusta:

   ```bash
    commercionetworkd version
    ```
    I valori dovrebbe essere 
    ```
    name: commercionetworkd
    server_name: commercionetworkd
    version: v3.0.0
    commit: ??????
    build_tags: netgo,ledger
    ...
   ```
    La versione hash del nuovo software dovrebbe essere v3.0.0: `????`

8. A questo punto deve essere eseguita la migrazione del file di genesis per rendere conforme il nuovo stato per il nuovo core.
   Deve essere acquisito l'ultima altezza validata per la chain

   ```bash
   cat .cnd/data/priv_validator_state.json
   ```   

   ```bash
   commercionetworkd migrate v3.0.0 \
    ~/commercio-2_2_genesis_export.json \
    --chain-id=commercio-3 \
    --initial-height=2248541 > ~/genesis.json
   ```


9.  Verificare il checksum del genesis prodotto:

   ```bash
   $ jq -S -c -M '' ~/genesis.json | shasum -a 256
   ```

   Il risultato dovrebbe essere del tipo
   ```
   [SHA256_VALUE]  genesis.json
   ```
   <img src="../img/attetion.png" width="30">Copiare e incollare sul gruppo di Telegram il valore `[SHA256_VALUE]` e compararlo con tutti gli altri validatori

10. Reset/inizializzazione cartelle della chain:
   ```bash
   commercionetworkd unsafe-reset-all
   ```
   Dovrebbe prodursi una cartella sulla propria home `.commmercionetwork`

1.  Installare il nuovo geneis della nuova chain

   ```bash
   cp ~/genesis.json ~/.commmercionetwork/config/
   ```
   <img src="../img/attetion.png" width="30"> **ATTENZIONE** in questa fase devono essere aggiornati prima i sentry. Verificare la [procedura di aggiornamento full node](#guida-per-i-full-node-sentry)

12. Verificare le configurazioni del file `congit.toml`.
    
13. Creazione del nuovo service
   ```bash
      tee /etc/systemd/system/commercionetworkd.service > /dev/null <<EOF  
      [Unit]
      Description=Commercio Node
      After=network-online.target

      [Service]
      User=root
      ExecStart=/root/go/bin/commercionetworkd start
      Restart=always
      RestartSec=3
      LimitNOFILE=4096

      [Install]
      WantedBy=multi-user.target
      EOF
   ```

14. Avvio della nuova chain
   ```bash
   systemctl start commercionetworkd
   ```
15. Controllare lo stato del nodo
   ```bash
   journalctl -u commercionetworkd -f
   ```
   I nodi potrebbero impiegare del tempo per arrivare al consenso.


# Guida per i full node (Sentry)

1. Verificare che sia impostato il blocco di stop esatto: `2937550`

   
   ```bash
   sed 's/^halt-height =.*/halt-height = 2937550/g' ~/.cnd/config/app.toml > ~/.cnd/config/app.toml.tmp
   mv ~/.cnd/config/app.toml.tmp  ~/.cnd/config/app.toml
   ```
   E applicare la configurazione usando il comando 
   ```bash
   systemctl restart cnd
   ```
   Il nodo si dovrebe fermare all'altezza `2937550`. Controllare con

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


3. Compilare i nuovi binari

   ```bash
   git clone https://github.com/commercionetwork/commercionetwork.git && cd commercionetwork && git checkout v2.2.0; make install
   ```

   Se sono già stati compilati i binari potete direttamente copiare i binari nei path dei precedenti binari.   
   I binari possono essere anche copiati da un'altra macchina (validatore ad esempio) con la stessa architettura della macchina del full node.

4. Verificare che gli applicativi siano la versione giusta:

   ```bash
    cnd version
    ```
    I valori dovrebbe essere 
    ```
    name: commercionetworkd
    server_name: commercionetworkd
    version: v3.0.0
    commit: ??????
    build_tags: netgo,ledger
    ...
   ```
    La versione hash del nuovo software dovrebbe essere v3.0.0: `????`

5. Reset dello stato della chain:

   ```bash
   commercionetworkd unsafe-reset-all
   ```
6. Installare il nuovo geneis della nuova chain
   
   Da un nodo validatore o dal repo della chains (questo però sarà pronto solo dopo il completamento della procedura) copiare il genesis.
   **Dal vostro computer, quindi fuori dai server, supposto che stiate utilizzando ssh per l'accesso e che la procedura sul validatore sia al punto 11**
   ```bash
   scp <UTENTE VALIDATORE>@<IP VALIDATORE>:.commercionetwork/config/genesis.json .
   scp genesis.json <UTENTE FULL NODE>@<IP FULL NODE>:.commercionetwork/config/.
   ```
7. Installare il service

8. Avvio della nuova chain

   ```bash
   systemctl start commercionetworkd
   ```

## Ripristino

Prima dell'aggiornamento tutti i validatori sono tenuti a mantenere la cartella `.cnd` come backup dello stato della chain. Il backup deve mantenuto sia su i nodi validatori sia sui sentry e in generale su qualsiasi full node della chain.    
E' essenziale salvare anche il file `.cnd/data/priv_validator_state.json`, o nel caso di utilizzo del `tmkms` del file di stato riportato nella configurazione `state_file`. Questo file, in special modo, dovrà essere ripristinato nel caso l'aggiornamento fallisca.    

Necessario è fare un backup anche delle configurazioni, sia sui nodi validatori, sentry e tmkms, sempre per avere la possibilità di compiere un ripristino pulito nel caso di problemi.     

Dalla [procedura di aggiornamento](#procedura-di-aggiornamento) questi sono i passaggi per la procedura di ripristino 

1. Fermare qualsiasi servizio
   ```bash
   systemctl stop commercionetworkd
   pkill commercionetworkd
   ```

2. Ripristinare correttamente il file `app.toml`
   ```bash
   cp ~/cnd_backup/config/app.toml ~/.cnd/config/.
   sed 's/^halt-height =.*/halt-height = 0/g' ~/.cnd/config/app.toml > ~/.cnd/config/app.toml.tmp
   mv ~/.cnd/config/app.toml.tmp  ~/.cnd/config/app.toml
   ```  


3. Avvio della precedente chain

   ```bash
   systemctl start cnd
   ```
4. Controllare lo stato del nodo
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
