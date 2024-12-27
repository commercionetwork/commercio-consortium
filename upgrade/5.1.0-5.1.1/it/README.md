# Istruzioni di aggiornamento dalla versione 5.1.0 alla versione 5.1.1 della Chain Mainnet di Commercio Network 

## Prerequisiti


1. Avere un nodo funzionante in **mainnet** con la versione del software v5.1.0.
2. Avere tutti i tools sul server per compilare l'applicazione come menzionato ne primo paragrafo [Installing the software requirements](https://docs.commercio.network/nodes/full-node-installation.html#_1-installing-the-software-requirements)

## ATTENZIONE

Questo è una versione di correzione della precedente. L'aggiornamento è **OBBLIGATORIO**. I nodi che non si aggiorneranno non potranno riprendere l'operatività.

## Raccomandazioni

Per eseguire l'aggiornamento in modo rapido e semplice, utilizzare `cosmovisor`

## Informazioni sull'aggiornamento

Questo aggiornamento verrà eseguito senza una proposta. Qualsiasi operatore può aggiornare il proprio nodo alla nuova versione in qualsiasi momento.

## Procedura di aggiornamento

Tutti i comandi devono essere eseguiti come utente che possa usare comandi con `sudo` o come utente `root`. **Ogni operatore deve adattare i comandi al proprio ambiente.**


1. Arrestare il servizio del nodo
   ```bash
   sudo systemctl stop commercionetworkd.service
   ```
2. Controllare la versione di golan installata. Se hai la versione 1.23.x esegui un downgrade. Se hai snap installato utilizza il comando qui sotto
   ```bash
   sudo snap remove go --purge
   sudo snap install go --channel=1.22/stable --classic
   ```

   Verificate la versione di go installata
   ```bash
   go version
   ```
3. Scaricare il repository da GitHub **se non lo avete già fatto**. Se avete già una copia locale del repository non provare a clonarlo.
   ```bash
   git clone https://github.com/commercionetwork/commercionetwork.git $HOME/commercionetwork
   ```
4. Entrare nella cartella e fare il checkout alla nuova versione
   ```bash
   cd $HOME/commercionetwork
   git fetch --tags && git checkout v5.1.1
   ```
5. Eseguire la build della nuova versione
   ```bash
   make build
   ```
6. Controllare la versione della build di make
   ```bash
   ./build/commercionetworkd version
   ```
   Dovrebbe restituire la versione `5.1.1`
7. Pulire la cache di wasm
   ```bash
   rm -rf $HOME/.commercionetwork/data/wasm/cache
   ```
8.  Copiare il nuovo binario nella cartella
   ```bash
   cp $HOME/commercionetwork/build/commercionetworkd $HOME/.commercionetwork/cosmovisor/current/bin/.
   ```
9.  Controllare la versione del binario
   ```bash
   $HOME/.commercionetwork/cosmovisor/current/bin/commercionetworkd version
   ```
   Dovrebbe restituire la versione `5.1.1`
10. Riavviare il servizio
   ```bash
   sudo systemctl start commercionetworkd.service
   ```
11. Controllare se il servizio funziona
   ```bash
   journalctl -u commercionetworkd.service -f
   ```

**NOTA**: All'inizio del log la chain sembra essere bloccata, ma dopo l'aggiornamento di un numero sufficiente di peer, la chain inizierà a funzionare correttamente.


### Su errore di aggiornamento

Se si verifica un errore, è possibile chiedere aiuto sul [Canale Discord](https://discord.com/channels/973149882032468029/973163682030833685)



