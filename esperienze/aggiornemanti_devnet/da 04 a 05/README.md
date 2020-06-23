# Guida aggiornamento chain da commercio-devnet03 a commercio-devnet04

## Premessa
 
La devnet05 è ottenuta da un'esportazione a una certa altezza della predente devnet04, escludendo le transazioni di creazione di nodi che hanno portato alla perdita di consenso.
Generalmente non è richiesta nessuna particolare azione ai validatori, se non spegnere il proprio nodo, fare un reset della chain e installare il nuovo genesis.   
Per chi sta utilizzando il kms vedere [in fondo la procedura da adottare](#kms).      

## Prerequisiti

Installare jq: usare il comando 

```bash
apt install jq -y
```

## 1) Installazione da zero
Chiunque installi il nodo da zero può riferirsi alla [guida ufficiale](https://docs.commercio.network), e alle istruzioni che vengono distribuite ai validatori sull'utilizzo di strumenti come i kms.   
Se invece siete nodi che hanno partecipato ai precedenti aggiornamenti della devente preseguite al [punto 2](#2-configurare-i-path-e-le-variabili)


## 2) Configurare i path e le variabili 
Questo passaggio dovrebbe già essere stato svolto, in particolare devono essere configurate le variabili seguenti


(ricordarsi di ricaricarle ad ogni login o creare un file da cui fare il source: source ./nome_file)

```bash
export HOME_CND="/root/.cnd"
export HOME_CND_CONFIG="$HOME_CND/config"
export HOME_CND_DATA="$HOME_CND/data"
export BIN_DIR="/root/go/bin"
export SRC_GIT_DIR="/root/commercionetwork" #Cambiare
export BUILD_DIR="$SRC_GIT_DIR/build"
export NEW_CHAIN_ID="commercio-devnet05"
export CHAIN_ID="commercio-devnet05"
export VERSIONE_BINARI=master
export VERSIONE_BUILD="2.1.2"
export NEW_GENESIS_TIME="2020-06-23T14:30:00Z"
```

Eventualmente creare il file e impostarlo 

```bash
cd
echo 'export HOME_CND="/root/.cnd"' > env_update_chain_05.txt
echo 'export HOME_CND_CONFIG="$HOME_CND/config"' >> env_update_chain_05.txt
echo 'export HOME_CND_DATA="$HOME_CND/data"' >> env_update_chain_05.txt
echo 'export BIN_DIR="/root/go/bin"' >> env_update_chain_05.txt
echo 'export SRC_GIT_DIR="/root/commercionetwork"' >> env_update_chain_05.txt
echo 'export BUILD_DIR="$SRC_GIT_DIR/build"' >> env_update_chain_05.txt
echo 'export NEW_CHAIN_ID="commercio-devnet05"' >> env_update_chain_05.txt
echo 'export CHAIN_ID="commercio-devnet05"' >> env_update_chain_05.txt
echo 'export VERSIONE_BINARI=master' >> env_update_chain_05.txt
echo 'export VERSIONE_BUILD="2.1.2"' >> env_update_chain_05.txt
echo 'export NEW_GENESIS_TIME="2020-06-23T14:30:00Z"' >> env_update_chain_05.txt

source ./env_update_chain_05.txt

echo '. /root/env_update_chain_05.txt' >> ~/.profile

```

## 3) Assicurarsi di aver stoppato servizi

```bash
service cnd stop
service cncli stop
pkill cnd
pkill cncli
```

## 4) Creare un salvataggio dei dati della chain e delle configurazioni (opzionale)

```bash
mv  $HOME_CND_DATA data_backup_chain_04_05
cp -r $HOME_CND_CONFIG config_backup_chain_04_05
```

## 5) Scaricare il nuovo genesis

```
curl https://raw.githubusercontent.com/commercionetwork/chains/master/commercio-devnet05/genesis.json > $HOME_CND_CONFIG/genesis.json
```

## 6) Verificare eventualmente il checksum

Nel file `https://github.com/commercionetwork/chains/blob/master/commercio-devnet05/.data` confrontare il valore **Ordered Checksum** con il valore ottenuto dal seguente comando

```bash
jq -S -c -M '' $HOME_CND_CONFIG/genesis.json | shasum -a 256
```


## 7) Reset della chain

```bash
cnd unsafe-reset-all
```

**Attenzione**: per chi ha implementato il `KMS` nelle precedenti devnet seguire le [istruzione specifiche](#kms) 


## 8) Ripartenza della chain

```bash
service cnd start
```


## 9) La nuova chain dovrebbe partire ed eseguire la sincronizzazione 

```bash
journalctl -u cnd -f
```

## 10) Configurare il cncli per la nuova chain

```bash
cncli config chain-id $NEW_CHAIN_ID
```

## 11) Controllo validatore

In teoria il validatore nella chain precedente è ancora attivo.    
Alcuni token devono essere ridistribuiti ai wallet.    
Eventualmente eseguire la transazione in `unjail`


# KMS

I kms vanno riconfigurati per la nuova chain, quindi ci si deve ricordare le seguenti azioni da intraprendere

1. Ricordarsi di cancellare o spostare i file di stato per i kms
2. Cambiare le configurazioni con i riferimenti della nuova chain

A tal proposito suggerisco di preparare già il file di configurazione nuovo e di controllarlo.      
L'indirizzo pubblico del validatore e l'indirizzo operatore, ossia `did:com:valconspub1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` e `did:com:valoper1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`, non cambiano.

1. Il nodo è fermo (assicurarsi quindi di essere arrivati al [punto 7](#7-reset-della-chain)
2. Stop del servizio sul kms
3. Cambio del file di configurazione precedentemente preparato
4. Cancellazione o spostamento del file di stato
5. Ripartenza del servizio sul kms
6. Proseguire con il [punto 8](#8-ripartenza-della-chain)
7. Quando il nodo riparte controllare il servizio sul kms che riesca a connettersi al nodo
8. In teoria il nodo dovrebbe ricominciare a fare il sign

