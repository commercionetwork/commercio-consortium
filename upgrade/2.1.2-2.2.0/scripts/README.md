# Scripts per upgrade (beta)

## Premessa 

Qui sono stati sviluppati alcuni scripts per l'utilizzo sulla chain.   
Il loro sviluppo cerca di venire incontro a dei sistemi eteregeneri di ambienti, ma comunque devono essere controllati.   

## Utilizzo



Trasferire l'intera cartella `scripts` sui server che si devono aggiornare.


Su server lanciare 
```bash
/path/scripts/setup.sh
```
Rispondere a tutte le domande

Lanciare 

```bash
/path/scripts/01_val_config_stop.sh $ENV_FILE
```
