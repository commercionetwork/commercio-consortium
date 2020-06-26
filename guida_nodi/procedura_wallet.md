# Guida per la gestione dei wallet

## Premessa

Questa piccola guida è stata creata per cercare di spiegare meglio il concetto di `wallet cratore` e `wallet delegatore`.    
Le finalità sono le seguenti.

1. Chiarire cos'è un wallet
2. Chiarire il ruolo di `wallet cratore` e quello di `wallet delegatore`
3. Fornire una procedura guidata di creazione del `wallet cratore`, crazione del nodo validatore e delega dei token dal `wallet delegatore` 

## Concetti fondamentali

**CONCETTO IMPORTANTE**: Un wallet può essere creato indipendentemente dalla sua presenza all'interno di una chain.


### Wallet

Il wallet corrisponde ad avere il possesso delle 24 parole, dalle quali è possibile generare un indirizzo `did:com` compatibile con la chain di **Commercio**.
Le 24 parole possono essere generate con un software, o con un hsm (es. ledger Nano S).    

---
Chi possiede le 24 parole può recuperare il wallet attraverso queste proceduere.

#### Recupero wallet con software di commercio

Usare il comando 
```sh
cncli keys add NOME_WALLET --recover
```
Il comando poi chiederà l'inserimento delle 24 parole + una passphrase per proteggere il wallet all'interno del keyring locale

#### Recupero wallet con software di commercio + ledger Nano S

1. Connettere il `ledger Nano S` al computer dove si vuole utilizzare.
2. Se il dispositivo è nuovo, sul display lcd, dopo alcune istruzioni sull'utilizzo, verrà chiesto se configurare il device come nuovo `Configure as new device`. Premere il tasto sinistro (x). La seconda opzione chiede se si vuole fare un ripristino delle configurazioni `Restore configurations`. Premere il tasto destro (v). A questo punto il ledger chiederà di scegliere un pin (password di accesso al device) e l'inserimento delle 24 parole. Se il dispositivo non è nuovo può essere forzato al ripristino sbagliando 3 volte il pin di sicurezza quando viene collegato a un computer.
3. Sul `ledger Nano S` deve avere installato l'applicazione **Cosmos**. Seguire le istruzioni in ["Install the Cosmos app"](https://support.ledger.com/hc/en-us/articles/360013713840-Cosmos-ATOM-) 
4. Con il software di commercio usare il comando
```sh
cncli keys add NOME_WALLET --recover
```
5. A questo punto un link alle chiavi registrate nel ledger verrà creato. Da questo momento in poi quasiasi transazione che faccia uso del wallet `NOME_WALLET` dovrà avere il supporto del ledger per fare il sign. In questo modo avete recuperato il wallet sul ledger.
       
                      
                   
---
Chi non possiede le 24 parole può generarle attraverso queste procedure

#### Generazione mnemnonic con software di commercio

1. Staccare il computer da rete e posizionarsi in un ambiente riservato. Questo comportamento è opzionale, ma consigliato se si vuole mantenere una certa riservatezza.
2. Usare il comando 
```sh
cncli keys add NOME_WALLET --dry-run 
```
3. Prendere nota delle 24 parole su supporto cartaceo, replicato, e registrare l'indirizzo did:com:1xxxxx su supporto digitale. Si può usare anche un supporto digitale per le 24 parole, tipo chiave usb, basta che si possa mettere al sicuro tale device, replicandolo, e utilizzandolo solo offline. In aggiunta la chiave usb può utilizzare dei software di crittazione per rendere sicuro il contenuto. **Attenzione**: il modo di registrare i dati sono dei consigli, che generalmente vanno adottati solo in ambiente di produzione (mainnet).
4. Mettere in dei posti sicuri e separati il supporto dove si sono registrate le 24 parole.

#### Generazione mnemnonic con ledger Nano S

1. Connettere il `ledger Nano S` al computer dove si vuole utilizzare.
2. Se il dispositivo è nuovo, sul display lcd, dopo alcune istruzioni sull'utilizzo, verrà chiesto se configurare il device come nuovo `Configure as new device`. Premere il tasto destro (v). A questo punto il ledger chiederà di scegliere un pin (password di accesso al device) e genererà le 24 parole.
3. Come nella generazione con software registrare in maniera sicura le 24 parole.
4. Resettare eventualmente il ledger se le 24 parole dovranno essere utilizzate sul device in un secondo momento.
   
---
Per generare un wallet direttamente si possono utilizzare queste procedure

#### Generazione wallet con software di commercio
1. Usare il comando (Il wallet viene aggiunto al proprio keyring sul computer)
```sh
cncli keys add NOME_WALLET
```
2. Regitrare il mnemonic.

**NB**: Usare il software e non dotarsi di un hsm generalmente non è completamente sicuro. Il software comunque dovrà funzionare on-line e quindi non è necessario né possibile usare le stesse accortezze per la generazione del solo mnemonic.

#### Generazione wallet con ledger Nano S
E' la stessa procedura utilizzata in [Generazione mnemnonic con ledger Nano S](#generazione-mnemnonic-con-ledger-nano-s) con l'unica differenza che non deve essere fatto un reset successivo.



**CONCETTO IMPORTANTE**: Un wallet può essere creato indipendentemente dalla sua presenza all'interno di una chain.




### Wallet creatore

Il `wallet creatore` è un wallet che servirà per creare il validatore, e può essere generato come già detto attraverso un software o con supporto hsm.      
Se si è già in possesso di 24 parole si può recuperare il wallet attraverso le procedure già citate.      
Se invece non si hanno le 24 parole il wallet dovrà essere creato sempre con le procedure già indicate.     


### Wallet delegatore (black card)

Il `wallet delegatore` è un wallet che servirà per creare delegare token al validatore.    
Questo wallet è generato a partire dalle 24 parole associate alle black card.    
Seguire le istruzioni già fornite per il recupero del wallet dalle 24 parole.   


## Procedura di creazione validatore e delega

**Premessa**: in questa spiegazione si presuppone di conoscere già i seguenti dati
* La chiave pubblica del validatore, di seguito `VALIDATOR_PUBKEY`
* Aver già creato il `wallet creatore`. nel seguito indicheremo `DID_WALLET_CREATORE`, l'indirizzo did:com associato al `wallet creatore`
* Conoscere l'id della chain, di seguito `CHAINID`
* Conoscere il nome del proprio nodo, di seguito `NODENAME`. Il nome è a discrezione di chi crea il nodo.
* Indicheremo con `DID_WALLET_DELEGATORE` l'indirizzo did:com associato al `wallet delegatore`
* Avere a disposizione un nodo della chain in locale o raggiungibile sulla porta rpc (26657)

1. Recuperare il `wallet delegatore` (black card)
2. Configurare il proprio enviroment per poter utilizzare nei comandi la chain corretta
```sh
cncli config chain-id CHAINID
```
3. Inviare almeno 1 token + 0,01token al `wallet creatore` dal `wallet delegatore`. 1 token serve per il minimo di stake nella creazione del nodo validatore (vedi di seguito), e 0,01token servono per le **fees**
```
cncli tx send \
  DID_WALLET_DELEGATORE \
  DID_WALLET_CREATORE \
  1000000ucommercio \
  --fees=10000ucommercio  \
  -y
```
Se si sta usando il ledger deve essere aggiunta l'opzione `--ledger`
```
cncli tx send \
  DID_WALLET_DELEGATORE \
  DID_WALLET_CREATORE \
  1000000ucommercio \
  --fees=10000ucommercio  \
  --ledger \
  -y
```

4. Eseguire la transazione di creazione del validatore
```sh
cncli tx staking create-validator \
  --amount=1000000ucommercio \
  --pubkey=VALIDATOR_PUBKEY \
  --moniker="NODENAME" \
  --chain-id="CHAINID" \
  --identity="" \
  --website="" \
  --details="" \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --from=DID_WALLET_CREATORE \
  --fees=10000ucommercio \
  -y
```
Se si sta usando il ledger deve essere aggiunta l'opzione `--ledger`
```sh
cncli tx staking create-validator \
  --amount=1000000ucommercio \
  --pubkey=VALIDATOR_PUBKEY \
  --moniker="NODENAME" \
  --chain-id="CHAINID" \
  --identity="" \
  --website="" \
  --details="" \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --from=DID_WALLET_CREATORE \
  --fees=10000ucommercio \
  --ledger \
  -y
```
5. A questo punto nella chain il validatore è stato creato, e dovrebbe essere visibile sull'explorer della relativa chain.
6. Dobbiano rilevare la chiave operatore del validatore, di seguito `VALIDATOR_OPERATORKEY`
```sh
cncli query staking validators | fgrep -B 1 VALIDATOR_PUBKEY
```
7. Il messaggio dovrebbe apparire come segue
```
operatoraddress: did:com:valoper1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
conspubkey: VALIDATOR_PUBKEY
```
8. Il valore di `VALIDATOR_OPERATORKEY` è **did:com:valoper1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx**
9. Delegare i token necessari per il validatore
```sh
cncli tx staking delegate \
  VALIDATOR_OPERATORKEY \
  50000000000ucommercio \
  --from DID_WALLET_DELEGATORE \
  --fees=10000ucommercio \
  -y
```
Se si sta utilizzando un nodo remoto usare
```sh
cncli tx staking delegate \
  VALIDATOR_OPERATORKEY \
  50000000000ucommercio \
  --from DID_WALLET_DELEGATORE \
  --node tcp://<ip of your full node>:26657 \
  --fees=10000ucommercio \
  -y
```
Se si sta usando il ledger deve essere aggiunta l'opzione `--ledger`
```sh
cncli tx staking delegate \
  VALIDATOR_OPERATORKEY \
  50000000000ucommercio \
  --from DID_WALLET_DELEGATORE \
  --node tcp://<ip of your full node>:26657 \
  --fees=10000ucommercio \
  --ledger \
  -y
```
10. Il validatore dovrebbe apparire sull'explorer con 50.001 token in stake

## Sintesi

In sintesi devono essere creati due wallet, uno per creare e uno per delegare.   
Quello per creare viene creato in qualche maniera da chi sta eseguendo la procedura, mentre quello per delegare deriva dalla black card, che sulla mainnet è stata distribuita attraverso le card, ma che invece in devnet e/o in testnet viene mandata a chi ne fa richiesta.   
Il wallet che delega manda un token + le fees al wallet che deve creare, così il wallet che deve creare viene attivato sulla chain.    
Possono essere mandati anche più token al wallet che crea: a volte si commettono errori nel creare il validatore e quindi si brucia la fees, quindi eventualmente inviare 2 token.   
Il wallet che deve creare esegue la transazione di creazione del validatore.     
Una volta creato il validatore il wallet che delega deve delgare appunto, il grosso dei token al validatore.   


## FONDAMENTALE

Le 24 parole della black card non sono da utilizzare nei sistema hsm utilizzati dal validatore per generare le chiavi di consenso.     
**Le chiavi di consenso del validatore sono una cosa separata e servono a generare il `VALIDATOR_PUBKEY`**    
Chi gestisce il validatore potrebbe essere un'entità che non ha nessun controllo sul wallet che delega.   
E' il caso, ad esempio, in cui chi gestisce fisicamente il nodo è un soggetto separato da chi detiene il possesso dei token.    

