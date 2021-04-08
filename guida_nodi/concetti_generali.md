# Note generali sulla configurazione KMS-nodo validatore

## Concetti generali
Il concetto generale di un nodo validatore è quello di validare ogni blocco che viene rilasciato sulla chain.    
Per fare ciò il validatore esegue dei calcoli matematici sui dati inviati dalle varie transazioni.
I dati risultanti dalle varie transazioni devono essere uguali per tutti i validatori.     
Questi dati poi vengono firmati con la chiave di firma in possesso del validatore stesso, che in tal modo li verifica.    
La chiave di firma può risiedere all'interno di un semplice file o in un HSM (Hardware Security Module).    
Se la chiave viene compromessa anche l'integrità della chain viene compromessa, fino a portare in alcuni casi al blocco della chain stessa.    
Se più dei 2/3 (due terzi) dei nodi validatori risulta con le chiavi compromesse la chain si bloccherà, perché si arriverà a creare una situazione in cui tutti i nodi coinvolti verranno messi in jail e quindi disattivati.     
Lo scenario difficilmente si può verificare, ma comunque, è necessario mantenere in sicurezza le proprie chiavi, ed è per questo che si dovrebbe adottare un HSM, in maniera che le chiavi private siano protette all'interno del modulo.

## Separazione kms-nodo validatore

Premesso che è possibile comunque installare il kms dal nodo validatore la separazione dei due componenti consente di agire in maniera più sicura e robusta nella gestione.     
1. Se il nodo validatore deve essere spostato per qualsiasi tipo di esigenza, si può creare un semplice full-node da un'altra parte, spegnere il nodo attualmente funzionante, spostare il puntamento del kms e cambiare la configurazione del full-node. Se invece la macchina è un tuttuno deve essere tutto predisposto in precedenza, avendo anche la necessità di avere un HSM aggiuntivo, o in alternativa togliere l'HSM dal nodo (e quindi un certo periodo di off-line per il nodo) e spostarlo su quello nuovo. Tutte le operazioni, specialmente se il nodo è in cloud, potrebbero risultare complicate
2. La compromissione del nodo validatore non compromette anche le chiavi, dato che si trovano su un sistema separato. Il kms ha accesso al nodo validatore su una specifica porta, mentre il nodo validatore non ha accesso a nessuna accesso del kms.
3. E' più semplice realizzare una ridondanza di chiavi: se si dovesse creare un nodo ridondato comunque quest'ultimo dovrebbe avere tutta la logica del nodo preesistente.


## Esempi di strutture

