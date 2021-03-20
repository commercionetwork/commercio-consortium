# Riferimenti tecnici configurazioni tmkms

## Descrizione

In questa guida si spiegano le differenze tra la versione `0.8.0` e le varsione `0.10.0` del tmkms


## File con tmkms versione `0.8.0` chain `commercio-2_1`

Questa configurazione è un esempio delle configurazioni attualmente presenti sulla chain funzionante con il software tmkms `0.8.0`.

```toml
[[chain]]
id = "commercio-2_1"
key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
state_file = "/data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state.json"

[[validator]]
addr = "tcp://10.1.1.1:26658"
chain_id = "commercio-2_1"
reconnect = true
secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection.key"

[[providers.yubihsm]]
adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }
auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" }
keys = [{ chain_ids = ["commercio-2_1"], key = 1 }] 
serial_number = "9876543210"
```

Da notare

* `[[chain]]` `state_file`: è il file di stato.
* `[[chain]]` `id`: chain id valore `commercio-2_1`
* `[[validator]]` `chain_id`: chain id valore `commercio-2_1`
* `[[providers.yubihsm]]` `keys` `chain_ids`: chain id valore `commercio-2_1` 

**NB**: questa configurazione è solo per mettere in evidenza l'attuale configurazione. La nuova chain non sarà compatibile con questo file e con il software `0.8.0`

## File con tmkms versione `0.10.0` per chain `commercio-2_1`

Questa configurazione è un esempio di configurazione utilizzabile con la chain  tmkms `commercio-2_1` e il software versione `0.10.0` del tmkms.
In questo caso si è aggiornato il software tmkms e si è applicato direttamente alla chain `commercio-2_1`. Si ricorda che aggiornare prima i servizi e il tmkms è una scelta operativa.


```toml
[[chain]]
id = "commercio-2_1"
key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
state_file = "/data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state.json"

[[validator]]
addr = "tcp://10.1.1.1:26658"
chain_id = "commercio-2_1"
reconnect = true
secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection.key"
protocol_version = "legacy"

[[providers.yubihsm]]
adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }
auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" }
keys = [{ chain_ids = ["commercio-2_1"], key = 1 }] 
serial_number = "9876543210"
```

Da notare

* `[[chain]]` `state_file`: è il file di stato. In ogni caso questo riferimento dovrà essere cambiato
* `[[chain]]` `id`: chain id valore `commercio-2_1`
* `[[validator]]` `chain_id`: chain id valore `commercio-2_1`
* `[[providers.yubihsm]]` `keys` `chain_ids`: chain id valore `commercio-2_1` 
* `[[validator]]` `protocol_version`: è il valore che indica come il tmkms deve comportarsi nei confronti del nodo e avrà valore `legacy` 

**PRECISAZIONE**: premesso che questa è solo una precisazione e quindi potete ignorarla, se avete cambiato anche il riferimento di `[[validator]]` `secret_key` dovete prima generare una chiave segreta. La versione `0.8.0` generava in automatico la chiave segreta, mentre con la versione `0.10.0` deve essere esplicitamente con il comando 

```bash
tmkms init /path/to/kms/home
```
dove `/path/to/kms/home` è un path generico di lavoro. Non usare lo stesso path delle confiturazioni ufficiali.   
Il comando genera un template di configurazione compresa la chiave segreta. Copiare eventualmente la chiave nella posizione corretta.

Vedi riferimenti su https://github.com/iqlusioninc/tmkms#configuration-tmkms-init


## File con tmkms versione `0.10.0` per chain `commercio-2_2`

Questa configurazione è un esempio di configurazione utilizzabile con la chain  tmkms `commercio-2_2` e il software versione `0.10.0` del tmkms, e dovrebbe essere la configurazione finale da  utilizzare sulla nuova chain

```toml
[[chain]]
id = "commercio-2_2"
key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
state_file = "/data_tmkms/tmkms/kms/commercio/2.2.0/commercio_priv_validator_state.json"

[[validator]]
addr = "tcp://10.1.1.1:26658"
chain_id = "commercio-2_2"
reconnect = true
secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection1.key"
protocol_version = "v0.33"

[[providers.yubihsm]]
adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }
auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" }
keys = [{ chain_ids = ["commercio-2_2"], key = 1 }] 
serial_number = "9876543210"
```

Da notare

* `[[chain]]` `state_file`: è il file di stato. **Questo riferimento deve essere cambiato da quello della chain precedente**
* `[[chain]]` `id`: chain id valore `commercio-2_2`
* `[[validator]]` `chain_id`: chain id valore `commercio-2_2`
* `[[providers.yubihsm]]` `keys` `chain_ids`: chain id valore `commercio-2_2` 
* `[[validator]]` `protocol_version`: è il valore che indica come il tmkms deve comportarsi nei confronti del nodo e avrà valore `v0.33` 


## DIFFERENZE



```toml
[[chain]]    
id = "commercio-2_1"
...

 ||
\  /
 \/

```toml
[[chain]]    
id = "commercio-2_2"
...
```


```toml
[[chain]]    
....
state_file = "/data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state.json"

 ||
\  /
 \/

[[chain]]    
....
state_file = "/data_tmkms/tmkms/kms/commercio/2.2.0/commercio_priv_validator_state.json"
```

```toml
[[validator]]
...   
chain_id = "commercio-2_1"

 ||
\  /
 \/

[[validator]]
...
chain_id = "commercio-2_2
```


```toml
[[validator]]
...
 ||
\  /
 \/

[[validator]]
...
protocol_version = "legacy"

 ||
\  /
 \/

[[validator]]
...
protocol_version = "v0.33"
```

```toml
[[providers.yubihsm]]
...   
keys = [{ chain_ids = ["commercio-2_1"], key = 1 }]

 ||
\  /
 \/

[[providers.yubihsm]]
...
keys = [{ chain_ids = ["commercio-2_2"], key = 1 }]
```
