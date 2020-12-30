# Installare un archive node.

## Prefazione

Nell'evoluzione della chain è necessario compiere degli aggiornamenti.    
Questi aggiornamenti comportano l'esportazione dello stato della chain attuale e la migrazione alla nuova versione, che ripartirà dal blocco zero.   
Per non perdere nessuna transazione è necessario creare dei nodi storici o archvie node, che riportano tutte le transazioni eseguite sulla chain, senza più aumentare il numero di blocchi.    

---

## Installazione di un archive node.

Da qui in poi quando si parlerà di `chain` si intenderà la versione di cui si vuole creare il nodo storico

1. Scaricare la versione dei binari su cui si basava la  `chain` 
2. Lanciare il comando `cnd unsafe-reset-all`
3. Scaricare il genesis.json della `chain` e installarlo nella cartella `.cnd/config/`
4. Scaricare il dump della `chain`
5. Copiare il dump nella cartella `.cnd/data/`
6. Avviare il demone con `cnd start`, o avviare il service
---
## Installazione di un archive per `commercio-testnet9001`.

**Attenzione**: le istruzioni sono pensate per l'utilizzo su macchina linux e con privilegi di root

### 1. Scaricare i binari

Dalla macchina su cui si sta installando il nodo lanciare

```bash
apt install -y git gcc unzip

wget https://github.com/commercionetwork/commercionetwork/releases/download/v2.1.2/Linux-AMD64.zip

unzip -o Linux-AMD64.zip && rm Linux-AMD64.zip
```

### 2. Inizializzare le cartelle 

```bash
./cnd unsafe-reset-all
```

La cartella `~/.cnd` dovrebbe essere stata creata

### 3. Scaricare il genesis

```bash
wget https://github.com/commercionetwork/chains/raw/master/commercio-testnet9001/genesis.json -P ~/.cnd/config
```
### 4. Scaricare il dump

```bash
wget http://178.62.202.95:7123/archive/archive_commercio_network_9001.tgz -P ~/.cnd
```


### 5. Copiare il dump nella cartella data

```bash
cd ~/.cnd/
tar -zxf archive_commercio_network_9001.tgz
```
### 6. Avviare il demone

```bash
cd
./cnd start
```
Usare `Ctrl + C` per interrompere

oppure se si ha un service configurato, [vedi](https://docs.commercio.network/nodes/full-node-installation.html#_4-configure-the-service) (attenzione ai path dei binari) usare

```bash
systemctl start cnd
```


### 7. Altre operazioni

Il nodo è configurato. Eventualmente si può anche lanciare il server per le [rest api](https://docs.commercio.network/nodes/full-node-installation.html#_6-start-the-rest-api), o anche installare un qualsiasi explorer compatibile con cosmos-sdk o personalizzato per commercio.network.    

Il nodo rimarrà sempre alla stessa altezza e non procederà ulteriormente.     

Qualsiasi transazione eseguita sulla `chain` è recuperabile con i comandi di query del `cncli` oppure con le rest api.



