# Upgrade instructions from version 4.2.0 to version 4.2.1 Commercio Network Chain

## Prerequisites


1. Have a working node with software version v4.2.0.
2. Have all the tools on the server to compile the application as mentioned in the first paragraph at [Installing the software requirements](https://docs.commercio.network/nodes/full-node-installation.html#_1-installing-the-software-requirements)


## Raccomandations

**Please note**: this upgrade is **NOT MANDATORY**. The nodes that will not upgrade will continue to work without problems. However, we recommend that you upgrade to the new version to take advantage of the new features and bug fixes.    
Every node can upgrade to the new version indipendently from the others. There is no need to coordinate the upgrade with the other nodes of the network.


## Upgrade info

This upgrade will be performed with a simple software update. No data migration is required.    
The upgrade increases the stability of the nodes.   
Introduces the new documentation about api and node handling.

## Upgrade procedure with cosmovisor

**This procedure is valid for cosmivicor installations.**

**<img src="../img/attetion.png" width="30">WARNING**: you need to setup cosmovisor env, mainly `$DAEMON_HOME` variable.  
```bash
export DAEMON_HOME="$HOME/.commercionetwork"
echo "export DAEMON_HOME=$DAEMON_HOME" >> ~/.profile
```



Download the repo from GitHub if you have not already done. **If you have already the local copy of repository don't try clone it**.

```bash
git clone https://github.com/commercionetwork/commercionetwork.git
```

Go to the repo folder, checkout to the v4.2.1 tag and build the application

```bash
cd commercionetwork
git fetch --tags && git checkout v4.2.1
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
version: 4.2.1
commit: 0030f38240b094aeb1c8e11ae23747ae1e5c4eb0
build_tags: netgo ledger,
...
```


Stop your `commercionetworkd` service, upgrade the application and restart the service

```bash
sudo systemctl stop commercionetworkd.service
cp $HOME/commercionetwork/build/commercionetworkd $DAEMON_HOME/cosmovisor/current/bin/.
sudo systemctl start commercionetworkd.service
```


Wait monitoring from your logs when your node crashes.

```bash
journalctl -u commercionetworkd.service -f
```

Install the new version in the `$GOPATH/bin` folder

```bash
cp $HOME/commercionetwork/build/commercionetworkd $GOPATH/bin/.
```
## Upgrade procedure without cosmovisor


Download the repo from GitHub if you have not already done. **If you have already the local copy of repository don't try clone it**.

```bash
git clone https://github.com/commercionetwork/commercionetwork.git
```

Go to the repo folder, checkout to the v4.2.1 tag and build the application

```bash
cd commercionetwork
git fetch --tags && git checkout v4.2.1
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
version: 4.2.1
commit: 0030f38240b094aeb1c8e11ae23747ae1e5c4eb0
build_tags: netgo ledger,
...
```


Stop your `commercionetworkd` service, upgrade the application and restart the service
**WARNING**: if you have installed commercionetworkd in a different folder from `$GOPATH/bin` you need to change the path in the following commands.

```bash
sudo systemctl stop commercionetworkd.service
cp $HOME/commercionetwork/build/commercionetworkd $GOPATH/bin/.
sudo systemctl start commercionetworkd.service
```


Wait monitoring from your logs when your node crashes.

```bash
journalctl -u commercionetworkd.service -f
```


### ON UPGRADE ERROR 

If you run into an error you can ask help on the [Discord Channel](https://discord.com/channels/973149882032468029/973163682030833685)



