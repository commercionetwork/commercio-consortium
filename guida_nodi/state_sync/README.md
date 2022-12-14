# Installazione nodo state sync

## Installere la base software
Installare un nodo come indicato in 
[Install a full node](https://docs.commercio.network/nodes/full-node-installation.html) **fermandosi a [4 .Configure the service](https://docs.commercio.network/nodes/full-node-installation.html#_4-configure-the-service)**



## Eseguire l'allineamento con lo state sync

Sul nodo lanciare i seguenti comandi

```bash
TRUST_RPC1="rpc-mainnet.commercio.network:80"
TRUST_RPC2="rpc2-mainnet.commercio.network:80"
CURR_HEIGHT=$(curl -s "http://$TRUST_RPC1/block" | jq -r '.result.block.header.height')
TRUST_HEIGHT=$((CURR_HEIGHT-(CURR_HEIGHT%10000)))
TRUST_HASH=$(curl -s "http://$TRUST_RPC1/block?height=$TRUST_HEIGHT" | jq -r '.result.block_id.hash')
printf "\n\nenable = true\nrpc_servers = \"$TRUST_RPC1,$TRUST_RPC2\"\ntrust_height = $TRUST_HEIGHT\ntrust_hash = \"$TRUST_HASH\"\ntrust_period = \"168h0m0s\"\n\n"
```

Dovrebbe apparire un output simile a questo

```toml
enable = true
rpc_servers = "rpc-mainnet.commercio.network:80,rpc2-mainnet.commercio.network:80"
trust_height = 6310000
trust_hash = "8B4BEDCFF554F52A0B7B2C833FB3AE2F734A31A8CFB842CB273574B1716143A8"
trust_period = "168h0m0s"
```

Modificare la configurazione del nodo con i nuovi parametri.    
Editare il file `~/.commercionetwork/config/config.toml`.    

Cercare la sezione `[statesync]`. Subito sotto la sezione dovrebbero esserci le configurazioni di base. Commentare (o eliminare) tutto quello nella sezione fino a `trust_period = "168h0m0s"` e aggiungere l'output precedente. Dovrebbe apparire alla fine in questa maniera

```toml
# State sync rapidly bootstraps a new node by discovering, fetching, and restoring a state machine
# snapshot from peers instead of fetching and replaying historical blocks. Requires some peers in
# the network to take and serve state machine snapshots. State sync is not attempted if the node
# has any local state (LastBlockHeight > 0). The node will have a truncated block history,
# starting from the height of the snapshot.
# enable = false

# RPC servers (comma-separated) for light client verification of the synced state machine and
# retrieval of state data for node bootstrapping. Also needs a trusted height and corresponding
# header hash obtained from a trusted source, and a period during which validators can be trusted.
#
# For Cosmos SDK-based chains, trust_period should usually be about 2/3 of the unbonding time (~2
# weeks) during which they can be financially punished (slashed) for misbehavior.
# rpc_servers = ""
# trust_height = 0
# trust_hash = ""
# trust_period = "168h0m0s"

enable = true
rpc_servers = "rpc-mainnet.commercio.network:80,rpc2-mainnet.commercio.network:80"
trust_height = 6310000
trust_hash = "8B4BEDCFF554F52A0B7B2C833FB3AE2F734A31A8CFB842CB273574B1716143A8"
trust_period = "168h0m0s"

# Time to spend discovering snapshots before initiating a restore.
discovery_time = "15s"
....
```

A questo punto è possibile avviare il nodo

```bash
# Start the node  
systemctl enable commercionetworkd  
systemctl start commercionetworkd
```

Controllare l'allineamento usando 

```bash
journalctl -u commercionetworkd -f | grep height=
```

Dopo una prima fase di ricerca del dump dello stato dovrebbe cominciare a produrre blocchi.    
Se non dovesse succedere eseguite un reset all e provate nuovamente.

