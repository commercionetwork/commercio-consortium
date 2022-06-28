# Upgrade instructions from version 3.1.0 to version 4.0.0 Commercio Network Chain 

## Prerequisites

1. Have a working node with software version v3.1.0
2. Have all the tools on the server to compile the application as mentioned in the first paragraph at https://docs.commercio.network/nodes/full-node-installation.html

If you want to make a backup and you have a kms, as you stop the service to make it, save the status file in the kms itself 

## Raccomandations

1. To speed up the upgrade and make it easy use `cosmovisor` tools


**Please note**: this upgrade is **mandatory**. The nodes that will not upgrade will become incompatible with the chain.

**Please note**: if you install a new node from genesis use version 3.0.0 and try to upgrade after height 3318000 to version 3.1.0. After the halt height of this upgrade the chain will be stopped automatically and the new version 4.0.0 will be required. If you want use this version directly you have to download the chain dump from https://quicksync.commercio.network after 2022/07/04

## Upgrade info

This upgrade will be performed with a proposal. The proposals are shown here

https://mainnet.commercio.network/proposals/

When a upgrade proposal passed the chain will halted at the height indicated in the proposal.

You can verify the approximate date when the upgrade will be performed putting the height in the follow link

https://mainnet.commercio.network/blocks/detail/HALT-HEIGHT

where `HALT-HEIGHT` is the height of upgrade.

Any validator and any user who has staked their tokens can vote the proposal. After two days of voting, the proposal will close and if it passes the update will be performed at the proposed height.

You can use the command line interface to vote Yes, No, Abstain or NoWithVeto.

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
  

## Upgrade procedure

Download the repo from GitHub **if you have not already done**. If you have already the local copy of repository don't try clone it.

```bash
git clone https://github.com/commercionetwork/commercionetwork.git
```

Go to the repo folder and checkout to the v4.0.0 tag

```bash
cd commercionetwork
git pull
git checkout v4.0.0
```

Build the Application

```bash
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
version: 4.0.0
commit: -------
build_tags: netgo,ledger
go: go version go1.18.1 linux/amd64
```


### Cosmovisor installation

**Warning**: you need to setup cosmovisor env, mainly `$DAEMON_HOME` variable.
From `commercionetwork` repository folder run commands below

```bash
mkdir -p $DAEMON_HOME/cosmovisor/upgrades/v4.0.0/bin
cp ./build/commercionetworkd $DAEMON_HOME/cosmovisor/upgrades/v4.0.0/bin/.
```

Wait sitting in your armchair watching your favorite TV series for the chain upgrade: cosmovisor should do all the dirty work for you.

**WARNING**: If you use cosmovisor version 1.0.0 or earlier you need to setup backup strategies. If you don't setup `UNSAFE_SKIP_BACKUP` variable a backup of your `data` folder will be performed before the upgrade. If `data` folder occupies for example 60Gb you need an equal or greater amount of free space on your disk to perform the backup. Read [here](./setup_cosmovisor.md) how to setup your cosmovisor.


### Generic installation


**Warning**: the path where the executable is installed depends on your environment. In the following it is indicated with $GOPATH.

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

Now wait sitting in your office chair, rotating your thumbs, monitoring from your logs when your node crashes.

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

