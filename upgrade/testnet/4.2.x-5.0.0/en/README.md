# Upgrade instructions from version 4.2.x to version 5.0.0 Commercio Network Chain Testnet

## Prerequisites


1. Have a working node in testnet with software version v4.2.x.
2. Have all the tools on the server to compile the application as mentioned in the first paragraph at [Installing the software requirements](https://docs.commercio.network/nodes/full-node-installation.html#_1-installing-the-software-requirements)


## Raccomandations

1. To perform the update quickly and make it easy use `cosmovisor` tools


**Please note**: this upgrade is **MANDATORY**. The nodes that will not upgrade will become incompatible with the chain and they will stop.

**Please note**: if you install a new node you have to download the chain dump from https://quicksync.commercio.network, or build new node from state sync.

## Upgrade info

This upgrade will be performed with a proposal. The proposals are shown here

https://testnet.commercio.network/proposals/

When a upgrade proposal passed the chain will halt at the height indicated in the proposal.

You can verify the approximate date when the upgrade will be performed replacing the height in the following link

https://testnet.commercio.network/blocks/detail/{HALT-HEIGHT}

where `HALT-HEIGHT` is the height of upgrade.

Any validator and any user who has staked their tokens can vote the proposal. After two days of voting, the proposal will close and if it passes the update will be performed at the proposed height.

You can use the command line interface to vote **Yes**, **No**, **Abstain** or **NoWithVeto**.

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


You also can use the web interfaces with keplr support

- [Commercio.Network Tesnet explorer](https://testnet.commercio.network/proposals/)
- [Ping.pub Tesnet Commercio.Network](https://testnet.ping.pub/commercio.network/gov)


## Upgrade procedure

Download the repo from GitHub **if you have not already done**. If you have already the local copy of repository don't try clone it.

```bash
git clone https://github.com/commercionetwork/commercionetwork.git
```

Go to the repo folder, checkout to the `v5.0.0-pre.3` tag and build the application

```bash
cd commercionetwork
git fetch --tags && git checkout v5.0.0-pre.3
make build
```

Check that the application is the right version

```bash
./build/commercionetworkd version --long
```

The result should be

```
name: commercionetwork
server_name: commercionetword
version: 5.0.0-pre.3
commit: 106d57404c51f65b47b9017bb22814d1f9bcb9c3
build_tags: netgo,ledger
go: go version go1.20.5 linux/amd64
....
```


### Cosmovisor installation



<img src="../img/attetion.png" width="50">**WARNING**: you need to setup cosmovisor env, mainly `$DAEMON_HOME` variable.<img src="../img/attetion.png" width="50">

In the most cases the value of `$DAEMON_HOME` variable is `$HOME/.commercionetwork`. If you don't have this variable set you can set it with command below

```bash
export DAEMON_HOME="$HOME/.commercionetwork"
echo "export DAEMON_HOME=\$HOME/.commercionetwork" >> ~/.profile
source ~/.profile
```

**From `commercionetwork` repository folder** run commands below


```bash
mkdir -p $DAEMON_HOME/cosmovisor/upgrades/v5.0.0/bin
cp ./build/commercionetworkd $DAEMON_HOME/cosmovisor/upgrades/v5.0.0/bin/.
```

**<img src="../img/attetion.png" width="30">WARNING**: You need to setup backup strategies. If you don't setup `UNSAFE_SKIP_BACKUP` variable a backup of your `data` folder will be performed before the upgrade. If `data` folder occupies for example 60Gb you need an equal or greater amount of free space on your disk to perform the backup. Read [here](./setup_cosmovisor.md) how to setup your cosmovisor.   

- Set `UNSAFE_SKIP_BACKUP` to `false` **if you want a backup**
- Set `UNSAFE_SKIP_BACKUP` to `true` **if you DON'T want a backup**


### Generic installation (**WITHOUT COSMOVISOR**)


**<img src="../img/attetion.png" width="30">WARNING**: the path where the executable is installed depends on your environment. In the following it is indicated with $GOPATH.

Few hours before upgrade setup your `commercionetworkd` service changing the line

```ini
Restart=always
```
to
```ini
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

When the node halts you need to change the `commercionetworkd` program and start the service.     
From `commercionetwork` repository folder run the command below

```bash
cp ./build/commercionetworkd $GOPATH/bin/.
```

If you want make a backup copy of the `data` folder, put it in a secure place.  

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

## After the official release

In the days following the testnet update an official version will be released for use in the mainnet.   
The official version may be replaced on the testnet independently by each node.     


