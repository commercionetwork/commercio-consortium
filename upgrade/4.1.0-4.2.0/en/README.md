# Upgrade instructions from version 4.1.0 (4.0.0) to version 4.2.0 Commercio Network Chain

## Prerequisites


1. Have a working node with software version v4.1.0. **<img src="../img/attetion.png" width="30">WARNING**:  If you have not upgraded from version v4.0.0 to version v4.1.0, the node may still be working. In that case, you can apply the upgrade.
2. Have all the tools on the server to compile the application as mentioned in the first paragraph at [Installing the software requirements](https://docs.commercio.network/nodes/full-node-installation.html#_1-installing-the-software-requirements)


## Raccomandations

1. To perform the update quickly and make it easy use `cosmovisor` tools version `v1.0.0+`


**Please note**: this upgrade is **MANDATORY**. The nodes that will not upgrade will become incompatible with the chain and they will stop.

**Please note**: if you install a new node from genesis use version 3.0.0 and try to upgrade after height 3318000 to version 3.1.0. After the halt height of all upgrades the chain will be stopped automatically and the new version will be required. If you want use this version directly you have to download the chain dump from https://quicksync.commercio.network after 2022/11/25

## Upgrade info

This upgrade will be performed with a proposal. The proposals are shown here

https://mainnet.commercio.network/proposals/detail/3

When a upgrade proposal passed the chain will halted at the height indicated in the proposal.

You can verify the approximate date when the upgrade will be performed putting the height in the follow link

https://mainnet.commercio.network/blocks/detail/6225000


Any validator and any user who has staked their tokens can vote the proposal. After one day of voting, the proposal will close and if it passes the update will be performed at the proposed height.

You can use the command line interface to vote **yes**, **no**, **abstain** or **no_with_veto**.

```bash
commercionetworkd tx gov vote \
   PROPOSAL_ID \
   yes \
   --from DELEGATOR_WALLET \
   --chain-id commercio-3 \
   --fees 10000ucommercio \
   -y
```


**PROPOSAL_ID** is the id of proposal (in this case 1).    
If you use ledger add `--ledger` flag to the command.

**<img src="../img/attetion.png" width="30">WARNING**: You may not find the keys because they were created with the previous version of the software: `cncli`. You must retrieve your private key from the mnemonic or ledger.


You also can use follow web interfaces with keplr support

- [Commercio.Network explorer](https://mainnet.commercio.network/proposals/)
- [Ping.pub Commercio.Network](https://ping.pub/commercio.network/gov)


## Upgrade procedure

Download the repo from GitHub **if you have not already done**. If you have already the local copy of repository don't try clone it.

```bash
git clone https://github.com/commercionetwork/commercionetwork.git
```

Go to the repo folder, checkout to the v4.2.0 tag and build the application

```bash
cd commercionetwork
git fetch --tags && git checkout v4.2.0
make build
```

Check that the application is the right version

```bash
./build/commercionetworkd version --long
```

The result should be

```
name: commercionetwork
server_name: commercionetworkd
version: 4.2.0
commit: 5c1e433c3bd60d86d8c852c76ebf2e0fe995bbb2
build_tags: netgo,ledger
go: go version go1.19.1 linux/amd64
build_deps:
```


### Cosmovisor installation
**<img src="../img/attetion.png" width="30">WARNING**: you need to setup cosmovisor env, mainly `$DAEMON_HOME` variable.    
**<img src="../img/attetion.png" width="30">WARNING**: you need to have cosmovisor version `v1.0.0+` installed. Check your version with `cosmovisor version` command.     
**<img src="../img/attetion.png" width="30">WARNING**: **you must install the new binary in the upgrades folder before reaching the height of the update**.       
From `commercionetwork` repository folder run commands below

```bash
mkdir -p $DAEMON_HOME/cosmovisor/upgrades/v4.2.0/bin
cp ./build/commercionetworkd $DAEMON_HOME/cosmovisor/upgrades/v4.2.0/bin/.
```

**<img src="../img/attetion.png" width="30">WARNING**: You need to setup backup strategies. If you don't setup `UNSAFE_SKIP_BACKUP` variable a backup of your `data` folder will be performed before the upgrade. If `data` folder occupies for example 150Gb you need an equal or greater amount of free space on your disk to perform the backup. Read [here](./setup_cosmovisor.md) how to setup your cosmovisor.   

- Remove `UNSAFE_SKIP_BACKUP` variable from your service **if you want a backup**
- Set `UNSAFE_SKIP_BACKUP` to `true` **if you DON'T want a backup**


### Generic installation (**WITHOUT COSMOVISOR**)


**<img src="../img/attetion.png" width="30">WARNING**: the path where the executable is installed depends on your environment. In the following it is indicated with $GOPATH.

Few hours before upgrade setup your `commercionetworkd` service changing the line

```
Restart=always
```
in
```
#Restart=always
Restart=no
```

Your service file should be in `/etc/systemd/system/commercionetworkd.service`

Reload and restart service
```bash
systemctl daemon-reload
systemctl restart commercionetworkd.service
```

Wait monitoring from your logs when your node crashes.

```bash
journalctl -u commercionetworkd.service -f
```

When the node will be halted you need to chenge the `commercionetworkd` program and start the service.     
From `commercionetwork` repository folder run commands below

```bash
cp ./build/commercionetworkd $GOPATH/bin/.
```

If you want make a backup coping the `data` folder in a secure place.  

Remember to revert your service configuration

```
#Restart=always
Restart=no
```
in
```
Restart=always
```


Reload and restart the service

```bash
systemctl daemon-reload
systemctl start commercionetworkd.service
```

Check if the service is working

```bash
journalctl -u commercionetworkd.service -f
```

### ON UPGRADE ERROR 

If you run into an error you can ask help on the [Discord Channel](https://discord.com/channels/973149882032468029/973163682030833685)


