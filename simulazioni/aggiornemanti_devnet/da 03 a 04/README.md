# Guida aggiornamento chain da commercio-devnet03 a commercio-devnet04

## Premessa
 
A differenza degli aggiornamenti precedenti quello tra devnet03 a devnet04 annulla tutte le precedenti transazioni.     
Questo aggiornamento è stato necessario per ripulire la chain da errori fatti nelle prime 3 chain che mettevano a rischio il normale funzionamento.   
Tutti i token sono stati ridistribuiti ai wallet blackcard della devnete per permettere di ricreare i nodi validatori.     
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
export NEW_CHAIN_ID="commercio-devnet04"
export CHAIN_ID="commercio-devnet04"
export VERSIONE_BINARI=master
export VERSIONE_BUILD="2.1.2"
```

Eventualmente creare il file e impostarlo 

```bash
cd
echo 'export HOME_CND="/root/.cnd"' > env_update_chain_04.txt
echo 'export HOME_CND_CONFIG="$HOME_CND/config"' >> env_update_chain_04.txt
echo 'export HOME_CND_DATA="$HOME_CND/data"' >> env_update_chain_04.txt
echo 'export BIN_DIR="/root/go/bin"' >> env_update_chain_04.txt
echo 'export SRC_GIT_DIR="/root/commercionetwork"' >> env_update_chain_04.txt
echo 'export BUILD_DIR="$SRC_GIT_DIR/build"' >> env_update_chain_04.txt
echo 'export NEW_CHAIN_ID="commercio-devnet04"' >> env_update_chain_04.txt
echo 'export CHAIN_ID="commercio-devnet04"' >> env_update_chain_04.txt
echo 'export VERSIONE_BINARI=master' >> env_update_chain_04.txt
echo 'export VERSIONE_BUILD="2.1.2"' >> env_update_chain_04.txt

source ./env_update_chain_04.txt

echo '. /root/env_update_chain_04.txt' >> ~/.profile

```



## 3) Compilare i nuovi binari

Se non è già stato scaricato clonare il repository

```bash
git clone https://github.com/commercionetwork/commercionetwork.git $SRC_GIT_DIR
```

Cambiare cartella ed eseguire il build

```bash
cd $SRC_GIT_DIR
git pull
git checkout v$VERSIONE_BUILD
git pull
make clean
make build
$BUILD_DIR/cnd version
#dovrebbe corrispondere a $VERSIONE_BUILD
cd
```

## 4) Assicurarsi di aver stoppato servizi

```bash
service cnd stop
service cncli stop
pkill cnd
pkill cncli
```

## 5) Cambiare i binari

```bash
cp $BUILD_DIR/cn* $BIN_DIR/.
```

## 6) Creare un salvataggio dei dati della chain e delle configurazioni (opzionale)

```bash
mv  $HOME_CND_DATA data_backup_chain_03_04
cp -r $HOME_CND_CONFIG config_backup_chain_03_04
```

## 7) Scaricare il nuovo genesis

```
curl https://raw.githubusercontent.com/commercionetwork/chains/master/commercio-devnet04/genesis.json > $HOME_CND_CONFIG/genesis.json
```

## 8) Verificare eventualmente il checksum

Nel file `https://github.com/commercionetwork/chains/blob/master/commercio-devnet04/.data` confrontare il valore **Ordered Checksum** con il valore ottenuto dal seguente comando

```bash
jq -S -c -M '' $HOME_CND_CONFIG/genesis.json | shasum -a 256
```


## 9) Reset della chain

```bash
cnd unsafe-reset-all
```

**Attenzione**: per chi ha implementato il `KMS` nelle precedenti devnet seguire le [istruzione specifiche](#kms) 


## 10) Ripartenza della chain

```bash
service cnd start
```


## 11) La nuova chain dovrebbe partire ed eseguire la sincronizzazione 

```bash
journalctl -u cnd -f
```

## 12) Configurare il cncli per la nuova chain

```bash
cncli config chain-id $NEW_CHAIN_ID
```

## 13) Ricreare il wallet creatore del nodo validatore

Sufficiente dal wallet blackcard versare 2 token a un wallet che servirà per creare il validatore

```bash
cncli tx send \
 <did wallet blackcard> \
 <did wallet creatore> \
 2000000ucommercio \
 --fees 10000ucommercio -y
```
## 14) Eseguire la transazione di per diventare validatore e delegare i token

Tale procedura è documentata nella guida ufficiale e dovrebbe essere nota a tutti i nodi validatori.     
Riferirsi alla guida [Create a validator](https://docs.commercio.network/nodes/validator-node-installation.html#_3-create-a-validator)




# KMS

I kms vanno riconfigurati per la nuova chain, quindi ci si deve ricordare le seguenti azioni da intraprendere

1. Ricordarsi di cancellare o spostare i file di stato per i kms
2. Cambiare le configurazioni con i riferimenti della nuova chain

A tal proposito suggerisco di preparare già il file di configurazione nuovo e di controllarlo.      
L'indirizzo pubblico del validatore e l'indirizzo operatore, ossia `did:com:valconspub1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` e `did:com:valoper1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`, non cambiano.

1. Il nodo è fermo (assicurarsi quindi di essere arrivati al [punto 9](#9-reset-della-chain))
2. Stop del servizio sul kms
3. Cambio del file di configurazione precedentemente preparato
4. Cancellazione o spostamento del file di stato
5. Ripartenza del servizio sul kms
6. Proseguire con il [punto 10](#10-ripartenza-della-chain)
7. Quando il nodo riparte controllare il servizio sul kms che riesca a connettersi al nodo
8. Proseguire fino al punto [punto 14](#14-eseguire-la-transazione-di-validatore) ed eseguira la procedura di creazione del validatore
9. Nel momento in cui viene eseguita la procedura di creazione del nodo si dovrebbe vedere che il kms comincia il sign

