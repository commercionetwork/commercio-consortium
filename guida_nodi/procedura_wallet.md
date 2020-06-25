# Guida per la gestione dei wallet

## Premessa

Questa piccola guida è stata creata per cercare di spiegare meglio il concetto di `wallet cratore` e `wallet delegatore`.    
Le finalità sono le seguenti.

1. Chiarire cos'è un wallet
2. Chiarire il ruolo di `wallet cratore` e quello di `wallet delegatore`
3. Fornire una procedura guidata di creazione del `wallet cratore`, crazione del nodo validatore e delega dei token dal `wallet delegatore` 

## Concetti fondamentali

### Wallet

Il wallet corrisponde ad avere il possesso delle 24 parole, dalle quali è possibile generare un indirizzo `did:com` compatibile con la chain di **Commercio**.
Le 24 parole possono essere generate con un software, o con un hsm (es. ledger Nano S).    

Chi possiede le 24 parole può recuperare il wallet attraverso queste proceduere.

### Con software di commercio

Usare il comando 
```sh
cncli keys add NOME_WALLET --recover
```
Il comando poi chiederà l'inserimento delle 24 parole + una passphrase per proteggere il wallet all'interno del keyring locale

#### Con software di commercio + ledger Nano

1. Inserire 



**Un wallet può essere creato indipendentemente dalla sua presenza all'interno di una chain**

### Wallet creatore

Il `wallet creatore` è un wallet che servirà per creare il validatore, e può essere generato come già detto attraverso un software o con supporto hsm.
Se si è già i 