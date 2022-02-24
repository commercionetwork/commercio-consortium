# Check your configurations

## Get base config.toml file and app.toml
You can create a config.toml file by compiling the application and running the command
```
commercionetworkd unsafe-reset-all
```

Or you can download the default files at this links 
* [config.toml](../commons/config.toml)
* [app.toml](../commons/app.toml)

## Setup config.toml

Compare the `config.toml` file with the previous file. The file should already have been configured. The main differences should be

1. `persistent_peers`: if you have sentries there should be references to them. Otherwise use the basic configurations of the chain
2. `seeds`: if you have sentries they should be empty, otherwise the chain defaults should be there.
3. `pex`: in presence of sentries should be false
4. `unconditional_peer_ids`: should be removed in initial phase
5. `private_peer_ids`: in sentries should be present id of validator
6. `addr_book_strict`: should be false in case of validators + sentries
7. `external_address`: in case of server behind nat use public ip. Not to be used in case the validator is connected to sentries. E.g. 156.157.12.34:26656
8. `priv_validator_laddr`: if you use a tmkms configure the value with the ip of your validator and port 26658. E.g. tcp://156.157.12.34:26658 
9. If need rpc listen on pubblic address under the section `[rpc]` setup `laddr` with "tcp://0.0.0.0:26657"
1. `moniker`: the value should be configured with your node moniker



## Setup app.toml

In the `app.toml` file you need to check if you previously had a rest service configured on the node. If so you have to configure in the section `[api]` the following values
* `address = "tcp://0.0.0.0:1317"` (default) 
* `enable = true`.

Configure your pruning strategy if you need it
* `pruning = "default"`. Default value for most nodes
* `pruning = "everything"`. All saved states will be deleted
* `pruning = "nothing"`. all historic states will be saved, nothing will be deleted (i.e. archiving node). **Not use if you don't need**.




